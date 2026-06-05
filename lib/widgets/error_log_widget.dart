import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ErrorLogWidget extends StatefulWidget {
  const ErrorLogWidget({super.key});

  @override
  State<ErrorLogWidget> createState() => _ErrorLogWidgetState();
}

class _ErrorLogWidgetState extends State<ErrorLogWidget> {
  List<Map<String, dynamic>> _errorData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await AdminService.getRecentErrors();
      setState(() {
        _errorData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      return DateFormat('MM/dd HH:mm').format(timestamp.toDate());
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

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
            child: _errorData.isEmpty
              ? const Center(child: Text('발생한 에러가 없습니다!', style: TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFFF0F2F5)),
                columns: const [
                  DataColumn(label: Text('발생 시간', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('유저 ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('에러 메시지', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('관련 컨텍스트', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _errorData.map((e) => DataRow(
                  cells: [
                    DataCell(Text(_formatTime(e['timestamp']))),
                    DataCell(Text(e['uid']?.toString() ?? 'anonymous')),
                    DataCell(Text(e['errorMessage']?.toString() ?? '알 수 없는 에러')),
                    DataCell(Text(e['context']?.toString() ?? '')),
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

