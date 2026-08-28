import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_state_provider.dart';
import '../../maps/screens/field_map_screen.dart';

class AmbulanceDispatchScreen extends StatelessWidget {
  final AppStateProvider state;

  const AmbulanceDispatchScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final drivers = state.ambulanceDrivers;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ambulance Dispatch Tracker'),
            actions: [
              IconButton(
                tooltip: 'Live Ambulance Fleet Map',
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
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            itemBuilder: (ctx, i) {
              final d = drivers[i];
              final isAvailable = d.currentStatus == 'Available';
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                            child: Icon(
                              Icons.airport_shuttle_rounded,
                              color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.driverName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Vehicle: ${d.vehicleNumber} • ${d.district}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? (isDark ? AppColors.darkLightGreenSurface : AppColors.successSurface)
                                  : (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              d.currentStatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAvailable
                                    ? (isDark ? AppColors.darkPrimaryGreen : AppColors.success)
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Calling Driver ${d.driverName} at ${d.phone}...')),
                                );
                              },
                              icon: const Icon(Icons.call_rounded, size: 14),
                              label: Text(d.phone, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final newStatus = isAvailable ? 'Dispatched' : 'Available';
                                state.updateAmbulanceStatus(d.id, newStatus);
                              },
                              icon: Icon(isAvailable ? Icons.send_rounded : Icons.check_circle_outline, size: 14),
                              label: Text(isAvailable ? 'Dispatch' : 'Available', style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAvailable
                                    ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                                    : Colors.teal,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                minimumSize: Size.zero,
                              ),
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
        );
      },
    );
  }
}
