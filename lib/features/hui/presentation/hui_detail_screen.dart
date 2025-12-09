import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_hui_app/core/database/database.dart';
import 'package:so_hui_app/core/providers/providers.dart';
import 'package:so_hui_app/models/models.dart';
import 'package:so_hui_app/common/utils/currency_formatter.dart';
import 'package:so_hui_app/common/utils/date_formatter.dart';
import 'package:so_hui_app/common/widgets/stats_card.dart';

final huiDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, huiId) async {
  final huiRepo = ref.watch(huiRepositoryProvider);
  final contributionRepo = ref.watch(contributionRepositoryProvider);
  final calcService = ref.watch(huiCalculationServiceProvider);

  final hui = await huiRepo.getHuiGroupById(huiId);
  if (hui == null) throw Exception('Hui not found');

  final contributions = await contributionRepo.getContributionsByHuiGroup(huiId);
  final totalPaid = calcService.calculateTotalPaid(contributions);
  final totalRemaining = calcService.calculateTotalRemaining(contributions, hui.contributionAmount);
  final progress = calcService.calculateProgress(contributions);
  final overdueContributions = contributions.where((c) => calcService.isOverdue(c)).toList();

  return {
    'hui': hui,
    'contributions': contributions,
    'totalPaid': totalPaid,
    'totalRemaining': totalRemaining,
    'progress': progress,
    'overdueContributions': overdueContributions,
  };
});

class HuiDetailScreen extends ConsumerWidget {
  final int huiId;

  const HuiDetailScreen({super.key, required this.huiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailData = ref.watch(huiDetailProvider(huiId));

    return Scaffold(
      body: detailData.when(
        data: (data) {
          final hui = data['hui'] as HuiGroupModel;
          final contributions = data['contributions'] as List<ContributionModel>;
          final totalPaid = data['totalPaid'] as double;
          final totalRemaining = data['totalRemaining'] as double;
          final progress = data['progress'] as double;
          final overdueContributions = data['overdueContributions'] as List<ContributionModel>;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(hui.name),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.push('/hui/$huiId/edit'),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa dây hụi'),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xác nhận xóa'),
                            content: const Text('Bạn có chắc muốn xóa dây hụi này?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          final huiRepo = ref.read(huiRepositoryProvider);
                          await huiRepo.deleteHuiGroup(huiId);
                          if (context.mounted) {
                            context.go('/');
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                context,
                                'Loại hụi',
                                hui.type == HuiType.fixed ? 'Hụi chết (không lãi)' : 'Hụi sống (có lãi)',
                                Icons.info,
                              ),
                              const Divider(),
                              _buildInfoRow(
                                context,
                                'Tổng số kỳ',
                                '${hui.totalPeriods} kỳ',
                                Icons.repeat,
                              ),
                              const Divider(),
                              _buildInfoRow(
                                context,
                                'Số thành viên',
                                '${hui.numMembers} người',
                                Icons.people,
                              ),
                              const Divider(),
                              _buildInfoRow(
                                context,
                                'Mệnh giá góp',
                                CurrencyFormatter.formatCurrency(hui.contributionAmount),
                                Icons.attach_money,
                              ),
                              const Divider(),
                              _buildInfoRow(
                                context,
                                'Tần suất',
                                _getFrequencyText(hui.frequency),
                                Icons.calendar_today,
                              ),
                              const Divider(),
                              _buildInfoRow(
                                context,
                                'Ngày bắt đầu',
                                DateFormatter.formatDate(hui.startDate),
                                Icons.event,
                              ),
                              if (hui.notes != null) ...[
                                const Divider(),
                                _buildInfoRow(
                                  context,
                                  'Ghi chú',
                                  hui.notes!,
                                  Icons.note,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Thống kê',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              title: 'Hoàn thành',
                              value: '${progress.toStringAsFixed(0)}%',
                              icon: Icons.pie_chart,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: 'Kỳ trễ hạn',
                              value: '${overdueContributions.length}',
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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Danh sách kỳ góp',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/reports/$huiId'),
                            child: const Text('Báo cáo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final contribution = contributions[index];
                      final calcService = ref.read(huiCalculationServiceProvider);
                      final isOverdue = calcService.isOverdue(contribution);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: contribution.isPaid
                                ? Colors.green
                                : isOverdue
                                    ? Colors.red
                                    : Colors.grey,
                            child: Icon(
                              contribution.isPaid
                                  ? Icons.check
                                  : isOverdue
                                      ? Icons.warning
                                      : Icons.schedule,
                              color: Colors.white,
                            ),
                          ),
                          title: Text('Kỳ ${contribution.periodNumber}'),
                          subtitle: Text(
                            'Hạn: ${DateFormatter.formatDate(contribution.dueDate)}',
                          ),
                          trailing: Text(
                            contribution.isPaid
                                ? CurrencyFormatter.formatCurrency(
                                    contribution.actualAmount ?? hui.contributionAmount)
                                : 'Chưa đóng',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: contribution.isPaid ? Colors.green : Colors.grey,
                            ),
                          ),
                          onTap: () => context.push('/contribution/${contribution.id}'),
                        ),
                      );
                    },
                    childCount: contributions.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Lỗi: $error')),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequencyText(FrequencyType frequency) {
    switch (frequency) {
      case FrequencyType.daily:
        return 'Hàng ngày';
      case FrequencyType.weekly:
        return 'Hàng tuần';
      case FrequencyType.monthly:
        return 'Hàng tháng';
    }
  }
}
