import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/admin_service.dart';

class UsageChartWidget extends StatefulWidget {
  const UsageChartWidget({super.key});

  @override
  State<UsageChartWidget> createState() => _UsageChartWidgetState();
}

class _UsageChartWidgetState extends State<UsageChartWidget> {
  Map<String, int> _coachStats = {};
  Map<String, int> _dailyFeatureStats = {};
  Map<String, int> _featureStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await AdminService.getCoachUsageStats();
      final dailyFeatureStats = await AdminService.getDailyFeatureUsageStats();
      final featureStats = await AdminService.getFeatureUsageStats();
      setState(() {
        _coachStats = stats;
        _dailyFeatureStats = dailyFeatureStats;
        _featureStats = featureStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Row(
      children: [
        // 코치별 사용량 파이 차트
        Expanded(
          child: Container(
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
                const Text(
                  '코치별 선택 비율',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _coachStats.isEmpty
                      ? const Center(child: Text('데이터가 없습니다.'))
                      : PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _getPieSections(),
                          ),
                        ),
                ),
                // 레전드
                Wrap(
                  spacing: 16,
                  children: _coachStats.keys
                      .map((key) => _buildLegend(key))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // 기능별 사용량 요약
        Expanded(
          child: Container(
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
                const Text(
                  '기능별 사용 횟수',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  '각 기능이 오늘 몇 번 쓰였는지와 지금까지의 누적 횟수를 함께 봅니다.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: _featureStats.isEmpty
                      ? const Center(child: Text('데이터가 없습니다.'))
                      : ListView.separated(
                          itemCount: _featureRows.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final featureName = _featureRows[index];
                            return _buildFeatureRow(featureName);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getPieSections() {
    final colors = [
      const Color(0xFF6B5EA8),
      const Color(0xFFE5B94A),
      Colors.green,
      Colors.blue,
    ];
    int index = 0;
    return _coachStats.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}명',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<String> get _featureRows {
    final names = <String>{
      ..._featureStats.keys,
      ..._dailyFeatureStats.keys,
    }.toList();
    names.sort((a, b) {
      final todayCompare = (_dailyFeatureStats[b] ?? 0).compareTo(
        _dailyFeatureStats[a] ?? 0,
      );
      if (todayCompare != 0) return todayCompare;
      return (_featureStats[b] ?? 0).compareTo(_featureStats[a] ?? 0);
    });
    return names;
  }

  String _featureDisplayName(String featureName) {
    switch (featureName) {
      case 'morning_call':
        return '모닝콜';
      case 'core_reminder':
        return '핵심 리마인더';
      case 'night_call':
        return '나이트콜';
      case 'chat':
        return 'AI 채팅';
      case 'tasks':
        return '할일';
      case 'cheat_core_recommend':
        return '오늘 핵심 추천';
      case 'cheat_schedule_escort':
        return '일정 에스코트';
      case 'cheat_today_vision':
        return '비전을 위한 오늘';
      case 'move_task':
        return '다른 날짜로 이동';
      case 'milestone_memo_organize':
        return '메모 정리';
      default:
        return featureName;
    }
  }

  Widget _buildLegend(String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Text(title),
      ],
    );
  }

  Widget _buildFeatureRow(String featureName) {
    final today = _dailyFeatureStats[featureName] ?? 0;
    final total = _featureStats[featureName] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0FF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _featureDisplayName(featureName),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          _buildCountPill('오늘', today, const Color(0xFF6B5EA8)),
          const SizedBox(width: 8),
          _buildCountPill('누적', total, const Color(0xFF8F8A9F)),
        ],
      ),
    );
  }

  Widget _buildCountPill(String label, int count, Color color) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count회',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
