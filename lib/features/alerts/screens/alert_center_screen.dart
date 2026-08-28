import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/alert_model.dart';
import '../../../core/repositories/alert_repository.dart';
import '../../../core/state/app_state_provider.dart';

class AlertCenterScreen extends StatefulWidget {
  final AppStateProvider state;

  const AlertCenterScreen({super.key, required this.state});

  @override
  State<AlertCenterScreen> createState() => _AlertCenterScreenState();
}

class _AlertCenterScreenState extends State<AlertCenterScreen> {
  List<ClinicalAlertModel> _alerts = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    final alerts = await AlertRepository.getAlerts();
    if (mounted) {
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    }
  }

  Future<void> _acknowledge(String alertId) async {
    final success = await AlertRepository.acknowledgeAlert(alertId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert acknowledged and logged.'), backgroundColor: Colors.teal),
      );
      _loadAlerts();
    }
  }


  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return AppColors.danger;
      case 'HIGH':
        return Colors.deepOrange;
      case 'MEDIUM':
        return AppColors.warning;
      case 'LOW':
        return AppColors.info;
      default:
        return AppColors.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredAlerts = _alerts.where((a) {
      if (_selectedFilter == 'ALL') return true;
      return a.severity == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Alert Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                    },
                    selectedColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                    checkmarkColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Alert List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredAlerts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 48, color: isDark ? AppColors.darkPrimaryGreen : Colors.teal),
                            const SizedBox(height: 12),
                            Text(
                              'No active clinical alerts.',
                              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredAlerts.length,
                        itemBuilder: (context, index) {
                          final alert = filteredAlerts[index];
                          final color = _getSeverityColor(alert.severity);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          alert.severity,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          alert.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    alert.message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Status: ${alert.status}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: alert.status == 'ACKNOWLEDGED'
                                                ? (isDark ? AppColors.darkPrimaryGreen : Colors.teal)
                                                : Colors.deepOrange,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (alert.status == 'OPEN')
                                        ElevatedButton.icon(
                                          onPressed: () => _acknowledge(alert.id),
                                          icon: const Icon(Icons.done_all, size: 14),
                                          label: const Text('Acknowledge', style: TextStyle(fontSize: 11)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
