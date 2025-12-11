import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_hui_app/core/providers/providers.dart';
import 'package:so_hui_app/models/models.dart';
import 'package:so_hui_app/common/utils/currency_formatter.dart';
import 'package:so_hui_app/common/utils/date_formatter.dart';
import 'package:so_hui_app/common/widgets/stats_card.dart';

final reportsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, huiId) async {
  final huiRepo = ref.watch(huiRepositoryProvider);
  final contributionRepo = ref.watch(contributionRepositoryProvider);
  final calcService = ref.watch(huiCalculationServiceProvider);

  final hui = await huiRepo.getHuiGroupById(huiId);
  if (hui == null) throw Exception('Hui not found');

  final contributions = await contributionRepo.getContributionsByHuiGroup(huiId);
  final overdueContributions = contributions.where((c) => calcService.isOverdue(c)).toList();
  final paidContributions = contributions.where((c) => c.isPaid).toList();
  final unpaidContributions = contributions.where((c) => !c.isPaid).toList();

  final totalPaid = calcService.calculateTotalPaid(contributions);
  final totalRemaining = calcService.calculateTotalRemaining(contributions, hui.contributionAmount);
  final progress = calcService.calculateProgress(contributions);
  final projectedEndDate = calcService.calculateProjectedEndDate(hui);

  // Cash flow by period
  final cashFlowData = <Map<String, dynamic>>[];
  for (final contribution in contributions) {
    cashFlowData.add({
      'period': contribution.periodNumber,
      'dueDate': contribution.dueDate,
      'amount': contribution.isPaid ? (contribution.actualAmount ?? hui.contributionAmount) : 0,
      'isPaid': contribution.isPaid,
    });
  }

  return {
    'hui': hui,
    'contributions': contributions,
    'overdueContributions': overdueContributions,
    'paidContributions': paidContributions,
    'unpaidContributions': unpaidContributions,
    'totalPaid': totalPaid,
    'totalRemaining': totalRemaining,
    'progress': progress,
    'projectedEndDate': projectedEndDate,
    'cashFlowData': cashFlowData,
  };
});

class ReportsScreen extends ConsumerWidget {
  final int huiId;

  const ReportsScreen({super.key, required this.huiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsData = ref.watch(reportsProvider(huiId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo'),
      ),
      body: reportsData.when(
        data: (data) {
          final hui = data['hui'] as HuiGroupModel;
          final contributions = data['contributions'] as List<ContributionModel>;
          final overdueContributions = data['overdueContributions'] as List<ContributionModel>;
          final paidContributions = data['paidContributions'] as List<ContributionModel>;
          final unpaidContributions = data['unpaidContributions'] as List<ContributionModel>;
          final totalPaid = data['totalPaid'] as double;
          final totalRemaining = data['totalRemaining'] as double;
          final progress = data['progress'] as double;
          final projectedEndDate = data['projectedEndDate'] as DateTime;
          final cashFlowData = data['cashFlowData'] as List<Map<String, dynamic>>;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(reportsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  hui.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hui.type == HuiType.fixed ? 'Hụi chết (không lãi)' : 'Hụi sống (có lãi)',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tổng quan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                StatsCard(
                  title: 'Tiến độ hoàn thành',
                  value: '${progress.toStringAsFixed(1)}%',
                  icon: Icons.pie_chart,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Tổng đã góp',
                        value: CurrencyFormatter.formatCompact(totalPaid),
                        icon: Icons.payments,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCard(
                        title: 'Còn phải góp',
                        value: CurrencyFormatter.formatCompact(totalRemaining),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Đã đóng',
                        value: '${paidContributions.length}/${contributions.length}',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCard(
                        title: 'Trễ hạn',
                        value: '${overdueContributions.length}',
                        icon: Icons.warning,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thời gian',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          'Ngày bắt đầu',
                          DateFormatter.formatDate(hui.startDate),
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          'Dự kiến kết thúc',
                          DateFormatter.formatDate(projectedEndDate),
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          'Tần suất',
                          _getFrequencyText(hui.frequency),
                        ),
                      ],
                    ),
                  ),
                ),
                if (overdueContributions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Kỳ trễ hạn',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...overdueContributions.map((contribution) {
                    final daysOverdue = DateTime.now().difference(contribution.dueDate).inDays;
                    return Card(
                      color: Colors.red.withOpacity(0.1),
                      child: ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text('Kỳ ${contribution.periodNumber}'),
                        subtitle: Text('Hạn: ${DateFormatter.formatDate(contribution.dueDate)}'),
                        trailing: Text(
                          'Trễ $daysOverdue ngày',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 24),
                Text(
                  'Dòng tiền',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(8),
                          child: _buildCashFlowChart(context, cashFlowData, hui.contributionAmount),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLegend(context, 'Đã đóng', Colors.green),
                            _buildLegend(context, 'Chưa đóng', Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Chi tiết theo kỳ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...cashFlowData.map((data) {
                  final isPaid = data['isPaid'] as bool;
                  final amount = data['amount'] as double;
                  final period = data['period'] as int;
                  final dueDate = data['dueDate'] as DateTime;

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isPaid ? Colors.green : Colors.grey,
                      ),
                      title: Text('Kỳ $period'),
                      subtitle: Text(DateFormatter.formatDate(dueDate)),
                      trailing: Text(
                        isPaid
                            ? CurrencyFormatter.formatCurrency(amount)
                            : CurrencyFormatter.formatCurrency(hui.contributionAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Lỗi: $error')),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowChart(
    BuildContext context,
    List<Map<String, dynamic>> data,
    double maxAmount,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: data.map((item) {
        final isPaid = item['isPaid'] as bool;
        final amount = item['amount'] as double;
        final height = isPaid ? (amount / maxAmount) * 150 : 0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: height > 0 ? height.toDouble() : 20,
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green : Colors.grey.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['period']}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
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
      default: 
        return 'Không xác định';
    }
  }
}
