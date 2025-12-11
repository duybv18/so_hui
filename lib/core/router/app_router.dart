import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:so_hui_app/features/hui/presentation/dashboard_screen.dart';
import 'package:so_hui_app/features/hui/presentation/hui_list_screen.dart';
import 'package:so_hui_app/features/hui/presentation/hui_form_screen.dart';
import 'package:so_hui_app/features/hui/presentation/hui_detail_screen.dart';
import 'package:so_hui_app/features/contributions/presentation/contribution_detail_screen.dart';
import 'package:so_hui_app/features/reports/presentation/reports_screen.dart';
import 'package:so_hui_app/features/settings/presentation/settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/hui-list',
        builder: (context, state) => const HuiListScreen(),
      ),
      GoRoute(
        path: '/hui/new',
        builder: (context, state) => const HuiFormScreen(),
      ),
      GoRoute(
        path: '/hui/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return HuiFormScreen(huiId: id);
        },
      ),
      GoRoute(
        path: '/hui/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return HuiDetailScreen(huiId: id);
        },
      ),
      GoRoute(
        path: '/contribution/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ContributionDetailScreen(contributionId: id);
        },
      ),
      GoRoute(
        path: '/reports/:huiId',
        builder: (context, state) {
          final huiId = int.parse(state.pathParameters['huiId']!);
          return ReportsScreen(huiId: huiId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
