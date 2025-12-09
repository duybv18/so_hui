import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Hui Group Types
enum HuiType {
  fixed, // Hụi chết - no interest
  interest, // Hụi sống - with interest/auction
}

// Frequency Types
enum FrequencyType {
  daily,
  weekly,
  monthly,
}

// Table: Hui Groups
class HuiGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get totalPeriods => integer()();
  IntColumn get numMembers => integer()();
  RealColumn get contributionAmount => real()();
  IntColumn get type => intEnum<HuiType>()();
  DateTimeColumn get startDate => dateTime()();
  IntColumn get frequency => intEnum<FrequencyType>()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Table: Contributions (Periods)
class Contributions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get huiGroupId => integer().references(HuiGroups, #id, onDelete: KeyAction.cascade)();
  IntColumn get periodNumber => integer()();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  RealColumn get actualAmount => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Table: Hui Winners (for auction-based hui)
class HuiWinners extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contributionId => integer().references(Contributions, #id, onDelete: KeyAction.cascade)();
  TextColumn get winnerName => text().withLength(min: 1, max: 100)();
  RealColumn get bidAmount => real()(); // The discount amount winner bids (tiền bỏ)
  RealColumn get amountReceived => real()(); // totalContribution - bidAmount
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [HuiGroups, Contributions, HuiWinners])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Handle future migrations here
    },
  );

  // Hui Groups queries
  Future<List<HuiGroup>> getAllHuiGroups() => select(huiGroups).get();
  
  Future<HuiGroup?> getHuiGroupById(int id) => 
    (select(huiGroups)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  
  Future<int> createHuiGroup(HuiGroupsCompanion entry) => 
    into(huiGroups).insert(entry);
  
  Future<bool> updateHuiGroup(HuiGroup entry) => 
    update(huiGroups).replace(entry);
  
  Future<int> deleteHuiGroup(int id) => 
    (delete(huiGroups)..where((tbl) => tbl.id.equals(id))).go();

  // Contributions queries
  Future<List<Contribution>> getContributionsByHuiGroup(int huiGroupId) => 
    (select(contributions)..where((tbl) => tbl.huiGroupId.equals(huiGroupId))
    ..orderBy([(tbl) => OrderingTerm(expression: tbl.periodNumber)])).get();
  
  Future<Contribution?> getContributionById(int id) => 
    (select(contributions)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  
  Future<int> createContribution(ContributionsCompanion entry) => 
    into(contributions).insert(entry);
  
  Future<bool> updateContribution(Contribution entry) => 
    update(contributions).replace(entry);
  
  Future<int> deleteContribution(int id) => 
    (delete(contributions)..where((tbl) => tbl.id.equals(id))).go();
  
  Future<List<Contribution>> getOverdueContributions(int huiGroupId) =>
    (select(contributions)
      ..where((tbl) => 
        tbl.huiGroupId.equals(huiGroupId) & 
        tbl.isPaid.equals(false) &
        tbl.dueDate.isSmallerThanValue(DateTime.now()))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.dueDate)])).get();

  // Hui Winners queries
  Future<List<HuiWinner>> getWinnersByHuiGroup(int huiGroupId) async {
    final query = select(huiWinners).join([
      innerJoin(
        contributions,
        contributions.id.equalsExp(huiWinners.contributionId),
      ),
    ])..where(contributions.huiGroupId.equals(huiGroupId));
    
    final results = await query.get();
    return results.map((row) => row.readTable(huiWinners)).toList();
  }
  
  Future<HuiWinner?> getWinnerByContribution(int contributionId) => 
    (select(huiWinners)..where((tbl) => tbl.contributionId.equals(contributionId))).getSingleOrNull();
  
  Future<int> createWinner(HuiWinnersCompanion entry) => 
    into(huiWinners).insert(entry);
  
  Future<bool> updateWinner(HuiWinner entry) => 
    update(huiWinners).replace(entry);
  
  Future<int> deleteWinner(int id) => 
    (delete(huiWinners)..where((tbl) => tbl.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'so_hui.sqlite'));
    return NativeDatabase(file);
  });
}
