import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/state/app_state_provider.dart';
import '../../maps/screens/field_map_screen.dart';
import 'visit_entry_screen.dart';
import 'palliative_operations_center_screen.dart';

class VisitScheduleScreen extends StatelessWidget {
  final AppStateProvider state;

  const VisitScheduleScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final visits = state.visits;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Today's Visit Schedule"),
            actions: [
              IconButton(
                tooltip: 'Palliative Operations Center',
                icon: const Icon(Icons.dashboard_customize_rounded, color: AppColors.emeraldLight),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PalliativeOperationsCenterScreen(state: state),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Open Live Route Map',
                icon: const Icon(Icons.map_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FieldMapScreen(state: state),
                    ),
                  );
                },
              ),
              if (state.pendingOfflineSyncCount > 0)
                IconButton(
                  icon: const Icon(Icons.sync_problem_rounded, color: AppColors.warning),
                  onPressed: () => state.syncOfflineQueue(),
                  tooltip: 'Sync Offline Visits',
                ),
            ],
          ),
          body: Column(
            children: [
              // Offline Sync Status Banner
              if (state.pendingOfflineSyncCount > 0)
                Container(
                  color: AppColors.warningSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${state.pendingOfflineSyncCount} Visit notes saved offline locally. Will auto-sync when online.',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => state.syncOfflineQueue(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Sync Now', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: visits.isEmpty
                    ? const Center(child: Text('No home visits scheduled for today.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: visits.length,
                        itemBuilder: (ctx, i) {
                          final visit = visits[i];
                          return _buildVisitCard(context, visit);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVisitCard(BuildContext context, VisitModel visit) {
    final isCompleted = visit.status == 'Completed';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? (isDark ? AppColors.darkLightGreenSurface : AppColors.successSurface)
                        : (isDark ? AppColors.darkInfoSurface : AppColors.infoSurface),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    visit.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? (isDark ? AppColors.darkPrimaryGreen : AppColors.success)
                          : AppColors.info,
                    ),
                  ),
                ),
                Text(
                  '${visit.scheduledDate} • ${visit.scheduledTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              visit.patientName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    visit.patientAddress,
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (visit.gpsCheckInTime != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSand,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.gps_fixed_rounded, size: 16, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${visit.gpsCheckInTime} (${visit.gpsLocationName})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FieldMapScreen(state: state, initialVisit: visit),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text('Route Map', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VisitEntryScreen(state: state, visit: visit),
                        ),
                      );
                    },
                    icon: Icon(isCompleted ? Icons.visibility : Icons.check_circle_outline, size: 16),
                    label: Text(isCompleted ? 'View Note' : 'Start Visit', style: const TextStyle(fontSize: 12)),
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
