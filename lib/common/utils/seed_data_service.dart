import 'package:so_hui_app/core/database/database.dart';
import 'package:so_hui_app/models/models.dart';
import 'package:so_hui_app/features/hui/data/hui_repository.dart';
import 'package:so_hui_app/features/contributions/data/contribution_repository.dart';
import 'package:so_hui_app/features/hui/domain/hui_calculation_service.dart';

class SeedDataService {
  final HuiRepository huiRepo;
  final ContributionRepository contributionRepo;
  final HuiCalculationService calcService;

  SeedDataService({
    required this.huiRepo,
    required this.contributionRepo,
    required this.calcService,
  });

  Future<void> seedSampleData() async {
    // Check if data already exists
    final existingHuis = await huiRepo.getAllHuiGroups();
    if (existingHuis.isNotEmpty) {
      return; // Don't seed if data already exists
    }

    // Create sample fixed hui
    final fixedHui = HuiGroupModel(
      name: 'Hụi Tết 2024',
      totalPeriods: 12,
      numMembers: 10,
      contributionAmount: 1000000,
      type: HuiType.fixed,
      startDate: DateTime(2024, 1, 1),
      frequency: FrequencyType.monthly,
      notes: 'Hụi không lãi - góp đều hàng tháng',
    );

    final fixedHuiId = await huiRepo.createHuiGroup(fixedHui);
    final fixedHuiWithId = fixedHui.copyWith(id: fixedHuiId);

    // Generate contributions for fixed hui
    final fixedContributions = calcService.generateContributions(fixedHuiWithId);
    
    // Mark some as paid
    for (int i = 0; i < 3; i++) {
      final contribution = fixedContributions[i];
      await contributionRepo.createContribution(contribution.copyWith(
        isPaid: true,
        actualAmount: fixedHui.contributionAmount,
        notes: 'Đã đóng đầy đủ',
      ));
    }
    
    // Rest as unpaid
    for (int i = 3; i < fixedContributions.length; i++) {
      await contributionRepo.createContribution(fixedContributions[i]);
    }

    // Create sample interest-based hui
    final interestHui = HuiGroupModel(
      name: 'Hụi Kinh Doanh',
      totalPeriods: 10,
      numMembers: 8,
      contributionAmount: 2000000,
      type: HuiType.interest,
      startDate: DateTime(2024, 3, 15),
      frequency: FrequencyType.weekly,
      notes: 'Hụi có lãi - đấu giá hàng tuần',
    );

    final interestHuiId = await huiRepo.createHuiGroup(interestHui);
    final interestHuiWithId = interestHui.copyWith(id: interestHuiId);

    // Generate contributions for interest hui
    final interestContributions = calcService.generateContributions(interestHuiWithId);
    
    // Mark some as paid with winners
    for (int i = 0; i < 2; i++) {
      final contribution = interestContributions[i];
      final contributionId = await contributionRepo.createContribution(contribution.copyWith(
        isPaid: true,
        actualAmount: interestHui.contributionAmount,
        notes: 'Đã đóng và có người hốt',
      ));

      // Create winner with bid amount using correct calculation
      final bidAmount = 800000.0 - (i * 100000); // 800k, 700k
      final membersAlreadyWon = i; // Number of members who won before this period
      final membersNotYetWon = interestHui.numMembers - membersAlreadyWon;
      
      final discounted = calcService.calculateDiscountedPayment(
        interestHui.contributionAmount,
        bidAmount,
      );
      final amountReceived = calcService.calculateWinnerPayout(
        discounted,
        membersNotYetWon,
      );

      await contributionRepo.createWinner(WinnerModel(
        contributionId: contributionId,
        winnerName: 'Người ${i + 1}',
        bidAmount: bidAmount,
        amountReceived: amountReceived,
      ));
    }
    
    // Rest as unpaid
    for (int i = 2; i < interestContributions.length; i++) {
      await contributionRepo.createContribution(interestContributions[i]);
    }

    // Create another fixed hui (smaller)
    final smallHui = HuiGroupModel(
      name: 'Hụi Nhỏ Bạn Bè',
      totalPeriods: 6,
      numMembers: 6,
      contributionAmount: 500000,
      type: HuiType.fixed,
      startDate: DateTime(2024, 4, 1),
      frequency: FrequencyType.monthly,
      notes: 'Hụi nhỏ trong nhóm bạn',
    );

    final smallHuiId = await huiRepo.createHuiGroup(smallHui);
    final smallHuiWithId = smallHui.copyWith(id: smallHuiId);

    // Generate and create contributions
    final smallContributions = calcService.generateContributions(smallHuiWithId);
    for (final contribution in smallContributions) {
      await contributionRepo.createContribution(contribution);
    }
  }

  Future<void> clearAllData() async {
    final huis = await huiRepo.getAllHuiGroups();
    for (final hui in huis) {
      if (hui.id != null) {
        await huiRepo.deleteHuiGroup(hui.id!);
      }
    }
  }
}
