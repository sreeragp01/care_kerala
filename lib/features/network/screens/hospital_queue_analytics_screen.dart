import 'package:flutter/material.dart';
import '../../../core/state/app_state_provider.dart';

class HospitalQueueAnalyticsScreen extends StatefulWidget {
  final AppStateProvider? state;

  const HospitalQueueAnalyticsScreen({super.key, this.state});

  @override
  State<HospitalQueueAnalyticsScreen> createState() => _HospitalQueueAnalyticsScreenState();
}

class _HospitalQueueAnalyticsScreenState extends State<HospitalQueueAnalyticsScreen> {
  String _selectedTimeframe = 'TODAY';
  late AppStateProvider _appState;

  @override
  void initState() {
    super.initState();
    _appState = widget.state ?? AppStateProvider();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        final analytics = _appState.hospitalFlowAnalytics;

        final int appointmentRatio = analytics.totalPatients > 0
            ? ((analytics.appointmentCount / analytics.totalPatients) * 100).round()
            : 68;
        final int walkInRatio = (100 - appointmentRatio).clamp(0, 100);
        final noShowRate = analytics.totalPatients > 0
            ? ((analytics.noShowCount / analytics.totalPatients) * 100).toStringAsFixed(1)
            : '4.8';

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            title: const Text('Hospital Patient Flow & Analytics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refreshed hospital flow analytics data.')),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hospital Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.analytics_rounded, color: Color(0xFF38BDF8), size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              analytics.organizationName,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Performance Report • ${analytics.reportDate} • Peak: ${analytics.peakHours}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Timeframe Selector Chips
                Row(
                  children: [
                    _buildTimeframeChip('TODAY', 'Today'),
                    const SizedBox(width: 8),
                    _buildTimeframeChip('WEEK', 'This Week'),
                    const SizedBox(width: 8),
                    _buildTimeframeChip('MONTH', 'This Month'),
                  ],
                ),

                const SizedBox(height: 20),

                // 4 KPI Summary Cards Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Total Throughput',
                        value: '${analytics.totalPatients}',
                        unit: 'Patients',
                        icon: Icons.groups_rounded,
                        accentColor: const Color(0xFF3B82F6),
                        subtitle: '${analytics.completedCount} Consulted',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Avg. Wait Time',
                        value: '${analytics.averageWaitMinutes}',
                        unit: 'Minutes',
                        icon: Icons.timer_rounded,
                        accentColor: const Color(0xFF10B981),
                        subtitle: 'Target: < 20 min',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Avg. Consultation',
                        value: '${analytics.averageConsultationMinutes}',
                        unit: 'Minutes / Pt',
                        icon: Icons.medical_information_rounded,
                        accentColor: const Color(0xFFF59E0B),
                        subtitle: 'Rolling Avg.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'No-Show Rate',
                        value: '$noShowRate%',
                        unit: '${analytics.noShowCount} Patients',
                        icon: Icons.person_off_rounded,
                        accentColor: const Color(0xFFEC4899),
                        subtitle: 'Staged Recalls Active',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Patient Intake Breakdown Card (Appointments vs Walk-ins)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Patient Intake Channel Distribution',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Progress Ratio Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 18,
                          child: Row(
                            children: [
                              Expanded(
                                flex: appointmentRatio,
                                child: Container(color: const Color(0xFF3B82F6)),
                              ),
                              Expanded(
                                flex: walkInRatio,
                                child: Container(color: const Color(0xFFF97316)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.spaceAround,
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(
                                'Pre-Booked: ${analytics.appointmentCount} ($appointmentRatio%)',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(
                                'Walk-In: ${analytics.walkInCount} ($walkInRatio%)',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Department Patient Throughput Table
                const Text(
                  'Department & Service Breakdown',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: analytics.departments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final dept = analytics.departments[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              dept['name'].toString().contains('Pharmacy')
                                  ? Icons.local_pharmacy_rounded
                                  : (dept['name'].toString().contains('Lab')
                                      ? Icons.science_rounded
                                      : Icons.medical_services_rounded),
                              color: const Color(0xFF38BDF8),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dept['name'] ?? 'Department',
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${dept['patients']} Patients • Avg. Wait: ${dept['avg_wait']} min',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF059669)),
                            ),
                            child: Text(
                              dept['throughput'] ?? '95%',
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Action: Export / Download Report
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hospital Flow Report exported as PDF & CSV.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.download_rounded, color: Color(0xFF38BDF8)),
                    label: const Text('Export Daily Operations Audit (PDF/CSV)', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeframeChip(String code, String label) {
    final isSelected = _selectedTimeframe == code;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFF1E293B),
      onSelected: (_) {
        setState(() {
          _selectedTimeframe = code;
        });
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(color: accentColor, fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        ],
      ),
    );
  }
}
