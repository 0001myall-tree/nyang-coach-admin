import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class SummaryWidget extends StatefulWidget {
  const SummaryWidget({super.key});

  @override
  State<SummaryWidget> createState() => _SummaryWidgetState();
}

class _SummaryWidgetState extends State<SummaryWidget> {
  int _totalUsers = 0;
  int _dailyActiveUsers = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final total = await AdminService.getTotalUsers();
      final dau = await AdminService.getDailyActiveUsers();
      
      setState(() {
        _totalUsers = total;
        _dailyActiveUsers = dau;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading summary: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 재방문률 (단순 계산)
    final retentionRate = _totalUsers > 0 
        ? (_dailyActiveUsers / _totalUsers * 100).toStringAsFixed(1) 
        : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '핵심 지표 요약',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildStatCard('총 가입 테스터', '$_totalUsers 명', Icons.people),
            const SizedBox(width: 16),
            _buildStatCard('오늘 접속한 테스터 (DAU)', '$_dailyActiveUsers 명', Icons.directions_run),
            const SizedBox(width: 16),
            _buildStatCard('재방문률 (Retention)', '$retentionRate %', Icons.trending_up),
          ],
        ),
        const SizedBox(height: 48),
        // 추가적인 그래프가 들어갈 자리
        Expanded(
          child: Container(
            width: double.infinity,
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
            child: const Center(
              child: Text(
                '상세 재방문률 차트 영역',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
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
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF6B5EA8), size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
