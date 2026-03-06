import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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
          style: TextStyle(
            fontSize: 16,
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(height: 24),

        // Statistics Cards
        GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          shrinkWrap: true,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 1.5 : 2,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _MetricCard(
              title: 'Tổng Users',
              value: '248',
              change: '+12% so với tháng trước',
              icon: Icons.people_outline,
              color: AppColors.primary,
              isPositive: true,
            ),
            _MetricCard(
              title: 'Tổng Topics',
              value: '64',
              change: 'Đang hoạt động',
              icon: Icons.book_outlined,
              color: AppColors.secondary,
              isPositive: true,
            ),
            _MetricCard(
              title: 'Bài luyện tuần này',
              value: '1,342',
              change: '+18% so với tuần trước',
              icon: Icons.trending_up,
              color: AppColors.success,
              isPositive: true,
            ),
            _MetricCard(
              title: 'Điểm TB',
              value: '7.8',
              change: '+0.5 điểm so với tháng trước',
              icon: Icons.star_outline,
              color: AppColors.warning,
              isPositive: true,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Chart
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hoạt động tuần qua',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Số lượng bài luyện theo ngày',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _WeeklyActivityChart(),
                  ),
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

  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
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
