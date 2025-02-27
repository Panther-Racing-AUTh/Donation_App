import 'package:hive/hive.dart';

part 'auth_service.g.dart';

@HiveType(typeId: 1)
class AuthService extends HiveObject {
  @HiveField(0)
  final bool? token;

  AuthService({this.token});

  static AuthService get defaultAuth => AuthService(token: null);

  factory AuthService.fromJson(Map<String, dynamic> json) {
    return AuthService(
      token: json['token'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }

  Future<void> saveToken(Box<AuthService> authBox, bool newToken) async {
    final authInstance = copyWith(token: newToken);
    await authBox.put('auth', authInstance);
  }

  static bool? getToken(Box<AuthService> authBox) {
    final authInstance = authBox.get('auth');
    return authInstance?.token;
  }

  static Future<void> clearToken(Box<AuthService> authBox) async {
    await authBox.delete('auth');
  }

  static bool isAuthenticated(Box<AuthService> authBox) {
    final authInstance = authBox.get('auth');
    return authInstance?.token != null;
  }

  Future<void> setNewToken(Box<AuthService> authBox, bool newToken) async {
    final updatedAuth = copyWith(token: newToken);
    await authBox.put('auth', updatedAuth);
  }

  AuthService copyWith({bool? token}) {
    return AuthService(
      token: token ?? this.token,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthService && other.token == token;
  }

  @override
  int get hashCode => token.hashCode;

  @override
  String toString() {
    return 'AuthService(token: $token)';
  }
}
