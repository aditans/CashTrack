import 'package:hive/hive.dart';
part 'group_model.g.dart';

@HiveType(typeId: 2)
class GroupModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final List<String> memberUids;
  @HiveField(3)
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.memberUids,
    required this.createdAt,
  });
}
