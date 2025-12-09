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
  double calculateTotalForFixedHui(double contributionAmount, int numMembers) {
    return contributionAmount * numMembers;
  }

  /// Calculate amount received for interest-based hui
  double calculateAmountReceivedWithInterest(
    double totalContribution,
    double interestRate,
  ) {
    return totalContribution - (totalContribution * interestRate);
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

  /// Calculate accumulated interest for interest-based hui
  double calculateAccumulatedInterest(List<WinnerModel> winners) {
    return winners.fold(0.0, (sum, winner) {
      // Interest = total contribution - amount received
      // We need to calculate this based on contribution amount and members
      return sum;
    });
  }
}
