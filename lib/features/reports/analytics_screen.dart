import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  final AppStateProvider state;

  const AnalyticsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating production PDF/Excel analytical report...')),
              );
            },
            tooltip: 'Export PDF Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Home Visits Monthly Growth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Bar Chart Component
            Card(
              child: Container(
                height: 220,
                padding: const EdgeInsets.all(16.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 200,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            switch (val.toInt()) {
                              case 0: return const Text('Apr', style: TextStyle(fontSize: 11));
                              case 1: return const Text('May', style: TextStyle(fontSize: 11));
                              case 2: return const Text('Jun', style: TextStyle(fontSize: 11));
                              case 3: return const Text('Jul', style: TextStyle(fontSize: 11));
                              case 4: return const Text('Aug', style: TextStyle(fontSize: 11));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 110, color: AppColors.secondaryGreen)]),
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 140, color: AppColors.secondaryGreen)]),
                      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 165, color: AppColors.secondaryGreen)]),
                      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 180, color: AppColors.secondaryGreen)]),
                      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 195, color: AppColors.primaryGreen)]),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Patient Distribution by Palliative Tier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTierProgressRow('Category A (Bedridden)', 0.45, AppColors.danger, '45%'),
                    _buildTierProgressRow('Category B (Semi-mobile)', 0.30, AppColors.warning, '30%'),
                    _buildTierProgressRow('Category C (Mobile/Chronic)', 0.15, AppColors.info, '15%'),
                    _buildTierProgressRow('Category D (Supportive)', 0.10, AppColors.success, '10%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading CareLink Kerala Full Analytical Excel Ledger (.xlsx)')),
                  );
                },
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Export Complete Excel Dataset'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierProgressRow(String label, double val, Color color, String percentStr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(percentStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: val,
            color: color,
            backgroundColor: AppColors.lightSand,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
