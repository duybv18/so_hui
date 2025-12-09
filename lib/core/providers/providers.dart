import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_hui_app/core/database/database.dart';
import 'package:so_hui_app/features/hui/data/hui_repository.dart';
import 'package:so_hui_app/features/contributions/data/contribution_repository.dart';
import 'package:so_hui_app/features/hui/domain/hui_calculation_service.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Repository providers
final huiRepositoryProvider = Provider<HuiRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return HuiRepository(database);
});

final contributionRepositoryProvider = Provider<ContributionRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ContributionRepository(database);
});

// Service providers
final huiCalculationServiceProvider = Provider<HuiCalculationService>((ref) {
  return HuiCalculationService();
});
