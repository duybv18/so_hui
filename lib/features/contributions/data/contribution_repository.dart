import 'package:so_hui_app/core/database/database.dart';
import 'package:so_hui_app/models/models.dart';

class ContributionRepository {
  final AppDatabase _database;

  ContributionRepository(this._database);

  Future<List<ContributionModel>> getContributionsByHuiGroup(int huiGroupId) async {
    final entities = await _database.getContributionsByHuiGroup(huiGroupId);
    return entities.map((e) => ContributionModel.fromEntity(e)).toList();
  }

  Future<ContributionModel?> getContributionById(int id) async {
    final entity = await _database.getContributionById(id);
    return entity != null ? ContributionModel.fromEntity(entity) : null;
  }

  Future<int> createContribution(ContributionModel model) async {
    return await _database.createContribution(model.toCompanion());
  }

  Future<bool> updateContribution(ContributionModel model) async {
    if (model.id == null) return false;
    final entity = Contribution(
      id: model.id!,
      huiGroupId: model.huiGroupId,
      periodNumber: model.periodNumber,
      dueDate: model.dueDate,
      isPaid: model.isPaid,
      actualAmount: model.actualAmount,
      notes: model.notes,
      createdAt: model.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await _database.updateContribution(entity);
  }

  Future<int> deleteContribution(int id) async {
    return await _database.deleteContribution(id);
  }

  Future<List<ContributionModel>> getOverdueContributions(int huiGroupId) async {
    final entities = await _database.getOverdueContributions(huiGroupId);
    return entities.map((e) => ContributionModel.fromEntity(e)).toList();
  }

  Future<WinnerModel?> getWinnerByContribution(int contributionId) async {
    final entity = await _database.getWinnerByContribution(contributionId);
    return entity != null ? WinnerModel.fromEntity(entity) : null;
  }

  Future<int> createWinner(WinnerModel model) async {
    return await _database.createWinner(model.toCompanion());
  }

  Future<bool> updateWinner(WinnerModel model) async {
    if (model.id == null) return false;
    final entity = HuiWinner(
      id: model.id!,
      contributionId: model.contributionId,
      winnerName: model.winnerName,
      interestRate: model.interestRate,
      amountReceived: model.amountReceived,
      createdAt: model.createdAt ?? DateTime.now(),
    );
    return await _database.updateWinner(entity);
  }
}
