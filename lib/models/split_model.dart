import 'package:hive/hive.dart';

part 'split_model.g.dart';

@HiveType(typeId: 4)
class SplitModel {
  @HiveField(0)
  final String splitId;

  @HiveField(1)
  final double totalAmount;

  @HiveField(2)
  final double amountPerPerson;

  @HiveField(3)
  final String note;

  @HiveField(4)
  final List<String> involvedFriends;

  @HiveField(5)
  final String createdBy;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final bool isPaid;

  SplitModel({
    required this.splitId,
    required this.totalAmount,
    required this.amountPerPerson,
    required this.note,
    required this.involvedFriends,
    required this.createdBy,
    required this.createdAt,
    this.isPaid = false,
  });
}
