// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuthServiceAdapter extends TypeAdapter<AuthService> {
  @override
  final int typeId = 1;

  @override
  AuthService read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthService(
      token: fields[0] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, AuthService obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.token);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthServiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
