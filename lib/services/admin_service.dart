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
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final snapshot = await _firestore.collection('users')
        .where('lastLoginDate', isEqualTo: todayStr)
        .count()
        .get();
        
    return snapshot.count ?? 0;
  }

  // 코치별 사용 비율 가져오기
  static Future<Map<String, int>> getCoachUsageStats() async {
    final snapshot = await _firestore.collection('users').get();
    final Map<String, int> coachStats = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final coachId = data['selectedCoachId'] as String? ?? 'unknown';
      coachStats[coachId] = (coachStats[coachId] ?? 0) + 1;
    }
    
    return coachStats;
  }
}
