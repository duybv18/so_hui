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

    test('Calculate winner payout', () {
      final discounted = 1700000.0;
      final membersNotYetWon = 10;
      final payout = service.calculateWinnerPayout(discounted, membersNotYetWon);
      // payout = discounted × (|U| - 1) = 1,700,000 × 9 = 15,300,000
      expect(payout, 15300000);
    });

    test('Calculate period total collected', () {
      final baseContribution = 2000000.0;
      final bidAmount = 300000.0;
      final membersNotYetWon = 10;
      final membersAlreadyWon = 0;
      
      final totalCollected = service.calculatePeriodTotalCollected(
        baseContribution,
        bidAmount,
        membersNotYetWon,
        membersAlreadyWon,
      );
      // discounted = 2,000,000 - 300,000 = 1,700,000
      // total = 1,700,000 × 10 = 17,000,000
      expect(totalCollected, 17000000);
    });

    test('Calculate period surplus', () {
      final baseContribution = 2000000.0;
      final bidAmount = 300000.0;
      final membersNotYetWon = 10;
      final membersAlreadyWon = 0;
      
      final periodSurplus = service.calculatePeriodSurplus(
        baseContribution,
        bidAmount,
        membersNotYetWon,
        membersAlreadyWon,
      );
      // totalCollected = 17,000,000
      // payout = 15,300,000
      // surplus = 1,700,000
      expect(periodSurplus, 1700000);
    });

    test('Calculate cumulative surplus from multiple periods', () {
      // Simulating the example from requirements
      final baseContribution = 2000000.0;
      final totalMembers = 10;
      
      // Period 1: bid = 300k, H=0, U=10
      final winners = [
        WinnerModel(
          contributionId: 1,
          winnerName: 'A',
          bidAmount: 300000,
          amountReceived: 15300000, // This will be calculated correctly
        ),
        WinnerModel(
          contributionId: 2,
          winnerName: 'B',
          bidAmount: 200000,
          amountReceived: 14400000, // This will be calculated correctly
        ),
        WinnerModel(
          contributionId: 3,
          winnerName: 'C',
          bidAmount: 100000,
          amountReceived: 13300000, // This will be calculated correctly
        ),
      ];
      
      final cumulativeSurplus = service.calculateCumulativeSurplus(
        baseContribution,
        totalMembers,
        winners,
      );
      
      // Period 1: surplus = 1,700,000
      // Period 2: surplus = 3,800,000
      // Period 3: surplus = 5,900,000
      // Total = 1,700,000 + 3,800,000 + 5,900,000 = 11,400,000
      expect(cumulativeSurplus, 11400000);
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
