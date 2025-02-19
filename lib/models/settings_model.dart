class Settings {
  final String theme; // e.g., 'light' or 'dark'
  final String language; // e.g., 'en', 'el'
  final bool notificationsEnabled;

  Settings({
    required this.theme,
    required this.language,
    required this.notificationsEnabled,
  });

  /// Creates a Settings instance from a JSON object.
  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      theme: json['theme'] as String,
      language: json['language'] as String,
      notificationsEnabled: json['notifications_enabled'] as bool,
    );
  }

  /// Converts the Settings instance into a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'notifications_enabled': notificationsEnabled,
    };
  }

  /// Creates a copy of this Settings with updated fields.
  Settings copyWith({
    String? theme,
    String? language,
    bool? notificationsEnabled,
  }) {
    return Settings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
