import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_hui_app/core/database/database.dart';
import 'package:so_hui_app/core/providers/providers.dart';
import 'package:so_hui_app/models/models.dart';
import 'package:so_hui_app/common/utils/currency_formatter.dart';
import 'package:so_hui_app/common/utils/date_formatter.dart';
import 'package:so_hui_app/common/utils/validators.dart';

final contributionDetailProvider = FutureProvider.family<Map<String, dynamic>, int>(
  (ref, contributionId) async {
    final contributionRepo = ref.watch(contributionRepositoryProvider);
    final huiRepo = ref.watch(huiRepositoryProvider);

    final contribution = await contributionRepo.getContributionById(contributionId);
    if (contribution == null) throw Exception('Contribution not found');

    final hui = await huiRepo.getHuiGroupById(contribution.huiGroupId);
    if (hui == null) throw Exception('Hui not found');

    WinnerModel? winner;
    if (hui.type == HuiType.interest) {
      winner = await contributionRepo.getWinnerByContribution(contributionId);
    }

    return {
      'contribution': contribution,
      'hui': hui,
      'winner': winner,
    };
  },
);

class ContributionDetailScreen extends ConsumerStatefulWidget {
  final int contributionId;

  const ContributionDetailScreen({super.key, required this.contributionId});

  @override
  ConsumerState<ContributionDetailScreen> createState() => _ContributionDetailScreenState();
}

class _ContributionDetailScreenState extends ConsumerState<ContributionDetailScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _winnerNameController = TextEditingController();
  final _bidAmountController = TextEditingController(); // Changed from _interestRateController
  bool _isPaid = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _winnerNameController.dispose();
    _bidAmountController.dispose();
    super.dispose();
  }

  Future<int> _getMembersAlreadyWon(int huiId, int currentPeriod) async {
    final contributionRepo = ref.read(contributionRepositoryProvider);
    final allContributions = await contributionRepo.getContributionsByHuiGroup(huiId);
    
    int count = 0;
    for (final contrib in allContributions) {
      if (contrib.periodNumber < currentPeriod && contrib.id != null) {
        final winner = await contributionRepo.getWinnerByContribution(contrib.id!);
        if (winner != null) {
          count++;
        }
      }
    }
    
    return count;
  }

  Future<void> _saveContribution(HuiGroupModel hui, ContributionModel contribution) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contributionRepo = ref.read(contributionRepositoryProvider);
      final calcService = ref.read(huiCalculationServiceProvider);

      final actualAmount = _amountController.text.trim().isEmpty
          ? hui.contributionAmount
          : double.parse(_amountController.text);

      final updatedContribution = contribution.copyWith(
        isPaid: _isPaid,
        actualAmount: actualAmount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await contributionRepo.updateContribution(updatedContribution);

      // Handle winner for auction-based hui
      if (hui.type == HuiType.interest && _isPaid) {
        if (_winnerNameController.text.trim().isNotEmpty &&
            _bidAmountController.text.trim().isNotEmpty) {
          final bidAmount = double.parse(_bidAmountController.text);
          
          // Calculate payout using correct formula: (base - bid) × (N - 1)
          // N is total members (constant)
          final amountReceived = calcService.calculateWinnerPayout(
            hui.contributionAmount,
            bidAmount,
            hui.numMembers,
          );

          final winner = WinnerModel(
            contributionId: contribution.id!,
            winnerName: _winnerNameController.text.trim(),
            bidAmount: bidAmount,
            amountReceived: amountReceived,
          );

          final existingWinner = await contributionRepo.getWinnerByContribution(contribution.id!);
          if (existingWinner != null) {
            await contributionRepo.updateWinner(winner.copyWith(id: existingWinner.id));
          } else {
            await contributionRepo.createWinner(winner);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công')),
        );
        ref.invalidate(contributionDetailProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailData = ref.watch(contributionDetailProvider(widget.contributionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết kỳ góp'),
      ),
      body: detailData.when(
        data: (data) {
          final contribution = data['contribution'] as ContributionModel;
          final hui = data['hui'] as HuiGroupModel;
          final winner = data['winner'] as WinnerModel?;

          // Initialize controllers if not yet set
          if (_amountController.text.isEmpty) {
            _amountController.text = contribution.actualAmount?.toString() ?? '';
            _notesController.text = contribution.notes ?? '';
            _isPaid = contribution.isPaid;

            if (winner != null) {
              _winnerNameController.text = winner.winnerName;
              _bidAmountController.text = winner.bidAmount.toString();
            }
          }

          final calcService = ref.read(huiCalculationServiceProvider);
          final isOverdue = calcService.isOverdue(contribution);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: contribution.isPaid
                                ? Colors.green
                                : isOverdue
                                    ? Colors.red
                                    : Colors.grey,
                            radius: 30,
                            child: Text(
                              '${contribution.periodNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kỳ ${contribution.periodNumber}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Hạn: ${DateFormatter.formatDate(contribution.dueDate)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Dây hụi: ${hui.name}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mệnh giá: ${CurrencyFormatter.formatCurrency(hui.contributionAmount)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin góp',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Đã đóng góp'),
                        value: _isPaid,
                        onChanged: (value) {
                          setState(() {
                            _isPaid = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Số tiền thực góp (VNĐ)',
                          hintText: CurrencyFormatter.formatCurrency(hui.contributionAmount),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú',
                          hintText: 'Nhập ghi chú...',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              if (hui.type == HuiType.interest) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin đấu giá (Hụi sống)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _winnerNameController,
                          decoration: const InputDecoration(
                            labelText: 'Người hốt',
                            hintText: 'Nhập tên người hốt...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bidAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Tiền bỏ (VNĐ)',
                            hintText: 'VD: 500000',
                            helperText: 'Số tiền người hốt chấp nhận bỏ ra (giảm giá)',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        if (_bidAmountController.text.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tính toán:',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                FutureBuilder<int>(
                                  future: _getMembersAlreadyWon(hui.id!, contribution.periodNumber),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const CircularProgressIndicator();
                                    }
                                    
                                    final membersAlreadyWon = snapshot.data!;
                                    final membersNotYetWonExcludingWinner = hui.numMembers - 1 - membersAlreadyWon;
                                    final calcService = ref.read(huiCalculationServiceProvider);
                                    final bidAmount = double.tryParse(_bidAmountController.text) ?? 0;
                                    final discounted = calcService.calculateDiscountedPayment(
                                      hui.contributionAmount,
                                      bidAmount,
                                    );
                                    // Payout uses constant N-1 (total members - 1)
                                    final payout = calcService.calculateWinnerPayout(
                                      hui.contributionAmount,
                                      bidAmount,
                                      hui.numMembers,
                                    );
                                    final totalCollected = calcService.calculatePeriodTotalCollected(
                                      hui.contributionAmount,
                                      bidAmount,
                                      membersAlreadyWon,
                                      membersNotYetWonExcludingWinner,
                                    );
                                    final periodSurplus = calcService.calculatePeriodSurplus(
                                      hui.contributionAmount,
                                      bidAmount,
                                      hui.numMembers,
                                      membersAlreadyWon,
                                    );

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Đã hốt trước: $membersAlreadyWon người'),
                                        Text('Chưa hốt (không tính người hốt): $membersNotYetWonExcludingWinner người'),
                                        Text('Người hốt trả: 0 (không đóng)'),
                                        const Divider(),
                                        Text('Tiền bỏ: ${CurrencyFormatter.formatCurrency(bidAmount)}'),
                                        Text('Thanh toán giảm giá: ${CurrencyFormatter.formatCurrency(discounted)}'),
                                        Text('Tổng thu kỳ này: ${CurrencyFormatter.formatCurrency(totalCollected)}'),
                                        const Divider(),
                                        Text(
                                          'Người hốt nhận = (${CurrencyFormatter.formatCurrency(hui.contributionAmount)} - ${CurrencyFormatter.formatCurrency(bidAmount)}) × ${hui.numMembers - 1}',
                                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                        ),
                                        Text(
                                          'Người hốt nhận: ${CurrencyFormatter.formatCurrency(payout)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          'Dư kỳ này: ${CurrencyFormatter.formatCurrency(periodSurplus)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : () => _saveContribution(hui, contribution),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu thay đổi'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Lỗi: $error')),
      ),
    );
  }
}
