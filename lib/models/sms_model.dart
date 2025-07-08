import 'package:hive/hive.dart';

part 'sms_model.g.dart';

@HiveType(typeId: 0)
class SmsModel extends HiveObject {
  @HiveField(0)
  String sender;

  @HiveField(1)
  String body;

  @HiveField(2)
  DateTime receivedAt;

  @HiveField(3)
  double? amount;

  @HiveField(4)
  String? type;

  @HiveField(5)
  String? tag;

  SmsModel({
    required this.sender,
    required this.body,
    required this.receivedAt,
    this.amount,
    this.type,
    this.tag,
  });

  SmsModel copyWith({
    String? sender,
    String? body,
    DateTime? receivedAt,
    double? amount,
    String? type,
    String? tag,
  }) {
    return SmsModel(
      sender: sender ?? this.sender,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      tag: tag ?? this.tag,
    );
  }
}
