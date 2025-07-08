// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'individual_chat_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IndividualChatModelAdapter extends TypeAdapter<IndividualChatModel> {
  @override
  final int typeId = 3;

  @override
  IndividualChatModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IndividualChatModel(
      chatId: fields[0] as String,
      friendUid: fields[1] as String,
      friendName: fields[2] as String,
      lastMessageTime: fields[3] as DateTime,
      lastMessage: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, IndividualChatModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.chatId)
      ..writeByte(1)
      ..write(obj.friendUid)
      ..writeByte(2)
      ..write(obj.friendName)
      ..writeByte(3)
      ..write(obj.lastMessageTime)
      ..writeByte(4)
      ..write(obj.lastMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndividualChatModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
