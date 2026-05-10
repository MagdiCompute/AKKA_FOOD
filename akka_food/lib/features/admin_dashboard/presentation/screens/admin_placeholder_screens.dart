import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Admin placeholder screens
//
// These are temporary screens used for deep-link routing until the real
// implementations are built in subsequent tasks.
// ---------------------------------------------------------------------------

// Note: AdminOrderDetailScreen has been replaced by the real implementation
// in admin_order_detail_screen.dart.

/// Placeholder for the User detail screen.
class AdminUserDetailScreen extends StatelessWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Detail')),
      body: Center(
        child: Text(
          'Admin User Detail\nUser ID: $userId',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
