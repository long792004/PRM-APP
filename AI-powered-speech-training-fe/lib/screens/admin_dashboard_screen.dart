import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = ApiService.getAdminStats();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tổng quan về hoạt động và hiệu suất của users',
          style: TextStyle(fontSize: 16, color: AppColors.gray600),
        ),
        const SizedBox(height: 24),

        // Statistics Cards
        FutureBuilder<Map<String, dynamic>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            final totalUsers = snapshot.data?['totalUsers'] ?? '-';
            final totalTopics = snapshot.data?['totalTopics'] ?? '-';
            final totalRecordings = snapshot.data?['totalRecordings'] ?? '-';

            return GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 1.5 : 2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MetricCard(
                  title: 'Tổng Users',
                  value: snapshot.connectionState == ConnectionState.waiting
                      ? '...'
                      : '$totalUsers',
                  change: 'Tổng số học viên',
                  icon: Icons.people_outline,
                  color: AppColors.primary,
                  isPositive: true,
                ),
                _MetricCard(
                  title: 'Tổng Topics',
                  value: snapshot.connectionState == ConnectionState.waiting
                      ? '...'
                      : '$totalTopics',
                  change: 'Đang hoạt động',
                  icon: Icons.book_outlined,
                  color: AppColors.secondary,
                  isPositive: true,
                ),
                _MetricCard(
                  title: 'Tổng bài luyện',
                  value: snapshot.connectionState == ConnectionState.waiting
                      ? '...'
                      : '$totalRecordings',
                  change: 'Tất cả thời gian',
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  isPositive: true,
                ),
                _MetricCard(
                  title: 'Refresh',
                  value: '↻',
                  change: 'Nhấn để tải lại',
                  icon: Icons.refresh,
                  color: AppColors.warning,
                  isPositive: true,
                  onTap: () => setState(() {
                    _statsFuture = ApiService.getAdminStats();
                  }),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Chart
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray200.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
              border: Border.all(color: AppColors.gray200.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hoạt động tuần qua',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Số lượng bài luyện theo ngày',
                    style: TextStyle(fontSize: 14, color: AppColors.gray600),
                  ),
                  const SizedBox(height: 24),
                  Expanded(child: _WeeklyActivityChart()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
  final bool isPositive;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
    required this.isPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isPositive)
                  const Icon(
                    Icons.arrow_upward,
                    size: 12,
                    color: AppColors.success,
                  )
                else
                  const Icon(
                    Icons.arrow_downward,
                    size: 12,
                    color: AppColors.error,
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 11,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  final List<double> data = [12, 19, 15, 23, 18, 26, 20];
  final List<String> labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  _WeeklyActivityChart({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 28,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${labels[group.x.toInt()]}\n${rod.toY.toInt()} bài',
                const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[value.toInt()],
                      style: const TextStyle(
                        color: AppColors.gray600,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppColors.gray600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: AppColors.gray200),
            left: BorderSide(color: AppColors.gray200),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: AppColors.gray200,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: AppColors.primary,
                width: isMobile ? 16 : 32,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
