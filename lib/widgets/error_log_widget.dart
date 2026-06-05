import 'package:flutter/material.dart';

class ErrorLogWidget extends StatelessWidget {
  const ErrorLogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시 에러 데이터
    final List<Map<String, dynamic>> errorData = [
      {'time': '2026-06-05 19:30:12', 'type': 'System', 'message': 'Firebase connection timeout', 'user': 'N/A'},
      {'time': '2026-06-05 18:45:00', 'type': 'AI API', 'message': 'Gemini API Rate Limit Exceeded', 'user': 'tester1@email.com'},
      {'time': '2026-06-05 14:20:33', 'type': 'System', 'message': 'Audio player failed to load asset', 'user': 'tester2@email.com'},
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
          const Text(
            '시스템 및 채팅 에러 로그',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFFF0F2F5)),
                columns: const [
                  DataColumn(label: Text('발생 시간', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('타입', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('에러 메시지', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('관련 유저', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: errorData.map((e) => DataRow(
                  cells: [
                    DataCell(Text(e['time'])),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: e['type'] == 'AI API' ? Colors.orange.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          e['type'],
                          style: TextStyle(
                            color: e['type'] == 'AI API' ? Colors.orange[800] : Colors.red[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    ),
                    DataCell(Text(e['message'])),
                    DataCell(Text(e['user'])),
                  ],
                )).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }
}
