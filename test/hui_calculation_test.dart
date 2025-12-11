import 'package:flutter_test/flutter_test.dart';
import 'package:so_hui_app/core/database/database.dart';
import 'package:so_hui_app/features/hui/domain/hui_calculation_service.dart';
import 'package:so_hui_app/models/models.dart';

void main() {
  group('HuiCalculationService Tests', () {
    late HuiCalculationService service;

    setUp(() {
      service = HuiCalculationService();
    });

    test('Calculate next due date for daily frequency', () {
      final startDate = DateTime(2024, 1, 1);
      final nextDate = service.calculateNextDueDate(startDate, FrequencyType.daily, 1);
      expect(nextDate, DateTime(2024, 1, 2));
    });

    test('Calculate next due date for weekly frequency', () {
      final startDate = DateTime(2024, 1, 1);
      final nextDate = service.calculateNextDueDate(startDate, FrequencyType.weekly, 1);
      expect(nextDate, DateTime(2024, 1, 8));
    });

    test('Calculate next due date for monthly frequency', () {
      final startDate = DateTime(2024, 1, 1);
      final nextDate = service.calculateNextDueDate(startDate, FrequencyType.monthly, 1);
      expect(nextDate, DateTime(2024, 2, 1));
    });

    test('Calculate total for fixed hui', () {
      final total = service.calculateTotalForFixedHui(1000000, 10);
      expect(total, 10000000);
    });

    test('Calculate discounted payment', () {
      final baseContribution = 2000000.0;
      final bidAmount = 300000.0;
      final discounted = service.calculateDiscountedPayment(baseContribution, bidAmount);
      expect(discounted, 1700000);
    });

    test('Calculate winner payout - CONSTANT N-1 multiplier', () {
      // IMPORTANT: Payout = (base - bid) × (N - 1)
      // N is total members (constant), NOT variable
      final baseContribution = 2000000.0;
      final bidAmount = 300000.0;
      final totalMembers = 10;
      
      final payout = service.calculateWinnerPayout(
        baseContribution,
        bidAmount,
        totalMembers,
      );
      
      // payout = (2,000,000 - 300,000) × (10 - 1) = 1,700,000 × 9 = 15,300,000
      expect(payout, 15300000);
    });

    test('Period 1: bid=300k, H=0, surplus=0', () {
      // N = 10, base = 2,000,000
      // Winner A pays 0
      // 9 others pay discounted = 1,700,000
      final baseContribution = 2000000.0;
      final bidAmount = 300000.0;
      final totalMembers = 10;
      final membersAlreadyWon = 0;
      final membersNotYetWonExcludingWinner = 9;
      
      final payout = service.calculateWinnerPayout(
        baseContribution,
        bidAmount,
        totalMembers,
      );
      expect(payout, 15300000); // 1,700,000 × 9
      
      final totalCollected = service.calculatePeriodTotalCollected(
        baseContribution,
        bidAmount,
        membersAlreadyWon,
        membersNotYetWonExcludingWinner,
      );
      expect(totalCollected, 15300000); // 9 × 1,700,000
      
      final periodSurplus = service.calculatePeriodSurplus(
        baseContribution,
        bidAmount,
        totalMembers,
        membersAlreadyWon,
      );
      expect(periodSurplus, 0); // 15,300,000 - 15,300,000
    });

    test('Period 2: bid=200k, H=1 (A), surplus=200k', () {
      // Winner B pays 0
      // A (already won) pays 2,000,000
      // 8 others pay discounted = 1,800,000
      final baseContribution = 2000000.0;
      final bidAmount = 200000.0;
      final totalMembers = 10;
      final membersAlreadyWon = 1;
      final membersNotYetWonExcludingWinner = 8;
      
      final payout = service.calculateWinnerPayout(
        baseContribution,
        bidAmount,
        totalMembers,
      );
      expect(payout, 16200000); // 1,800,000 × 9
      
      final totalCollected = service.calculatePeriodTotalCollected(
        baseContribution,
        bidAmount,
        membersAlreadyWon,
        membersNotYetWonExcludingWinner,
      );
      // A pays 2,000,000 + 8 × 1,800,000 = 2,000,000 + 14,400,000 = 16,400,000
      expect(totalCollected, 16400000);
      
      final periodSurplus = service.calculatePeriodSurplus(
        baseContribution,
        bidAmount,
        totalMembers,
        membersAlreadyWon,
      );
      expect(periodSurplus, 200000); // 16,400,000 - 16,200,000
    });

    test('Period 3: bid=100k, H=2 (A,B), surplus=200k', () {
      // Winner C pays 0
      // A, B (already won) pay 2,000,000 each
      // 7 others pay discounted = 1,900,000
      final baseContribution = 2000000.0;
      final bidAmount = 100000.0;
      final totalMembers = 10;
      final membersAlreadyWon = 2;
      final membersNotYetWonExcludingWinner = 7;
      
      final payout = service.calculateWinnerPayout(
        baseContribution,
        bidAmount,
        totalMembers,
      );
      expect(payout, 17100000); // 1,900,000 × 9
      
      final totalCollected = service.calculatePeriodTotalCollected(
        baseContribution,
        bidAmount,
        membersAlreadyWon,
        membersNotYetWonExcludingWinner,
      );
      // 2 × 2,000,000 + 7 × 1,900,000 = 4,000,000 + 13,300,000 = 17,300,000
      expect(totalCollected, 17300000);
      
      final periodSurplus = service.calculatePeriodSurplus(
        baseContribution,
        bidAmount,
        totalMembers,
        membersAlreadyWon,
      );
      expect(periodSurplus, 200000); // 17,300,000 - 17,100,000
    });

    test('Cumulative surplus after 3 periods = 400k', () {
      // N = 10, base = 2,000,000
      final baseContribution = 2000000.0;
      final totalMembers = 10;
      
      final winners = [
        WinnerModel(
          contributionId: 1,
          winnerName: 'A',
          bidAmount: 300000,
          amountReceived: 15300000,
        ),
        WinnerModel(
          contributionId: 2,
          winnerName: 'B',
          bidAmount: 200000,
          amountReceived: 16200000,
        ),
        WinnerModel(
          contributionId: 3,
          winnerName: 'C',
          bidAmount: 100000,
          amountReceived: 17100000,
        ),
      ];
      
      final cumulativeSurplus = service.calculateCumulativeSurplus(
        baseContribution,
        totalMembers,
        winners,
      );
      
      // Period 1: surplus = 0
      // Period 2: surplus = 200,000
      // Period 3: surplus = 200,000
      // Total = 400,000
      expect(cumulativeSurplus, 400000);
    });

    test('Calculate total paid', () {
      final contributions = [
        ContributionModel(
          huiGroupId: 1,
          periodNumber: 1,
          dueDate: DateTime(2024, 1, 1),
          isPaid: true,
          actualAmount: 1000000,
        ),
        ContributionModel(
          huiGroupId: 1,
          periodNumber: 2,
          dueDate: DateTime(2024, 2, 1),
          isPaid: true,
          actualAmount: 1000000,
        ),
        ContributionModel(
          huiGroupId: 1,
          periodNumber: 3,
          dueDate: DateTime(2024, 3, 1),
          isPaid: false,
        ),
      ];

      final totalPaid = service.calculateTotalPaid(contributions);
      expect(totalPaid, 2000000);
    });

    test('Calculate total remaining', () {
      final contributions = [
        ContributionModel(
          huiGroupId: 1,
          periodNumber: 1,
          dueDate: DateTime(2024, 1, 1),
          isPaid: true,
          actualAmount: 1000000,
        ),
        ContributionModel(
          huiGroupId: 1,
          periodNumber: 2,
          dueDate: DateTime(2024, 2, 1),
          isPaid: false,
        ),
        ContributionModel(
          huiGroupId: 1,
          periodNumber: 3,
          dueDate: DateTime(2024, 3, 1),
          isPaid: false,
        ),
      ];

      final totalRemaining = service.calculateTotalRemaining(contributions, 1000000);
      expect(totalRemaining, 2000000);
    });

    test('Check if contribution is overdue', () {
      final overdueContribution = ContributionModel(
        huiGroupId: 1,
        periodNumber: 1,
        dueDate: DateTime(2020, 1, 1),
        isPaid: false,
      );

      final notOverdueContribution = ContributionModel(
        huiGroupId: 1,
        periodNumber: 2,
        dueDate: DateTime(2025, 1, 1),
        isPaid: false,
      );

      expect(service.isOverdue(overdueContribution), true);
      expect(service.isOverdue(notOverdueContribution), false);
    });

    test('Calculate progress', () {
      final contributions = [
        ContributionModel(
          huiGroupId: 1,
          periodNumber: 1,
          dueDate: DateTime(2024, 1, 1),
          isPaid: true,
        ),
        ContributionModel(
          huiGroupId: 1,
          periodNumber: 2,
          dueDate: DateTime(2024, 2, 1),
          isPaid: true,
        ),
        ContributionModel(
          huiGroupId: 1,
          periodNumber: 3,
          dueDate: DateTime(2024, 3, 1),
          isPaid: false,
        ),
        ContributionModel(
          huiGroupId: 1,
          periodNumber: 4,
          dueDate: DateTime(2024, 4, 1),
          isPaid: false,
        ),
      ];

      final progress = service.calculateProgress(contributions);
      expect(progress, 50.0);
    });

    test('Generate contributions for hui group', () {
      final huiGroup = HuiGroupModel(
        id: 1,
        name: 'Test Hui',
        totalPeriods: 3,
        numMembers: 10,
        contributionAmount: 1000000,
        type: HuiType.fixed,
        startDate: DateTime(2024, 1, 1),
        frequency: FrequencyType.monthly,
      );

      final contributions = service.generateContributions(huiGroup);
      expect(contributions.length, 3);
      expect(contributions[0].periodNumber, 1);
      expect(contributions[0].dueDate, DateTime(2024, 1, 1));
      expect(contributions[1].periodNumber, 2);
      expect(contributions[1].dueDate, DateTime(2024, 2, 1));
      expect(contributions[2].periodNumber, 3);
      expect(contributions[2].dueDate, DateTime(2024, 3, 1));
    });
  });

  group('Model Tests', () {
    test('HuiGroupModel copyWith', () {
      final original = HuiGroupModel(
        id: 1,
        name: 'Test',
        totalPeriods: 12,
        numMembers: 10,
        contributionAmount: 1000000,
        type: HuiType.fixed,
        startDate: DateTime(2024, 1, 1),
        frequency: FrequencyType.monthly,
      );

      final updated = original.copyWith(name: 'Updated');
      expect(updated.name, 'Updated');
      expect(updated.totalPeriods, 12);
    });

    test('ContributionModel copyWith', () {
      final original = ContributionModel(
        id: 1,
        huiGroupId: 1,
        periodNumber: 1,
        dueDate: DateTime(2024, 1, 1),
        isPaid: false,
      );

      final updated = original.copyWith(isPaid: true, actualAmount: 1000000);
      expect(updated.isPaid, true);
      expect(updated.actualAmount, 1000000);
      expect(updated.periodNumber, 1);
    });
  });
}
