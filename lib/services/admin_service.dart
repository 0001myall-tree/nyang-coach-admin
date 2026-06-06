import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

  // 누적 API 사용량 가져오기
  static Future<Map<String, int>> getApiCostStats() async {
    final doc = await _firestore.collection('analytics').doc('api_costs').get();
    final data = doc.data();
    if (data == null) {
      return {'totalTokens': 0, 'totalCostWon': 0, 'apiCallCount': 0};
    }

    return {
      'totalTokens': _readInt(data, 'totalTokens'),
      'totalCostWon': _readInt(data, 'totalCostWon'),
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
      'totalCostWon': _readInt(data, 'totalCostWon'),
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
    final todayStr = _dateKey(DateTime.now());
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
        final dailyDoc = await userDoc.reference
            .collection('analytics_daily')
            .doc(todayStr)
            .get();

        final summary = summaryDoc.data() ?? <String, dynamic>{};
        final daily = dailyDoc.data() ?? <String, dynamic>{};
        final joinedAt = _readDateTime(summary, 'joinedAt');
        final activeDates = summary['activeDates'];

        final today = DateTime.now();
        final joinedDay = joinedAt == null
            ? null
            : DateTime(joinedAt.year, joinedAt.month, joinedAt.day);
        final todayDay = DateTime(today.year, today.month, today.day);
        final daysSinceJoined = joinedDay == null
            ? 0
            : todayDay.difference(joinedDay).inDays + 1;
        final activeDays = activeDates is List ? activeDates.length : 0;

        final totalUserMessages = _readInt(summary, 'totalUserMessages');
        final totalCostWon = _readInt(summary, 'totalCostWon');

        return {
          'uid': uid,
          'email': _readString(summary, 'email').isNotEmpty
              ? _readString(summary, 'email')
              : _readString(userDocData, 'email'),
          'coachId': _readString(userDataMap, 'selected_coach_id'),
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
          'todayTokens': _readInt(daily, 'totalTokens'),
          'totalTokens': _readInt(summary, 'totalTokens'),
          'todayCostWon': _readInt(daily, 'totalCostWon'),
          'totalCostWon': totalCostWon,
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
