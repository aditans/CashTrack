import 'package:hive/hive.dart';

part 'individual_chat_model.g.dart';

@HiveType(typeId: 3)
class IndividualChatModel {
  @HiveField(0)
  final String chatId;

  @HiveField(1)
  final String friendUid;

  @HiveField(2)
  final String friendName;

  @HiveField(3)
  final DateTime lastMessageTime;

  @HiveField(4)
  final String lastMessage;

  IndividualChatModel({
    required this.chatId,
    required this.friendUid,
    required this.friendName,
    required this.lastMessageTime,
    required this.lastMessage,
  });
}
