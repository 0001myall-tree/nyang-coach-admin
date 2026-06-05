import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 전체 유저 수 가져오기
  static Future<int> getTotalUsers() async {
    final snapshot = await _firestore.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  // 오늘 접속한 유저 수 (DAU)
  static Future<int> getDailyActiveUsers() async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

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

    int readInt(String key) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    return {
      'totalTokens': readInt('totalTokens'),
      'totalCostWon': readInt('totalCostWon'),
      'apiCallCount': readInt('apiCallCount') > 0
          ? readInt('apiCallCount')
          : readInt('chatCount'),
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

    int readInt(String key) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    return {
      'totalUserMessages': readInt('totalUserMessages'),
      'totalCoachReplies': readInt('totalCoachReplies'),
      'apiReplies': readInt('apiReplies'),
      'localReplies': readInt('localReplies'),
    };
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
