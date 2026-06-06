import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/summary_widget.dart';
import '../widgets/usage_chart_widget.dart';
import '../widgets/tester_usage_widget.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/error_log_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<String> _menuTitles = [
    '종합 요약',
    '코치 및 기능 사용량',
    '테스터별 사용량',
    '테스터 활동 및 타임라인',
    '에러 로그',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          // 사이드바
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Text(
                  '냥냥코치\nAdmin Dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B5EA8),
                  ),
                ),
                const SizedBox(height: 48),
                _buildMenuItem(Icons.dashboard, '종합 요약', 0),
                _buildMenuItem(Icons.pie_chart, '코치 및 기능 사용량', 1),
                _buildMenuItem(Icons.table_chart, '테스터별 사용량', 2),
                _buildMenuItem(Icons.people, '테스터 활동 및 타임라인', 3),
                _buildMenuItem(Icons.error_outline, '에러 로그', 4),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.black12),
          // 메인 컨텐츠 영역
          Expanded(
            child: Column(
              children: [
                // 앱바/헤더
                Container(
                  height: 60,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _menuTitles[_selectedIndex],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        tooltip: '로그아웃',
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        icon: const CircleAvatar(
                          backgroundColor: Color(0xFF6B5EA8),
                          child: Icon(Icons.logout, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.black12),
                // 화면 내용
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF6B5EA8) : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF6B5EA8) : Colors.grey[800],
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF6B5EA8).withValues(alpha: 0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const SummaryWidget();
      case 1:
        return const UsageChartWidget();
      case 2:
        return const TesterUsageWidget();
      case 3:
        return const TimelineWidget();
      case 4:
        return const ErrorLogWidget();
      default:
        return const SizedBox.shrink();
    }
  }
}
