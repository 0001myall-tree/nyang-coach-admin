import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/admin_service.dart';

class TesterUsageWidget extends StatefulWidget {
  const TesterUsageWidget({super.key});

  @override
  State<TesterUsageWidget> createState() => _TesterUsageWidgetState();
}

class _TesterUsageWidgetState extends State<TesterUsageWidget> {
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final rows = await AdminService.getTesterUsageStats();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '테스터별 사용량',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '가입 후 전체 기간과 실제 사용일 기준으로 메시지, 호출, 비용을 함께 봅니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                tooltip: '새로고침',
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _loadData();
                },
                icon: const Icon(Icons.refresh, color: Color(0xFF6B5EA8)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _rows.isEmpty
                ? const Center(
                    child: Text(
                      '아직 테스터별 사용량이 없습니다.\n업데이트된 앱에서 사용 기록이 쌓이면 표시됩니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF5F2FF),
                          ),
                          columnSpacing: 28,
                          columns: const [
                            DataColumn(label: Text('접속 이메일')),
                            DataColumn(label: Text('플랜')),
                            DataColumn(label: Text('코치')),
                            DataColumn(label: Text('가입 후')),
                            DataColumn(label: Text('사용일수')),
                            DataColumn(label: Text('오늘 핵심 추천(오늘/누적)')),
                            DataColumn(label: Text('일정 에스코트(오늘/누적)')),
                            DataColumn(label: Text('비전 오늘(오늘/누적)')),
                            DataColumn(label: Text('모닝콜(오늘/누적)')),
                            DataColumn(label: Text('나이트콜(오늘/누적)')),
                            DataColumn(label: Text('리마인더(오늘/누적)')),
                            DataColumn(label: Text('오늘 메시지')),
                            DataColumn(label: Text('누적 메시지')),
                            DataColumn(label: Text('오늘 API/로컬')),
                            DataColumn(label: Text('누적 API/로컬')),
                            DataColumn(label: Text('오늘 토큰')),
                            DataColumn(label: Text('누적 토큰')),
                            DataColumn(label: Text('오늘 비용')),
                            DataColumn(label: Text('누적 비용')),
                            DataColumn(label: Text('가입일 평균')),
                            DataColumn(label: Text('사용일 평균')),
                            DataColumn(label: Text('마지막 접속')),
                          ],
                          rows: _rows.map(_buildRow).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(Map<String, dynamic> row) {
    return DataRow(
      cells: [
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(_testerLabel(row), overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(_plainLabel(row['planType']))),
        DataCell(Text(_coachLabel(row['coachId']))),
        DataCell(Text(_daysLabel(row['daysSinceJoined']))),
        DataCell(Text(_daysLabel(row['activeDays']))),
        DataCell(
          Text(
            '${_int(row['featCoreRecToday'])} / ${_int(row['featCoreRecTotal'])}',
          ),
        ),
        DataCell(
          Text(
            '${_int(row['featScheduleToday'])} / ${_int(row['featScheduleTotal'])}',
          ),
        ),
        DataCell(
          Text(
            '${_int(row['featVisionToday'])} / ${_int(row['featVisionTotal'])}',
          ),
        ),
        DataCell(
          Text(
            '${_int(row['featMorningToday'])} / ${_int(row['featMorningTotal'])}',
          ),
        ),
        DataCell(
          Text(
            '${_int(row['featNightToday'])} / ${_int(row['featNightTotal'])}',
          ),
        ),
        DataCell(
          Text(
            '${_int(row['featReminderToday'])} / ${_int(row['featReminderTotal'])}',
          ),
        ),
        DataCell(Text('${_int(row['todayUserMessages'])}회')),
        DataCell(
          Text(
            '${_formatNumber(_int(row['totalUserMessages']))}회\n'
            '가입일 ${_decimal(row['avgMessagesSinceJoin'])}회/일\n'
            '사용일 ${_decimal(row['avgMessagesPerActiveDay'])}회/일',
          ),
        ),
        DataCell(
          Text(
            '${_int(row['todayApiReplies'])} / ${_int(row['todayLocalReplies'])}',
          ),
        ),
        DataCell(
          Text('${_int(row['apiReplies'])} / ${_int(row['localReplies'])}'),
        ),
        DataCell(Text('${_formatNumber(_int(row['todayTokens']))} tokens')),
        DataCell(Text('${_formatNumber(_int(row['totalTokens']))} tokens')),
        DataCell(Text('${_formatNumber(_int(row['todayCostWon']))}원')),
        DataCell(Text('${_formatNumber(_int(row['totalCostWon']))}원')),
        DataCell(Text('${_formatWon(row['avgCostSinceJoin'])}/일')),
        DataCell(Text('${_formatWon(row['avgCostPerActiveDay'])}/일')),
        DataCell(Text(_dateLabel(row['lastActiveAt']))),
      ],
    );
  }

  String _testerLabel(Map<String, dynamic> row) {
    final email = row['email']?.toString() ?? '';
    if (email.isNotEmpty) return email;
    return row['uid']?.toString() ?? '-';
  }

  String _coachLabel(dynamic value) {
    switch (value?.toString()) {
      case 'nyang':
        return '냥냥';
      case 'boyfriend':
        return '남친';
      case 'secretary_male':
        return '남비서';
      case 'secretary_female':
        return '여비서';
      default:
        return _plainLabel(value);
    }
  }

  String _plainLabel(dynamic value) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? '-' : text;
  }

  String _daysLabel(dynamic value) {
    final days = _int(value);
    return days > 0 ? '$days일' : '-';
  }

  String _dateLabel(dynamic value) {
    if (value is DateTime) {
      return DateFormat('MM/dd HH:mm').format(value);
    }
    return '-';
  }

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  String _decimal(dynamic value) {
    if (value is num) return value.toStringAsFixed(1);
    return '0.0';
  }

  String _formatWon(dynamic value) {
    final amount = value is num ? value.round() : 0;
    return '${_formatNumber(amount)}원';
  }

  String _formatNumber(int value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }
}
