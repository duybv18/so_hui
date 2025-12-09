import 'package:so_hui_app/core/database/database.dart';
import 'package:so_hui_app/models/models.dart';

class HuiRepository {
  final AppDatabase _database;

  HuiRepository(this._database);

  Future<List<HuiGroupModel>> getAllHuiGroups() async {
    final entities = await _database.getAllHuiGroups();
    return entities.map((e) => HuiGroupModel.fromEntity(e)).toList();
  }

  Future<HuiGroupModel?> getHuiGroupById(int id) async {
    final entity = await _database.getHuiGroupById(id);
    return entity != null ? HuiGroupModel.fromEntity(entity) : null;
  }

  Future<int> createHuiGroup(HuiGroupModel model) async {
    return await _database.createHuiGroup(model.toCompanion());
  }

  Future<bool> updateHuiGroup(HuiGroupModel model) async {
    if (model.id == null) return false;
    final entity = HuiGroup(
      id: model.id!,
      name: model.name,
      totalPeriods: model.totalPeriods,
      numMembers: model.numMembers,
      contributionAmount: model.contributionAmount,
      type: model.type,
      startDate: model.startDate,
      frequency: model.frequency,
      notes: model.notes,
      createdAt: model.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await _database.updateHuiGroup(entity);
  }

  Future<int> deleteHuiGroup(int id) async {
    return await _database.deleteHuiGroup(id);
  }
}
