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
  final _interestRateController = TextEditingController();
  bool _isPaid = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _winnerNameController.dispose();
    _interestRateController.dispose();
    super.dispose();
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

      // Handle winner for interest-based hui
      if (hui.type == HuiType.interest && _isPaid) {
        if (_winnerNameController.text.trim().isNotEmpty &&
            _interestRateController.text.trim().isNotEmpty) {
          final interestRate = double.parse(_interestRateController.text) / 100;
          final totalContribution = calcService.calculateTotalForFixedHui(
            hui.contributionAmount,
            hui.numMembers,
          );
          final amountReceived = calcService.calculateAmountReceivedWithInterest(
            totalContribution,
            interestRate,
          );

          final winner = WinnerModel(
            contributionId: contribution.id!,
            winnerName: _winnerNameController.text.trim(),
            interestRate: interestRate,
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
              _interestRateController.text = (winner.interestRate * 100).toString();
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
                          'Thông tin hốt (Hụi sống)',
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
                          controller: _interestRateController,
                          decoration: const InputDecoration(
                            labelText: 'Lãi suất (%)',
                            hintText: 'VD: 5',
                            suffixText: '%',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                        if (_interestRateController.text.isNotEmpty) ...[
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
                                Builder(
                                  builder: (context) {
                                    final calcService = ref.read(huiCalculationServiceProvider);
                                    final totalContribution = calcService.calculateTotalForFixedHui(
                                      hui.contributionAmount,
                                      hui.numMembers,
                                    );
                                    final interestRate = double.tryParse(_interestRateController.text) ?? 0;
                                    final amountReceived = calcService.calculateAmountReceivedWithInterest(
                                      totalContribution,
                                      interestRate / 100,
                                    );
                                    final interestAmount = totalContribution - amountReceived;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Tổng góp: ${CurrencyFormatter.formatCurrency(totalContribution)}'),
                                        Text('Tiền lãi: ${CurrencyFormatter.formatCurrency(interestAmount)}'),
                                        Text(
                                          'Người hốt nhận: ${CurrencyFormatter.formatCurrency(amountReceived)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
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
