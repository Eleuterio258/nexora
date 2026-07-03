// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApplicationHiveModelAdapter extends TypeAdapter<ApplicationHiveModel> {
  @override
  final int typeId = 1;

  @override
  ApplicationHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApplicationHiveModel(
      id: fields[0] as int,
      jobId: fields[1] as int,
      jobTitle: fields[2] as String,
      company: fields[3] as String,
      location: fields[4] as String,
      appliedAt: fields[5] as DateTime,
      status: fields[6] as String,
      logoUrl: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ApplicationHiveModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.jobId)
      ..writeByte(2)
      ..write(obj.jobTitle)
      ..writeByte(3)
      ..write(obj.company)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.appliedAt)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.logoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
