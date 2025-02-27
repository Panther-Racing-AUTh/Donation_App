// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 0;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      theme: fields[0] as String,
      language: fields[1] as String,
      notificationsEnabled: fields[2] as bool,
      fontSize: fields[3] as double,
      privacyMode: fields[4] as bool,
      accentColor: fields[5] as int,
      notificationSound: fields[6] as String,
      layoutMode: fields[7] as String,
      currency: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.theme)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.notificationsEnabled)
      ..writeByte(3)
      ..write(obj.fontSize)
      ..writeByte(4)
      ..write(obj.privacyMode)
      ..writeByte(5)
      ..write(obj.accentColor)
      ..writeByte(6)
      ..write(obj.notificationSound)
      ..writeByte(7)
      ..write(obj.layoutMode)
      ..writeByte(8)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
