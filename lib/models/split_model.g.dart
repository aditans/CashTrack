// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SplitModelAdapter extends TypeAdapter<SplitModel> {
  @override
  final int typeId = 4;

  @override
  SplitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SplitModel(
      splitId: fields[0] as String,
      totalAmount: fields[1] as double,
      amountPerPerson: fields[2] as double,
      note: fields[3] as String,
      involvedFriends: (fields[4] as List).cast<String>(),
      createdBy: fields[5] as String,
      createdAt: fields[6] as DateTime,
      isPaid: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SplitModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.splitId)
      ..writeByte(1)
      ..write(obj.totalAmount)
      ..writeByte(2)
      ..write(obj.amountPerPerson)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.involvedFriends)
      ..writeByte(5)
      ..write(obj.createdBy)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isPaid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
