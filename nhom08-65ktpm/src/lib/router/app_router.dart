import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Route path constants for the Travel Buddy application.
abstract final class AppRoutes {
  static const String auth = '/auth';
  static const String goals = '/goals';
  static const String savings = '/savings';
  static const String itinerary = '/itinerary';
  static const String budget = '/budget';
}

/// Provides the application's [GoRouter] instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.auth,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth_and_group',
        builder: (context, state) => const _ModulePlaceholderScreen(
          title: 'Đăng nhập & Nhóm',
          subtitle: 'Module auth_and_group',
          currentIndex: -1,
        ),
      ),
      GoRoute(
        path: AppRoutes.goals,
        name: 'goal_and_checklist',
        builder: (context, state) => const _ModulePlaceholderScreen(
          title: 'Mục tiêu & Checklist',
          subtitle: 'Module 1: goal_and_checklist',
          currentIndex: 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.savings,
        name: 'saving_discipline_and_momo',
        builder: (context, state) => const _ModulePlaceholderScreen(
          title: 'Quỹ MoMo & Streak',
          subtitle: 'Module 2: saving_discipline_and_momo',
          currentIndex: 1,
        ),
      ),
      GoRoute(
        path: AppRoutes.itinerary,
        name: 'place_and_itinerary_planner',
        builder: (context, state) => const _ModulePlaceholderScreen(
          title: 'Điểm đến & Lịch trình',
          subtitle: 'Module 3: place_and_itinerary_planner',
          currentIndex: 2,
        ),
      ),
      GoRoute(
        path: AppRoutes.budget,
        name: 'budget_and_expense_cashew',
        builder: (context, state) => const _ModulePlaceholderScreen(
          title: 'Ngân sách & Chi tiêu',
          subtitle: 'Module 4: budget_and_expense_cashew',
          currentIndex: 3,
        ),
      ),
    ],
  );
});

class _ModulePlaceholderScreen extends StatelessWidget {
  const _ModulePlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.currentIndex,
  });

  final String title;
  final String subtitle;
  final int currentIndex;

  static const _routes = [
    AppRoutes.goals,
    AppRoutes.savings,
    AppRoutes.itinerary,
    AppRoutes.budget,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (currentIndex >= 0)
            IconButton(
              tooltip: 'Đăng nhập & Nhóm',
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => context.go(AppRoutes.auth),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (currentIndex < 0) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.goals),
                  child: const Text('Vào ứng dụng'),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: currentIndex >= 0
          ? NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) => context.go(_routes[index]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.checklist_outlined),
                  selectedIcon: Icon(Icons.checklist),
                  label: 'Mục tiêu',
                ),
                NavigationDestination(
                  icon: Icon(Icons.savings_outlined),
                  selectedIcon: Icon(Icons.savings),
                  label: 'Quỹ MoMo',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Lịch trình',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: 'Ngân sách',
                ),
              ],
            )
          : null,
    );
  }
}
