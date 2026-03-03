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
  final members = await huiRepo.getMembersByHuiGroup(huiId);
  double totalPaid;
  double totalRemaining;
  final periodCollectedByContribution = <int, double>{};
  final progress = calcService.calculateProgress(contributions);
  final overdueContributions = contributions.where((c) => calcService.isOverdue(c)).toList();

  // For interest-based hui, get winner information
  WinnerModel? userWinnerRecord;
  List<WinnerModel> allWinners = [];
  double? profitLoss;
  double? adminFinalAmount;
  double? totalSurplus;

  if (hui.type == HuiType.interest) {
    // Get all winners for this hui
    for (final contribution in contributions) {
      if (contribution.id != null) {
        final winner = await contributionRepo.getWinnerByContribution(contribution.id!);
        if (winner != null) {
          allWinners.add(winner);
          // Check if current user won (winner name is "Bạn")
          if (winner.winnerName == 'Bạn') {
            userWinnerRecord = winner;
          }
        }
      }
    }

    // Calculate cumulative surplus for interest-based hui
    if (allWinners.isNotEmpty) {
      totalSurplus = calcService.calculateCumulativeSurplus(
        hui.contributionAmount,
        hui.numMembers,
        allWinners,
      );
    }

    // Calculate profit/loss for player
    if (hui.userRole == UserRole.player) {
      profitLoss = calcService.calculatePlayerProfitLoss(contributions, userWinnerRecord);
    }

    // Calculate final amount for admin
    if (hui.userRole == UserRole.admin && allWinners.isNotEmpty) {
      adminFinalAmount = calcService.calculateAdminFinalAmount(
        hui.contributionAmount,
        hui.numMembers,
        allWinners,
      );
    }
  }

  final memberPaymentSummary = <Map<String, dynamic>>[];
  if (hui.userRole == UserRole.admin && members.isNotEmpty) {
    final memberPaymentsByContribution = <int, List<MemberContributionModel>>{};
    for (final contribution in contributions) {
      if (contribution.id == null) continue;
      final memberPayments = await contributionRepo.getMemberContributionsByContribution(contribution.id!);
      memberPaymentsByContribution[contribution.id!] = memberPayments;

      double periodCollected = 0;
      for (final payment in memberPayments) {
        periodCollected += payment.amount;
      }
      periodCollectedByContribution[contribution.id!] = periodCollected;
    }

    totalPaid = periodCollectedByContribution.values.fold(0.0, (sum, value) => sum + value);
    final expectedTotal = hui.contributionAmount * hui.numMembers * hui.totalPeriods;
    totalRemaining = (expectedTotal - totalPaid) > 0 ? (expectedTotal - totalPaid) : 0.0;

    for (final member in members) {
      final memberId = member.id;
      if (memberId == null) continue;

      double total = 0;
      final byPeriod = <int, double>{};

      for (final contribution in contributions) {
        final contributionId = contribution.id;
        if (contributionId == null) continue;
        double amount = 0;
        final payments = memberPaymentsByContribution[contributionId] ?? [];
        for (final payment in payments) {
          if (payment.memberId == memberId) {
            amount = payment.amount;
            break;
          }
        }
        byPeriod[contribution.periodNumber] = amount;
        total += amount;
      }

      memberPaymentSummary.add({
        'member': member,
        'total': total,
        'byPeriod': byPeriod,
      });
    }
  } else {
    totalPaid = calcService.calculateTotalPaid(contributions);
    totalRemaining = calcService.calculateTotalRemaining(contributions, hui.contributionAmount);
  }

  return {
    'hui': hui,
    'contributions': contributions,
    'members': members,
    'totalPaid': totalPaid,
    'totalRemaining': totalRemaining,
    'progress': progress,
    'overdueContributions': overdueContributions,
    'userWinnerRecord': userWinnerRecord,
    'profitLoss': profitLoss,
    'adminFinalAmount': adminFinalAmount,
    'totalSurplus': totalSurplus,
    'memberPaymentSummary': memberPaymentSummary,
    'periodCollectedByContribution': periodCollectedByContribution,
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
          final profitLoss = data['profitLoss'] as double?;
          final adminFinalAmount = data['adminFinalAmount'] as double?;
          final totalSurplus = data['totalSurplus'] as double?;
          final memberPaymentSummary = data['memberPaymentSummary'] as List<Map<String, dynamic>>;
            final periodCollectedByContribution =
              Map<int, double>.from(data['periodCollectedByContribution'] as Map);
            final paidCardTitle = hui.userRole == UserRole.admin ? 'Tổng đã thu' : 'Tổng đã góp';
            final remainingCardTitle = hui.userRole == UserRole.admin ? 'Còn phải thu' : 'Còn phải góp';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(huiDetailProvider(huiId));
            },
            child: CustomScrollView(
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
                                'Vai trò của bạn',
                                hui.userRole == UserRole.admin ? 'Chủ hụi' : 'Người chơi',
                                hui.userRole == UserRole.admin ? Icons.admin_panel_settings : Icons.person,
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
                      Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              title: paidCardTitle,
                              value: CurrencyFormatter.formatCompact(totalPaid),
                              icon: Icons.payments,
                              color: Colors.green,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: remainingCardTitle,
                              value: CurrencyFormatter.formatCompact(totalRemaining),
                              icon: Icons.pending_actions,
                              color: Colors.orange,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      // Show profit/loss and cumulative surplus row for interest-based hui
                      if (hui.type == HuiType.interest) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (hui.userRole == UserRole.player && profitLoss != null)
                              Expanded(
                                child: StatsCard(
                                  title: 'Lời/Lỗ',
                                  value: '${profitLoss >= 0 ? '+' : ''}${CurrencyFormatter.formatCompact(profitLoss.abs())}',
                                  icon: profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                                  color: profitLoss >= 0 ? Colors.green : Colors.red,
                                  compact: true,
                                ),
                              ),
                            if (hui.userRole == UserRole.player && profitLoss != null)
                              const SizedBox(width: 12),
                            Expanded(
                              child: StatsCard(
                                title: 'Tổng dư tích lũy',
                                value: totalSurplus != null 
                                    ? CurrencyFormatter.formatCompact(totalSurplus)
                                    : 'Chưa có dữ liệu',
                                icon: Icons.savings,
                                color: Colors.teal,
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Show final amount for admin in interest-based hui
                      if (hui.type == HuiType.interest && hui.userRole == UserRole.admin) ...[
                        const SizedBox(height: 12),
                        StatsCard(
                          title: adminFinalAmount != null ? 'Tiền dư cuối kỳ (Dự kiến)' : 'Tiền dư cuối kỳ',
                          value: adminFinalAmount != null 
                              ? CurrencyFormatter.formatCurrency(adminFinalAmount)
                              : 'Chưa có dữ liệu',
                          icon: Icons.account_balance_wallet,
                          color: Colors.purple,
                        ),
                      ],
                      // Show admin receives 0 for fixed hui
                      if (hui.type == HuiType.fixed && hui.userRole == UserRole.admin) ...[
                        const SizedBox(height: 12),
                        StatsCard(
                          title: 'Số tiền nhận',
                          value: CurrencyFormatter.formatCurrency(0),
                          icon: Icons.account_balance_wallet,
                          color: Colors.grey,
                        ),
                      ],
                      if (hui.userRole == UserRole.admin && memberPaymentSummary.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Đóng góp theo từng người',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...memberPaymentSummary.map((item) {
                          final member = item['member'] as HuiMemberModel;
                          final total = item['total'] as double;
                          final byPeriod = item['byPeriod'] as Map<int, double>;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        member.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.formatCurrency(total),
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: byPeriod.entries
                                        .map(
                                          (entry) => Chip(
                                            label: Text(
                                              'Kỳ ${entry.key}: ${CurrencyFormatter.formatCompact(entry.value)}',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
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
                                hui.userRole == UserRole.admin
                                  ? (contribution.id != null
                                    ? (periodCollectedByContribution[contribution.id!] ?? 0.0)
                                    : 0.0)
                                  : (contribution.actualAmount ?? hui.contributionAmount))
                                : 'Chưa đóng',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: contribution.isPaid ? Colors.green : Colors.grey,
                            ),
                          ),
                          onTap: () async {
                            await context.push('/contribution/${contribution.id}');
                            ref.invalidate(huiDetailProvider(huiId));
                          },
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
            ),
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
