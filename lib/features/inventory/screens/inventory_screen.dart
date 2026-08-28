import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_state_provider.dart';

class InventoryScreen extends StatelessWidget {
  final AppStateProvider state;

  const InventoryScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Inventory & Equipment'),
              bottom: const TabBar(
                indicatorColor: AppColors.primaryGreen,
                labelColor: AppColors.primaryGreen,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(text: 'Medicine Stock'),
                  Tab(text: 'Equipment Loan Tracking'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildMedicineStockTab(context),
                _buildEquipmentTab(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMedicineStockTab(BuildContext context) {
    final medicines = state.medicines;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medicines.length,
      itemBuilder: (ctx, i) {
        final med = medicines[i];
        final isLowStock = med.isLowStock;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: isLowStock
                          ? (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface)
                          : (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface),
                      child: Icon(
                        Icons.medication_rounded,
                        color: isLowStock ? AppColors.warning : (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            'Batch: ${med.batchNumber} • Expires: ${med.expiryDate}',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                          Text(
                            'Reorder Level: ${med.reorderLevel} ${med.unit}',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${med.stockQuantity} ${med.unit}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isLowStock
                                ? AppColors.warning
                                : (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                          ),
                        ),
                        if (isLowStock)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkWarningSurface : AppColors.warningSurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Low Stock', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning)),
                          ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showRestockMedicineDialog(context, med.id, med.name),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Restock', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showIssueMedicineDialog(context, med.id, med.name),
                      icon: const Icon(Icons.outbox_rounded, size: 16),
                      label: const Text('Issue Stock', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }

  Widget _buildEquipmentTab(BuildContext context) {
    final equipment = state.equipment;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: equipment.length,
      itemBuilder: (ctx, i) {
        final eq = equipment[i];
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
                    Expanded(
                      child: Text(eq.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: eq.maintenanceStatus == 'Good'
                            ? (isDark ? AppColors.darkLightGreenSurface : AppColors.successSurface)
                            : (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        eq.maintenanceStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: eq.maintenanceStatus == 'Good'
                              ? (isDark ? AppColors.darkPrimaryGreen : AppColors.success)
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPill('Total Units', '${eq.totalCount}', isDark),
                    _buildPill('Available', '${eq.availableCount}', isDark),
                    _buildPill('On Loan', '${eq.loanedCount}', isDark),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (eq.loanedCount > 0) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showReturnEquipmentDialog(context, eq.id, eq.name),
                          icon: const Icon(Icons.keyboard_return_rounded, size: 16),
                          label: const Text('Return Unit', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: eq.availableCount > 0
                            ? () => _showLoanEquipmentDialog(context, eq.id, eq.name)
                            : null,
                        icon: const Icon(Icons.handshake_outlined, size: 16),
                        label: const Text('Loan Unit', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
    );
  }

  Widget _buildPill(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
      ],
    );
  }

  void _showIssueMedicineDialog(BuildContext context, String medId, String medName) {
    final qtyCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: Text('Issue $medName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 440 : double.maxFinite,
          child: SingleChildScrollView(
            child: TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity to Issue', prefixIcon: Icon(Icons.outbox_rounded)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              state.issueMedicine(medId, int.tryParse(qtyCtrl.text) ?? 10);
              Navigator.pop(ctx);
            },
            child: const Text('Issue'),
          ),
        ],
      ),
    );
  }

  void _showRestockMedicineDialog(BuildContext context, String medId, String medName) {
    final qtyCtrl = TextEditingController(text: '50');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: Text('Restock $medName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 440 : double.maxFinite,
          child: SingleChildScrollView(
            child: TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity to Add to Stock', prefixIcon: Icon(Icons.add_box_outlined)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              state.restockMedicine(medId, int.tryParse(qtyCtrl.text) ?? 50);
              Navigator.pop(ctx);
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }

  void _showLoanEquipmentDialog(BuildContext context, String eqId, String eqName) {
    final patientCtrl = TextEditingController(text: 'Karthyayani Amma');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: Text('Loan $eqName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 440 : double.maxFinite,
          child: SingleChildScrollView(
            child: TextField(
              controller: patientCtrl,
              decoration: const InputDecoration(labelText: 'Patient Name', prefixIcon: Icon(Icons.person_outline)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              state.loanEquipmentToPatient(eqId, patientCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Loan'),
          ),
        ],
      ),
    );
  }

  void _showReturnEquipmentDialog(BuildContext context, String eqId, String eqName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: Text('Return $eqName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Confirm returning 1 unit of $eqName back to inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              state.returnEquipmentFromPatient(eqId, 1);
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }
}
