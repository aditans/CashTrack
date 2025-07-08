import 'package:hive/hive.dart';

part 'friend_model.g.dart';

@HiveType(typeId: 1)
class FriendModel extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String displayName;

  @HiveField(2)
  String code; // extractedId

  @HiveField(3)
  DateTime addedAt;

  FriendModel({
    required this.uid,
    required this.displayName,
    required this.code,
    required this.addedAt,
  });
}
