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
      bidAmount: model.bidAmount,
      // interestRate: model.interestRate,
      amountReceived: model.amountReceived,
      createdAt: model.createdAt ?? DateTime.now(),
    );
    return await _database.updateWinner(entity);
  }

  Future<List<MemberContributionModel>> getMemberContributionsByContribution(int contributionId) async {
    final entities = await _database.getMemberContributionsByContribution(contributionId);
    return entities.map((e) => MemberContributionModel.fromEntity(e)).toList();
  }

  Future<MemberContributionModel?> getMemberContribution(int contributionId, int memberId) async {
    final entity = await _database.getMemberContribution(contributionId, memberId);
    return entity != null ? MemberContributionModel.fromEntity(entity) : null;
  }

  Future<int> createMemberContribution(MemberContributionModel model) async {
    return await _database.createMemberContribution(model.toCompanion());
  }

  Future<bool> updateMemberContribution(MemberContributionModel model) async {
    if (model.id == null) return false;
    final entity = MemberContribution(
      id: model.id!,
      contributionId: model.contributionId,
      memberId: model.memberId,
      amount: model.amount,
      paidAt: model.paidAt,
      createdAt: model.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await _database.updateMemberContribution(entity);
  }

  Future<int> upsertMemberContribution(MemberContributionModel model) async {
    final existing = await getMemberContribution(model.contributionId, model.memberId);
    if (existing != null) {
      await updateMemberContribution(
        model.copyWith(
          id: existing.id,
          createdAt: existing.createdAt,
        ),
      );
      return existing.id!;
    }
    return await createMemberContribution(model);
  }

  Future<int> deleteMemberContributionsByContribution(int contributionId) async {
    return await _database.deleteMemberContributionsByContribution(contributionId);
  }
}
