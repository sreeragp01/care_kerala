import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_state_provider.dart';
import 'palliative_care_team_screen.dart';
import 'family_caregiver_portal_screen.dart';
import 'medication_tracker_screen.dart';
import 'nurse_visit_execution_screen.dart';
import '../../maps/screens/field_map_screen.dart';

class PalliativeOperationsCenterScreen extends StatefulWidget {
  final AppStateProvider? state;

  const PalliativeOperationsCenterScreen({super.key, this.state});

  @override
  State<PalliativeOperationsCenterScreen> createState() => _PalliativeOperationsCenterScreenState();
}

class _PalliativeOperationsCenterScreenState extends State<PalliativeOperationsCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state == null) {
      return const Scaffold(body: Center(child: Text('AppStateProvider not provided')));
    }

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final pendingRequests = state.homeVisitRequests.where((r) => r.status == 'PENDING').toList();
        final visits = state.visits;
        final dailyRoutes = state.dailyRoutes;

        return Scaffold(
          backgroundColor: const Color(0xFF0D1B1E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF132A2F),
            elevation: 0,
            title: const Row(
              children: [
                Icon(Icons.dashboard_customize_rounded, color: AppColors.emeraldLight, size: 24),
                SizedBox(width: 10),
                Text(
                  'Palliative Operations Center',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Live Field Route Map',
                icon: const Icon(Icons.map_rounded, color: AppColors.emeraldLight),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FieldMapScreen(state: state)),
                  );
                },
              ),
              IconButton(
                tooltip: 'Multi-Disciplinary Teams',
                icon: const Icon(Icons.groups_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PalliativeCareTeamScreen(state: state)),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.emeraldLight,
              indicatorWeight: 3,
              labelColor: AppColors.emeraldLight,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  icon: const Icon(Icons.route_rounded, size: 20),
                  text: 'Daily Route (${dailyRoutes.isNotEmpty ? dailyRoutes.first.totalStops : 0})',
                ),
                Tab(
                  icon: const Icon(Icons.pending_actions_rounded, size: 20),
                  text: 'Intake Requests (${pendingRequests.length})',
                ),
                Tab(
                  icon: const Icon(Icons.home_work_rounded, size: 20),
                  text: 'All Visits (${visits.length})',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Top KPI Metric Dashboard
              _buildMetricDashboard(state),

              // Main Tab View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDailyRouteTab(state),
                    _buildIntakeRequestsTab(state),
                    _buildAllVisitsTab(state),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomQuickActions(state),
        );
      },
    );
  }

  Widget _buildMetricDashboard(AppStateProvider state) {
    final activePatients = state.patients.length;
    final todaysVisits = state.visits.length;
    final pendingRequests = state.homeVisitRequests.where((r) => r.status == 'PENDING').length;
    final activeTeams = state.careTeams.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF102327),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildMetricPill('Patients', '$activePatients', Icons.personal_injury_rounded, AppColors.emeraldLight)),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricPill('Today Visits', '$todaysVisits', Icons.schedule_rounded, AppColors.secondary)),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricPill('Requests', '$pendingRequests', Icons.pending_actions_rounded, AppColors.warning)),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricPill('Care Teams', '$activeTeams', Icons.groups_rounded, Colors.purpleAccent)),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF132A2F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDailyRouteTab(AppStateProvider state) {
    final dailyRoutes = state.dailyRoutes;

    if (dailyRoutes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route_rounded, size: 64, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('No Daily Route Generated', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Route planner sequences daily stops for assigned field nurses.', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }

    final route = dailyRoutes.first;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Route Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF132A2F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      route.careTeamName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      route.status,
                      style: const TextStyle(color: AppColors.emeraldLight, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Primary Nurse: ${route.primaryNurseName} • Date: ${route.routeDate} • ${route.totalStops} Sequenced Stops',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(route.notes, style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Sequenced Route Stops', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),

        ...route.stops.map((stop) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF132A2F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: stop.isCompleted ? AppColors.emerald.withValues(alpha: 0.4) : Colors.white12),
            ),
            child: Row(
              children: [
                // Stop Sequence Number Badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: stop.isCompleted ? AppColors.emerald : const Color(0xFF0D1B1E),
                    shape: BoxShape.circle,
                    border: Border.all(color: stop.isCompleted ? AppColors.emerald : Colors.white24),
                  ),
                  child: Center(
                    child: stop.isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : Text('${stop.sequenceOrder}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.patientName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(stop.patientAddress, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('Est. Arrival: ${stop.estimatedArrivalTime} • ${stop.visitType}',
                          style: const TextStyle(color: AppColors.emeraldLight, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Open Nurse Console',
                  icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.emeraldLight, size: 30),
                  onPressed: () {
                    final visit = state.visits.firstWhere(
                      (v) => v.patientName == stop.patientName,
                      orElse: () => state.visits.first,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NurseVisitExecutionScreen(state: state, visit: visit)),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildIntakeRequestsTab(AppStateProvider state) {
    final requests = state.homeVisitRequests;

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('No Incoming Visit Requests', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final isPending = req.status == 'PENDING';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF132A2F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isPending ? AppColors.warning.withValues(alpha: 0.4) : Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      req.patientName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPending ? AppColors.warning.withValues(alpha: 0.2) : AppColors.emerald.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      req.status,
                      style: TextStyle(
                        color: isPending ? AppColors.warning : AppColors.emeraldLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${req.visitType} (${req.urgency})', style: const TextStyle(color: AppColors.emeraldLight, fontSize: 12)),
              Text('Preferred: ${req.preferredDate} (${req.preferredTimeSlot})', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF0D1B1E), borderRadius: BorderRadius.circular(8)),
                child: Text('Reason: ${req.reasonAndSymptoms}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              if (isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => state.rejectHomeVisitRequest(req.id, 'Outside coverage'),
                        child: const Text('Decline', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => state.acceptHomeVisitRequest(req.id, assignedNurse: 'Nurse Anitha'),
                        child: const Text('Accept & Schedule', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllVisitsTab(AppStateProvider state) {
    final visits = state.visits;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF132A2F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(visit.patientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(visit.patientAddress, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('Nurse: ${visit.assignedNurseName} • Date: ${visit.scheduledDate} at ${visit.scheduledTime}',
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NurseVisitExecutionScreen(state: state, visit: visit)),
                  );
                },
                child: const Text('Open', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomQuickActions(AppStateProvider state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF132A2F),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.emeraldLight,
                side: const BorderSide(color: AppColors.emeraldLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.family_restroom_rounded, size: 16),
              label: const Text('Family Portal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FamilyCaregiverPortalScreen(state: state)),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.medication_liquid_rounded, size: 16),
              label: const Text('Medications', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MedicationTrackerScreen(state: state)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
