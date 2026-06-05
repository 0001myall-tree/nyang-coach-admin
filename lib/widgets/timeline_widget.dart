import 'package:flutter/material.dart';

class TimelineWidget extends StatelessWidget {
  const TimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시 데이터
    final List<Map<String, dynamic>> timelineData = [
      {'user': 'tester1@email.com', 'action': 'AI 채팅 (선생님 코치)', 'time': '방금 전', 'cost': '\$0.001'},
      {'user': 'tester2@email.com', 'action': '모닝콜 설정 (할매 코치)', 'time': '5분 전', 'cost': '-'},
      {'user': 'tester3@email.com', 'action': '할일 완료 (운동)', 'time': '12분 전', 'cost': '-'},
      {'user': 'tester1@email.com', 'action': 'AI 채팅 (선생님 코치)', 'time': '20분 전', 'cost': '\$0.002'},
      {'user': 'tester4@email.com', 'action': '앱 최초 가입', 'time': '1시간 전', 'cost': '-'},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '테스터 최근 활동 타임라인',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '총 누적 API 비용: \$0.342',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6B5EA8)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: timelineData.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final data = timelineData[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0F2F5),
                    child: Icon(Icons.person, color: Colors.grey),
                  ),
                  title: Text(data['user'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(data['action']),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(data['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      if (data['cost'] != '-')
                        Text(data['cost'], style: const TextStyle(color: Color(0xFF6B5EA8), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
