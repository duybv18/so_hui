import 'package:so_hui_app/core/database/database.dart';
import 'package:so_hui_app/models/models.dart';

class HuiCalculationService {
  /// Calculate the next due date based on frequency
  DateTime calculateNextDueDate(DateTime startDate, FrequencyType frequency, int periodNumber) {
    switch (frequency) {
      case FrequencyType.daily:
        return startDate.add(Duration(days: periodNumber));
      case FrequencyType.weekly:
        return startDate.add(Duration(days: periodNumber * 7));
      case FrequencyType.monthly:
        return DateTime(
          startDate.year,
          startDate.month + periodNumber,
          startDate.day,
        );
    }
  }

  /// Generate all contribution periods for a hui group
  List<ContributionModel> generateContributions(HuiGroupModel huiGroup) {
    final List<ContributionModel> contributions = [];
    
    for (int i = 1; i <= huiGroup.totalPeriods; i++) {
      final dueDate = calculateNextDueDate(huiGroup.startDate, huiGroup.frequency, i - 1);
      
      contributions.add(ContributionModel(
        huiGroupId: huiGroup.id!,
        periodNumber: i,
        dueDate: dueDate,
        isPaid: false,
        actualAmount: null,
        notes: null,
      ));
    }
    
    return contributions;
  }

  /// Calculate total amount for fixed-type hui
  double calculateTotalContribution(double contributionAmount, int numMembers) {
    return contributionAmount * numMembers;
  }

  /// Calculate discounted payment for members who haven't won yet (non-winners)
  /// discounted = baseContribution - bidAmount
  double calculateDiscountedPayment(
    double baseContribution,
    double bidAmount,
  ) {
    return baseContribution - bidAmount;
  }

  /// Calculate payout for winner in auction-based hui
  /// IMPORTANT: payout = (base - bid) × (N - 1)
  /// where N is TOTAL members (constant), NOT variable
  /// Winner pays 0 in their winning period
  double calculateWinnerPayout(
    double baseContribution,
    double bidAmount,
    int totalMembers,
  ) {
    final discounted = calculateDiscountedPayment(baseContribution, bidAmount);
    return discounted * (totalMembers - 1);
  }

  /// Calculate total collected in a period for auction-based hui
  /// Winner pays 0
  /// totalCollected = full × |H| + discounted × (|U| - 1)
  /// where H = members who already won, U = members not yet won (excluding current winner)
  double calculatePeriodTotalCollected(
    double baseContribution,
    double bidAmount,
    int membersAlreadyWon,
    int membersNotYetWonExcludingWinner,
  ) {
    final discounted = calculateDiscountedPayment(baseContribution, bidAmount);
    final fullPayments = baseContribution * membersAlreadyWon;
    final discountedPayments = discounted * membersNotYetWonExcludingWinner;
    return fullPayments + discountedPayments;
  }

  /// Calculate surplus for a single period
  /// periodSurplus = totalCollected - payout
  double calculatePeriodSurplus(
    double baseContribution,
    double bidAmount,
    int totalMembers,
    int membersAlreadyWon,
  ) {
    // Winner pays 0, so non-winner contributors = totalMembers - 1
    // Of those, membersAlreadyWon pay full, rest pay discounted
    final membersNotYetWonExcludingWinner = totalMembers - 1 - membersAlreadyWon;
    
    final totalCollected = calculatePeriodTotalCollected(
      baseContribution,
      bidAmount,
      membersAlreadyWon,
      membersNotYetWonExcludingWinner,
    );
    
    final payout = calculateWinnerPayout(
      baseContribution,
      bidAmount,
      totalMembers,
    );
    
    return totalCollected - payout;
  }

  /// Calculate cumulative surplus across all periods
  /// This requires knowing the bid amount and winner count for each period
  double calculateCumulativeSurplus(
    double baseContribution,
    int totalMembers,
    List<WinnerModel> winners,
  ) {
    double cumulativeSurplus = 0.0;
    
    for (int i = 0; i < winners.length; i++) {
      final winner = winners[i];
      final membersAlreadyWon = i; // Members who won in previous periods
      
      final periodSurplus = calculatePeriodSurplus(
        baseContribution,
        winner.bidAmount,
        totalMembers,
        membersAlreadyWon,
      );
      
      cumulativeSurplus += periodSurplus;
    }
    
    return cumulativeSurplus;
  }

  /// Calculate total paid by user so far
  double calculateTotalPaid(List<ContributionModel> contributions) {
    return contributions
        .where((c) => c.isPaid)
        .fold(0.0, (sum, c) => sum + (c.actualAmount ?? 0.0));
  }

  /// Calculate total remaining to pay
  double calculateTotalRemaining(
    List<ContributionModel> contributions,
    double contributionAmount,
  ) {
    final unpaidContributions = contributions.where((c) => !c.isPaid).length;
    return unpaidContributions * contributionAmount;
  }

  /// Check if contribution is overdue
  bool isOverdue(ContributionModel contribution) {
    return !contribution.isPaid && contribution.dueDate.isBefore(DateTime.now());
  }

  /// Calculate projected end date
  DateTime calculateProjectedEndDate(HuiGroupModel huiGroup) {
    return calculateNextDueDate(
      huiGroup.startDate,
      huiGroup.frequency,
      huiGroup.totalPeriods - 1,
    );
  }

  /// Calculate progress percentage
  double calculateProgress(List<ContributionModel> contributions) {
    if (contributions.isEmpty) return 0.0;
    final paidCount = contributions.where((c) => c.isPaid).length;
    return (paidCount / contributions.length) * 100;
  }
}
