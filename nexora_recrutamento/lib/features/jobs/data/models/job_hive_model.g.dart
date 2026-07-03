// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JobHiveModelAdapter extends TypeAdapter<JobHiveModel> {
  @override
  final int typeId = 0;

  @override
  JobHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JobHiveModel(
      id: fields[0] as int,
      title: fields[1] as String,
      company: fields[2] as String,
      location: fields[3] as String,
      type: fields[4] as String,
      category: fields[5] as String,
      description: fields[6] as String,
      salary: fields[7] as String?,
      logoUrl: fields[8] as String,
      postedAt: fields[9] as DateTime,
      isSaved: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, JobHiveModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.company)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.salary)
      ..writeByte(8)
      ..write(obj.logoUrl)
      ..writeByte(9)
      ..write(obj.postedAt)
      ..writeByte(10)
      ..write(obj.isSaved);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
