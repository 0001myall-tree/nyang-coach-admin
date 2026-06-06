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
      final featureStats = await AdminService.getFeatureUsageStats();
      setState(() {
        _coachStats = stats;
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
                  color: Colors.black.withOpacity(0.05),
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
        // 기능별 사용량 바 차트 (임시 데이터)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '기능별 사용 횟수 (오늘)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _featureStats.isEmpty
                      ? const Center(child: Text('데이터가 없습니다.'))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            barGroups: _getFeatureBarGroups(),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                        final labels = _featureLabels;
                                        final index = value.toInt();
                                        if (index < 0 ||
                                            index >= labels.length) {
                                          return const Text('');
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            _featureDisplayName(labels[index]),
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                          ),
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

  List<String> get _featureLabels => _featureStats.keys.toList();

  List<BarChartGroupData> _getFeatureBarGroups() {
    final entries = _featureStats.entries.toList();
    return List.generate(entries.length, (index) {
      return _makeBarData(index, entries[index].value.toDouble());
    });
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

  BarChartGroupData _makeBarData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF6B5EA8),
          width: 20,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
