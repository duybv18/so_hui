import 'package:so_hui_app/core/database/database.dart';
import 'package:drift/drift.dart' as d;

class HuiGroupModel {
  final int? id;
  final String name;
  final int totalPeriods;
  final int numMembers;
  final double contributionAmount;
  final HuiType type;
  final DateTime startDate;
  final FrequencyType frequency;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HuiGroupModel({
    this.id,
    required this.name,
    required this.totalPeriods,
    required this.numMembers,
    required this.contributionAmount,
    required this.type,
    required this.startDate,
    required this.frequency,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory HuiGroupModel.fromEntity(HuiGroup entity) {
    return HuiGroupModel(
      id: entity.id,
      name: entity.name,
      totalPeriods: entity.totalPeriods,
      numMembers: entity.numMembers,
      contributionAmount: entity.contributionAmount,
      type: entity.type,
      startDate: entity.startDate,
      frequency: entity.frequency,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  HuiGroupsCompanion toCompanion() {
    return HuiGroupsCompanion.insert(
      name: name,
      totalPeriods: totalPeriods,
      numMembers: numMembers,
      contributionAmount: contributionAmount,
      type: type,
      startDate: startDate,
      frequency: frequency,
      notes: d.Value(notes),
    );
  }

  HuiGroupModel copyWith({
    int? id,
    String? name,
    int? totalPeriods,
    int? numMembers,
    double? contributionAmount,
    HuiType? type,
    DateTime? startDate,
    FrequencyType? frequency,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HuiGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      totalPeriods: totalPeriods ?? this.totalPeriods,
      numMembers: numMembers ?? this.numMembers,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      frequency: frequency ?? this.frequency,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ContributionModel {
  final int? id;
  final int huiGroupId;
  final int periodNumber;
  final DateTime dueDate;
  final bool isPaid;
  final double? actualAmount;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ContributionModel({
    this.id,
    required this.huiGroupId,
    required this.periodNumber,
    required this.dueDate,
    this.isPaid = false,
    this.actualAmount,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory ContributionModel.fromEntity(Contribution entity) {
    return ContributionModel(
      id: entity.id,
      huiGroupId: entity.huiGroupId,
      periodNumber: entity.periodNumber,
      dueDate: entity.dueDate,
      isPaid: entity.isPaid,
      actualAmount: entity.actualAmount,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ContributionsCompanion toCompanion() {
    return ContributionsCompanion.insert(
      huiGroupId: huiGroupId,
      periodNumber: periodNumber,
      dueDate: dueDate,
      isPaid: d.Value(isPaid),
      actualAmount: d.Value(actualAmount),
      notes: d.Value(notes),
    );
  }

  ContributionModel copyWith({
    int? id,
    int? huiGroupId,
    int? periodNumber,
    DateTime? dueDate,
    bool? isPaid,
    double? actualAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContributionModel(
      id: id ?? this.id,
      huiGroupId: huiGroupId ?? this.huiGroupId,
      periodNumber: periodNumber ?? this.periodNumber,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      actualAmount: actualAmount ?? this.actualAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class WinnerModel {
  final int? id;
  final int contributionId;
  final String winnerName;
  final double bidAmount; // The discount amount winner bids (tiền bỏ)
  final double amountReceived; // payout = (base - bid) × (N - 1), winner pays 0
  final DateTime? createdAt;

  WinnerModel({
    this.id,
    required this.contributionId,
    required this.winnerName,
    required this.bidAmount,
    required this.amountReceived,
    this.createdAt,
  });

  factory WinnerModel.fromEntity(HuiWinner entity) {
    return WinnerModel(
      id: entity.id,
      contributionId: entity.contributionId,
      winnerName: entity.winnerName,
      bidAmount: entity.bidAmount,
      amountReceived: entity.amountReceived,
      createdAt: entity.createdAt,
    );
  }

  HuiWinnersCompanion toCompanion() {
    return HuiWinnersCompanion.insert(
      contributionId: contributionId,
      winnerName: winnerName,
      bidAmount: bidAmount,
      amountReceived: amountReceived,
    );
  }

  WinnerModel copyWith({
    int? id,
    int? contributionId,
    String? winnerName,
    double? bidAmount,
    double? amountReceived,
    DateTime? createdAt,
  }) {
    return WinnerModel(
      id: id ?? this.id,
      contributionId: contributionId ?? this.contributionId,
      winnerName: winnerName ?? this.winnerName,
      bidAmount: bidAmount ?? this.bidAmount,
      amountReceived: amountReceived ?? this.amountReceived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
