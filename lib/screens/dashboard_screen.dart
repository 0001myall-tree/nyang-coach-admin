import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _updatePlan(String uid, UserData userData, String newPlan) async {
    userData.planType = newPlan;
    if (newPlan == 'none') {
      userData.planExpiresAt = null;
    } else {
      userData.planExpiresAt = DateTime.now().add(const Duration(days: 30)); // 기본 30일
    }
    
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'userData': userData.toJson(),
    }, SetOptions(merge: true));
  }

  Future<void> _addPoints(String uid, UserData userData, int pointsToAdd) async {
    userData.points += pointsToAdd;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'userData': userData.toJson(),
    }, SetOptions(merge: true));
  }

  void _showEditDialog(String uid, UserData userData) {
    final pointsController = TextEditingController(text: userData.points.toString());
    String selectedPlan = userData.planType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('유저 정보 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('유저 ID: $uid', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPlan,
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('무료 (none)')),
                  DropdownMenuItem(value: 'friends', child: Text('프렌즈 (friends)')),
                  DropdownMenuItem(value: 'master', child: Text('마스터 (master)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedPlan = val);
                },
                decoration: const InputDecoration(labelText: '구독 플랜'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(labelText: '보유 포인트'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                userData.planType = selectedPlan;
                userData.points = int.tryParse(pointsController.text) ?? userData.points;
                await FirebaseFirestore.instance.collection('users').doc(uid).set({
                  'userData': userData.toJson(),
                }, SetOptions(merge: true));
                if (mounted) Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('냥냥코치 관리자 대시보드', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B7CFF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('데이터를 불러오는데 실패했습니다: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;
              
              UserData userData = UserData();
              if (data.containsKey('userData')) {
                userData = UserData.fromJson(data['userData']);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(data['email'] ?? '이메일 없음 (UID: ${doc.id})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '플랜: ${userData.planType} | 포인트: ${userData.points} | 보유 코치: ${userData.ownedCoaches.join(', ')}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => _addPoints(doc.id, userData, 100),
                        child: const Text('+100P'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _showEditDialog(doc.id, userData),
                        child: const Text('상세 수정'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
