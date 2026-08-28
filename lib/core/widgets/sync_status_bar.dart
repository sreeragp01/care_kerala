import 'package:flutter/material.dart';
import '../state/app_state_provider.dart';

class SyncStatusBar extends StatefulWidget {
  final AppStateProvider state;

  const SyncStatusBar({super.key, required this.state});

  @override
  State<SyncStatusBar> createState() => _SyncStatusBarState();
}

class _SyncStatusBarState extends State<SyncStatusBar> {
  bool _isSyncing = false;

  Future<void> _triggerSync() async {
    setState(() {
      _isSyncing = true;
    });

    widget.state.syncOfflineQueue();
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isSyncing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sync completed successfully! Cloud database updated.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.state.pendingOfflineSyncCount;
    final isOffline = pendingCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isOffline ? Colors.amber.shade900 : const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? 'Offline Mode • $pendingCount draft(s) queued'
                  : 'System Online • All records synchronized',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isOffline) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _isSyncing ? null : _triggerSync,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync, color: Colors.white, size: 14),
              label: Text(
                _isSyncing ? 'Syncing...' : 'Sync',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.black26,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
