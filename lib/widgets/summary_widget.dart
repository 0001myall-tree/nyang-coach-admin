import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'tester_usage_widget.dart';

class SummaryWidget extends StatefulWidget {
  const SummaryWidget({super.key});

  @override
  State<SummaryWidget> createState() => _SummaryWidgetState();
}

class _SummaryWidgetState extends State<SummaryWidget> {
  int _totalUsers = 0;
  int _dailyActiveUsers = 0;
  int _usageDays = 0;
  int _dailyUserMessages = 0;
  int _totalUserMessages = 0;
  int _apiReplies = 0;
  int _localReplies = 0;
  int _apiCallCount = 0;
  int _dailyTokens = 0;
  int _totalTokens = 0;
  int _totalCostWon = 0;
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
      final usageDays = await AdminService.getUsageDayCount();
      final apiStats = await AdminService.getApiCostStats();
      final dailyApiStats = await AdminService.getDailyApiCostStats();
      final conversationStats = await AdminService.getConversationUsageStats();
      final dailyConversationStats =
          await AdminService.getDailyConversationUsageStats();

      setState(() {
        _totalUsers = total;
        _dailyActiveUsers = dau;
        _usageDays = usageDays;
        _dailyUserMessages = dailyConversationStats['totalUserMessages'] ?? 0;
        _totalUserMessages = conversationStats['totalUserMessages'] ?? 0;
        _apiReplies = conversationStats['apiReplies'] ?? 0;
        _localReplies = conversationStats['localReplies'] ?? 0;
        _apiCallCount = apiStats['apiCallCount'] ?? 0;
        _dailyTokens = dailyApiStats['totalTokens'] ?? 0;
        _totalTokens = apiStats['totalTokens'] ?? 0;
        _totalCostWon = apiStats['totalCostWon'] ?? 0;
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
    final costPerTester = _totalUsers > 0
        ? (_totalCostWon / _totalUsers).round()
        : 0;

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
            _buildStatCard(
              '오늘 접속한 테스터 (DAU)',
              '$_dailyActiveUsers 명',
              Icons.directions_run,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              '재방문률 (Retention)',
              '$retentionRate %',
              Icons.trending_up,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard(
              '일별 사용자 메시지',
              '$_dailyUserMessages 회',
              Icons.today_outlined,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              '누적 사용자 메시지',
              '$_totalUserMessages 회',
              Icons.chat_bubble_outline,
              subtitle: '사용일수 $_usageDays일',
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'API 응답 / 로컬 응답',
              '$_apiReplies / $_localReplies',
              Icons.compare_arrows,
            ),
            const SizedBox(width: 16),
            _buildStatCard('API 호출', '$_apiCallCount 회', Icons.cloud_outlined),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard(
              '누적 토큰',
              '${_formatNumber(_totalTokens)} tokens',
              Icons.data_usage,
              subtitle: '오늘 ${_formatNumber(_dailyTokens)} tokens',
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              '예상 API 비용 / 테스터',
              '${_formatNumber(costPerTester)} 원',
              Icons.payments_outlined,
              subtitle: '총 ${_formatNumber(_totalCostWon)}원 / $_totalUsers명 기준',
            ),
          ],
        ),
        const SizedBox(height: 48),
        const Expanded(child: TesterUsageWidget()),
      ],
    );
  }

  String _formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    String? subtitle,
  }) {
    return Expanded(
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
            Row(
              children: [
                Icon(icon, color: const Color(0xFF6B5EA8), size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
