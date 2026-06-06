import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const double _krwPerUsd = 1400;
  static const double _geminiFlashLiteOutputUsdPerMillionTokens = 0.40;

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static List<String> _recentDateKeys(DateTime date, int dayCount) {
    return List.generate(
      dayCount,
      (index) => _dateKey(date.subtract(Duration(days: index))),
    );
  }

  static int _readInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static DateTime? _readDateTime(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value?.toString() ?? '';
  }

  static String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static int _estimateCostWonFromTokens(int tokenCount) {
    if (tokenCount <= 0) return 0;
    final usdCost =
        tokenCount / 1000000 * _geminiFlashLiteOutputUsdPerMillionTokens;
    return (usdCost * _krwPerUsd).round();
  }

  static int _normaliseCostWon({
    required int storedCostWon,
    required int tokenCount,
  }) {
    final estimatedCostWon = _estimateCostWonFromTokens(tokenCount);
    if (tokenCount <= 0) return storedCostWon;
    if (storedCostWon <= 0) return estimatedCostWon;
    if (estimatedCostWon > 0 && storedCostWon > estimatedCostWon * 2) {
      return estimatedCostWon;
    }
    return storedCostWon;
  }

  static Map<String, int> _readUsageMap(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! Map) return {};

    return value.map((coachId, usageValue) {
      final usageCount = usageValue is num ? usageValue.toInt() : 0;
      return MapEntry(coachId.toString(), usageCount);
    })..removeWhere((_, usageCount) => usageCount <= 0);
  }

  static Map<String, int> _mergeUsageMaps(Iterable<Map<String, int>> maps) {
    final merged = <String, int>{};
    for (final usageMap in maps) {
      for (final entry in usageMap.entries) {
        merged[entry.key] = (merged[entry.key] ?? 0) + entry.value;
      }
    }
    return merged;
  }

  static Map<String, dynamic> _topCoachUsage(Map<String, int> usage) {
    if (usage.isEmpty) {
      return {'coachId': '', 'count': 0};
    }

    final entries = usage.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.compareTo(b.key);
      });

    final top = entries.first;
    return {'coachId': top.key, 'count': top.value};
  }

  // 전체 유저 수 가져오기
  static Future<int> getTotalUsers() async {
    final snapshot = await _firestore.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  // 오늘 접속한 유저 수 (DAU)
  static Future<int> getDailyActiveUsers() async {
    final todayStr = _dateKey(DateTime.now());

    final doc = await _firestore
        .collection('analytics')
        .doc('dau_$todayStr')
        .get();
    final data = doc.data();
    if (data == null) return 0;

    final activeUsers = data['activeUsers'];
    if (activeUsers is List) return activeUsers.length;

    return 0;
  }

  // 실제 접속 기록이 있는 날짜 수
  static Future<int> getUsageDayCount() async {
    final snapshot = await _firestore.collection('analytics').get();
    return snapshot.docs.where((doc) => doc.id.startsWith('dau_')).length;
  }

  // 코치별 사용 비율 가져오기
  static Future<Map<String, int>> getCoachUsageStats() async {
    final snapshot = await _firestore.collection('users').get();
    final Map<String, int> coachStats = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final userData = data['userData'];
      final coachId = userData is Map
          ? userData['selected_coach_id'] as String? ?? 'unknown'
          : 'unknown';
      coachStats[coachId] = (coachStats[coachId] ?? 0) + 1;
    }

    return coachStats;
  }

  // 기능별 사용량 가져오기
  static Future<Map<String, int>> getFeatureUsageStats() async {
    final doc = await _firestore
        .collection('analytics')
        .doc('feature_usage')
        .get();
    final data = doc.data();
    if (data == null) return {};

    final Map<String, int> stats = {};
    data.forEach((key, value) {
      if (value is int) {
        stats[key] = value;
      } else if (value is num) {
        stats[key] = value.toInt();
      }
    });

    return stats;
  }

  // 오늘 기능별 사용량 가져오기
  static Future<Map<String, int>> getDailyFeatureUsageStats() async {
    final todayStr = _dateKey(DateTime.now());
    final usersSnapshot = await _firestore.collection('users').get();
    final Map<String, int> stats = {};

    await Future.wait(
      usersSnapshot.docs.map((userDoc) async {
        final dailyDoc = await userDoc.reference
            .collection('analytics_daily')
            .doc(todayStr)
            .get();
        final data = dailyDoc.data();
        if (data == null) return;

        final features = data['features'];
        if (features is! Map) return;

        features.forEach((key, value) {
          final count = value is num ? value.toInt() : 0;
          if (count > 0) {
            stats[key.toString()] = (stats[key.toString()] ?? 0) + count;
          }
        });
      }),
    );

    return stats;
  }

  // 누적 API 사용량 가져오기
  static Future<Map<String, int>> getApiCostStats() async {
    final doc = await _firestore.collection('analytics').doc('api_costs').get();
    final data = doc.data();
    if (data == null) {
      return {'totalTokens': 0, 'totalCostWon': 0, 'apiCallCount': 0};
    }

    return {
      'totalTokens': _readInt(data, 'totalTokens'),
      'totalCostWon': _normaliseCostWon(
        storedCostWon: _readInt(data, 'totalCostWon'),
        tokenCount: _readInt(data, 'totalTokens'),
      ),
      'apiCallCount': _readInt(data, 'apiCallCount') > 0
          ? _readInt(data, 'apiCallCount')
          : _readInt(data, 'chatCount'),
    };
  }

  // 오늘 API 사용량 가져오기
  static Future<Map<String, int>> getDailyApiCostStats() async {
    final todayStr = _dateKey(DateTime.now());
    final doc = await _firestore
        .collection('analytics')
        .doc('api_costs_daily_$todayStr')
        .get();
    final data = doc.data();
    if (data == null) {
      return {'totalTokens': 0, 'totalCostWon': 0, 'apiCallCount': 0};
    }

    return {
      'totalTokens': _readInt(data, 'totalTokens'),
      'totalCostWon': _normaliseCostWon(
        storedCostWon: _readInt(data, 'totalCostWon'),
        tokenCount: _readInt(data, 'totalTokens'),
      ),
      'apiCallCount': _readInt(data, 'apiCallCount'),
    };
  }

  // 전체 대화량 가져오기
  static Future<Map<String, int>> getConversationUsageStats() async {
    final doc = await _firestore
        .collection('analytics')
        .doc('conversation_usage')
        .get();
    final data = doc.data();
    if (data == null) {
      return {
        'totalUserMessages': 0,
        'totalCoachReplies': 0,
        'apiReplies': 0,
        'localReplies': 0,
      };
    }

    return {
      'totalUserMessages': _readInt(data, 'totalUserMessages'),
      'totalCoachReplies': _readInt(data, 'totalCoachReplies'),
      'apiReplies': _readInt(data, 'apiReplies'),
      'localReplies': _readInt(data, 'localReplies'),
    };
  }

  // 오늘 대화량 가져오기
  static Future<Map<String, int>> getDailyConversationUsageStats() async {
    final todayStr = _dateKey(DateTime.now());
    final doc = await _firestore
        .collection('analytics')
        .doc('conversation_usage_daily_$todayStr')
        .get();
    final data = doc.data();
    if (data == null) {
      return {
        'totalUserMessages': 0,
        'totalCoachReplies': 0,
        'apiReplies': 0,
        'localReplies': 0,
      };
    }

    return {
      'totalUserMessages': _readInt(data, 'totalUserMessages'),
      'totalCoachReplies': _readInt(data, 'totalCoachReplies'),
      'apiReplies': _readInt(data, 'apiReplies'),
      'localReplies': _readInt(data, 'localReplies'),
    };
  }

  // 테스터별 누적/일별 사용량 가져오기
  static Future<List<Map<String, dynamic>>> getTesterUsageStats() async {
    final now = DateTime.now();
    final todayStr = _dateKey(now);
    final recentDateKeys = _recentDateKeys(now, 7);
    final usersSnapshot = await _firestore.collection('users').get();

    final rows = await Future.wait(
      usersSnapshot.docs.map((userDoc) async {
        final uid = userDoc.id;
        final userDocData = userDoc.data();
        final userData = userDocData['userData'];
        final userDataMap = userData is Map
            ? Map<String, dynamic>.from(userData)
            : <String, dynamic>{};

        final summaryDoc = await userDoc.reference
            .collection('analytics')
            .doc('summary')
            .get();
        final recentDailyDocs = await Future.wait(
          recentDateKeys.map(
            (dateKey) => userDoc.reference
                .collection('analytics_daily')
                .doc(dateKey)
                .get(),
          ),
        );

        final summary = summaryDoc.data() ?? <String, dynamic>{};
        final todayDailyDoc = recentDailyDocs.firstWhere(
          (doc) => doc.id == todayStr,
        );
        final daily = todayDailyDoc.data() ?? <String, dynamic>{};
        final joinedAt = _readDateTime(summary, 'joinedAt');
        final activeDates = summary['activeDates'];

        final today = now;
        final joinedDay = joinedAt == null
            ? null
            : DateTime(joinedAt.year, joinedAt.month, joinedAt.day);
        final todayDay = DateTime(today.year, today.month, today.day);
        final daysSinceJoined = joinedDay == null
            ? 0
            : todayDay.difference(joinedDay).inDays + 1;
        final activeDays = activeDates is List ? activeDates.length : 0;

        final totalUserMessages = _readInt(summary, 'totalUserMessages');
        final todayTokens = _readInt(daily, 'totalTokens');
        final totalTokens = _readInt(summary, 'totalTokens');
        final todayCostWon = _normaliseCostWon(
          storedCostWon: _readInt(daily, 'totalCostWon'),
          tokenCount: todayTokens,
        );
        final totalCostWon = _normaliseCostWon(
          storedCostWon: _readInt(summary, 'totalCostWon'),
          tokenCount: totalTokens,
        );

        final summaryFeatures =
            summary['features'] as Map<String, dynamic>? ?? {};
        final dailyFeatures = daily['features'] as Map<String, dynamic>? ?? {};

        final todayTopCoach = _topCoachUsage(
          _readUsageMap(daily, 'coachUsage'),
        );
        final weeklyTopCoach = _topCoachUsage(
          _mergeUsageMaps(
            recentDailyDocs.map(
              (doc) => _readUsageMap(
                doc.data() ?? <String, dynamic>{},
                'coachUsage',
              ),
            ),
          ),
        );

        return {
          'uid': uid,
          'email': _firstNonEmptyString([
            summary['email'],
            daily['email'],
            userDocData['email'],
            userDocData['loginEmail'],
            userDataMap['email'],
          ]),
          'todayTopCoachId': todayTopCoach['coachId'],
          'todayTopCoachCount': todayTopCoach['count'],
          'weeklyTopCoachId': weeklyTopCoach['coachId'],
          'weeklyTopCoachCount': weeklyTopCoach['count'],
          'planType': _readString(userDataMap, 'plan_type'),
          'joinedAt': joinedAt,
          'lastActiveAt': _readDateTime(summary, 'lastActiveAt'),
          'daysSinceJoined': daysSinceJoined,
          'activeDays': activeDays,
          'todayUserMessages': _readInt(daily, 'totalUserMessages'),
          'totalUserMessages': totalUserMessages,
          'todayApiReplies': _readInt(daily, 'apiReplies'),
          'todayLocalReplies': _readInt(daily, 'localReplies'),
          'apiReplies': _readInt(summary, 'apiReplies'),
          'localReplies': _readInt(summary, 'localReplies'),
          'todayApiCalls': _readInt(daily, 'apiCallCount'),
          'apiCallCount': _readInt(summary, 'apiCallCount'),
          'todayTokens': todayTokens,
          'totalTokens': totalTokens,
          'todayCostWon': todayCostWon,
          'totalCostWon': totalCostWon,
          'featCoreRecToday': _readInt(dailyFeatures, 'cheat_core_recommend'),
          'featCoreRecTotal': _readInt(summaryFeatures, 'cheat_core_recommend'),
          'featScheduleToday': _readInt(dailyFeatures, 'cheat_schedule_escort'),
          'featScheduleTotal': _readInt(
            summaryFeatures,
            'cheat_schedule_escort',
          ),
          'featVisionToday': _readInt(dailyFeatures, 'cheat_today_vision'),
          'featVisionTotal': _readInt(summaryFeatures, 'cheat_today_vision'),
          'featMorningToday': _readInt(dailyFeatures, 'morning_call'),
          'featMorningTotal': _readInt(summaryFeatures, 'morning_call'),
          'featNightToday': _readInt(dailyFeatures, 'night_call'),
          'featNightTotal': _readInt(summaryFeatures, 'night_call'),
          'featReminderToday': _readInt(dailyFeatures, 'core_reminder'),
          'featReminderTotal': _readInt(summaryFeatures, 'core_reminder'),
          'avgMessagesSinceJoin': daysSinceJoined > 0
              ? totalUserMessages / daysSinceJoined
              : 0,
          'avgMessagesPerActiveDay': activeDays > 0
              ? totalUserMessages / activeDays
              : 0,
          'avgCostSinceJoin': daysSinceJoined > 0
              ? totalCostWon / daysSinceJoined
              : 0,
          'avgCostPerActiveDay': activeDays > 0 ? totalCostWon / activeDays : 0,
        };
      }),
    );

    rows.sort((a, b) {
      final bMessages = b['totalUserMessages'] as int? ?? 0;
      final aMessages = a['totalUserMessages'] as int? ?? 0;
      return bMessages.compareTo(aMessages);
    });

    return rows;
  }

  // 최근 타임라인 가져오기 (가장 최근 20개)
  static Future<List<Map<String, dynamic>>> getRecentTimeline() async {
    // 모든 유저의 타임라인을 모으려면 collectionGroup을 사용할 수 있습니다.
    final snapshot = await _firestore
        .collectionGroup('timeline')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // 최근 에러 로그 가져오기
  static Future<List<Map<String, dynamic>>> getRecentErrors() async {
    final snapshot = await _firestore
        .collection('error_logs')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
