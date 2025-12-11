import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_hui_app/core/providers/providers.dart';
import 'package:so_hui_app/common/widgets/stats_card.dart';
import 'package:so_hui_app/common/widgets/hui_card.dart';
import 'package:so_hui_app/common/widgets/empty_state.dart';
import 'package:so_hui_app/common/utils/currency_formatter.dart';
import 'package:so_hui_app/features/hui/domain/hui_calculation_service.dart';

final dashboardDataProvider = FutureProvider((ref) async {
  final huiRepo = ref.watch(huiRepositoryProvider);
  final contributionRepo = ref.watch(contributionRepositoryProvider);
  final calcService = ref.watch(huiCalculationServiceProvider);

  final huiGroups = await huiRepo.getAllHuiGroups();
  
  double totalPaid = 0;
  double totalRemaining = 0;
  int totalOverdue = 0;

  for (final hui in huiGroups) {
    if (hui.id != null) {
      final contributions = await contributionRepo.getContributionsByHuiGroup(hui.id!);
      totalPaid += calcService.calculateTotalPaid(contributions);
      totalRemaining += calcService.calculateTotalRemaining(contributions, hui.contributionAmount);
      totalOverdue += contributions.where((c) => calcService.isOverdue(c)).length;
    }
  }

  return {
    'huiGroups': huiGroups,
    'totalPaid': totalPaid,
    'totalRemaining': totalRemaining,
    'totalOverdue': totalOverdue,
  };
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ Hụi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: dashboardData.when(
        data: (data) {
          final huiGroups = data['huiGroups'] as List;
          final totalPaid = data['totalPaid'] as double;
          final totalRemaining = data['totalRemaining'] as double;
          final totalOverdue = data['totalOverdue'] as int;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardDataProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng quan',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: StatsCard(
                                title: 'Tổng số dây',
                                value: '${huiGroups.length}',
                                icon: Icons.widgets,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatsCard(
                                title: 'Kỳ trễ hạn',
                                value: '$totalOverdue',
                                icon: Icons.warning,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StatsCard(
                          title: 'Tổng đã góp',
                          value: CurrencyFormatter.formatCurrency(totalPaid),
                          icon: Icons.payments,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        StatsCard(
                          title: 'Còn phải góp',
                          value: CurrencyFormatter.formatCurrency(totalRemaining),
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dây hụi gần đây',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/hui-list'),
                              child: const Text('Xem tất cả'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (huiGroups.isEmpty)
                  SliverFillRemaining(
                    child: EmptyState(
                      message: 'Chưa có dây hụi nào\nHãy tạo dây hụi đầu tiên',
                      icon: Icons.widgets,
                      actionLabel: 'Tạo dây hụi',
                      onAction: () => context.push('/hui/new'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final hui = huiGroups[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: HuiCard(
                              huiGroup: hui,
                              onTap: () => context.push('/hui/${hui.id}'),
                            ),
                          );
                        },
                        childCount: huiGroups.length > 5 ? 5 : huiGroups.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Lỗi: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/hui/new'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo dây hụi'),
      ),
    );
  }
}
