import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_analytics_screen.dart';
import 'admin_meal_list_screen.dart';
import 'admin_order_list_screen.dart';

/// Placeholder for the Users management screen.
class AdminUserListScreen extends StatelessWidget {
  const AdminUserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Users',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab index provider
// ---------------------------------------------------------------------------

/// Tracks the currently selected bottom navigation tab index.
final _adminTabIndexProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// AdminHomeScreen
// ---------------------------------------------------------------------------

/// The root screen of the Admin Dashboard.
///
/// Hosts a [BottomNavigationBar] with four tabs:
/// Orders | Meals | Analytics | Users
///
/// Each tab renders a placeholder screen until the real screens are
/// implemented in subsequent tasks.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  static final _tabs = const [
    AdminOrderListScreen(),
    AdminMealListScreen(),
    AdminAnalyticsScreen(),
    AdminUserListScreen(),
  ];

  static const _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long),
      label: 'Orders',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.restaurant_menu),
      label: 'Meals',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart),
      label: 'Analytics',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Users',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(_adminTabIndexProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surface,
        items: _navItems,
        onTap: (index) =>
            ref.read(_adminTabIndexProvider.notifier).state = index,
      ),
    );
  }
}
