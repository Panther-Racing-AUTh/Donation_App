import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 0)
class Settings extends HiveObject {
  /// The current theme mode: for example, 'light' or 'dark'.
  @HiveField(0)
  final String theme;

  /// The current language code: for example, 'en' or 'el'.
  @HiveField(1)
  final String language;

  /// Whether notifications are enabled.
  @HiveField(2)
  final bool notificationsEnabled;

  /// The base font size used in the app.
  @HiveField(3)
  final double fontSize;

  /// Whether privacy mode is enabled (could hide sensitive info).
  @HiveField(4)
  final bool privacyMode;

  /// Accent color stored as an ARGB integer.
  @HiveField(5)
  final int accentColor;

  /// Preferred notification sound identifier.
  @HiveField(6)
  final String notificationSound;

  /// A layout mode value (e.g., 'compact', 'comfortable').
  @HiveField(7)
  final String layoutMode;

  /// The currently selected currency (e.g., 'USD', 'EUR').
  @HiveField(8)
  final String currency;

  Settings({
    required this.theme,
    required this.language,
    required this.notificationsEnabled,
    required this.fontSize,
    required this.privacyMode,
    required this.accentColor,
    required this.notificationSound,
    required this.layoutMode,
    required this.currency,
  });

  /// A static default settings instance for the app.
  static Settings get defaultSettings => Settings(
    theme: 'light',
    language: 'en',
    notificationsEnabled: true,
    fontSize: 14.0,
    privacyMode: false,
    accentColor: Colors.teal.value,
    notificationSound: 'default',
    layoutMode: 'comfortable',
    currency: 'USD',
  );

  /// Creates a [Settings] instance from a JSON object.
  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      theme: json['theme'] as String? ?? defaultSettings.theme,
      language: json['language'] as String? ?? defaultSettings.language,
      notificationsEnabled:
      json['notifications_enabled'] as bool? ?? defaultSettings.notificationsEnabled,
      fontSize: (json['font_size'] as num?)?.toDouble() ?? defaultSettings.fontSize,
      privacyMode: json['privacy_mode'] as bool? ?? defaultSettings.privacyMode,
      accentColor: json['accent_color'] as int? ?? defaultSettings.accentColor,
      notificationSound:
      json['notification_sound'] as String? ?? defaultSettings.notificationSound,
      layoutMode: json['layout_mode'] as String? ?? defaultSettings.layoutMode,
      currency: json['currency'] as String? ?? defaultSettings.currency,
    );
  }

  /// Converts the [Settings] instance into a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'notifications_enabled': notificationsEnabled,
      'font_size': fontSize,
      'privacy_mode': privacyMode,
      'accent_color': accentColor,
      'notification_sound': notificationSound,
      'layout_mode': layoutMode,
      'currency': currency,
    };
  }

  /// Creates a copy of this [Settings] with updated fields.
  Settings copyWith({
    String? theme,
    String? language,
    bool? notificationsEnabled,
    double? fontSize,
    bool? privacyMode,
    int? accentColor,
    String? notificationSound,
    String? layoutMode,
    String? currency,
  }) {
    return Settings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      fontSize: fontSize ?? this.fontSize,
      privacyMode: privacyMode ?? this.privacyMode,
      accentColor: accentColor ?? this.accentColor,
      notificationSound: notificationSound ?? this.notificationSound,
      layoutMode: layoutMode ?? this.layoutMode,
      currency: currency ?? this.currency,
    );
  }

  /// Merges another [Settings] instance into this one.
  Settings merge(Settings newSettings) {
    return copyWith(
      theme: newSettings.theme,
      language: newSettings.language,
      notificationsEnabled: newSettings.notificationsEnabled,
      fontSize: newSettings.fontSize,
      privacyMode: newSettings.privacyMode,
      accentColor: newSettings.accentColor,
      notificationSound: newSettings.notificationSound,
      layoutMode: newSettings.layoutMode,
      currency: newSettings.currency,
    );
  }

  /// Helper method to toggle the theme between light and dark.
  Settings toggleTheme() {
    return copyWith(theme: theme == 'light' ? 'dark' : 'light');
  }

  /// Helper method to toggle notifications on and off.
  Settings toggleNotifications() {
    return copyWith(notificationsEnabled: !notificationsEnabled);
  }

  /// Helper method to toggle privacy mode.
  Settings togglePrivacyMode() {
    return copyWith(privacyMode: !privacyMode);
  }

  /// Returns a [Color] instance based on the accentColor integer.
  Color get accentColorAsColor => Color(accentColor);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Settings &&
        other.theme == theme &&
        other.language == language &&
        other.notificationsEnabled == notificationsEnabled &&
        other.fontSize == fontSize &&
        other.privacyMode == privacyMode &&
        other.accentColor == accentColor &&
        other.notificationSound == notificationSound &&
        other.layoutMode == layoutMode &&
        other.currency == currency;
  }

  @override
  int get hashCode {
    return theme.hashCode ^
    language.hashCode ^
    notificationsEnabled.hashCode ^
    fontSize.hashCode ^
    privacyMode.hashCode ^
    accentColor.hashCode ^
    notificationSound.hashCode ^
    layoutMode.hashCode ^
    currency.hashCode;
  }

  @override
  String toString() {
    return 'Settings(theme: $theme, language: $language, notificationsEnabled: $notificationsEnabled, '
        'fontSize: $fontSize, privacyMode: $privacyMode, accentColor: $accentColor, '
        'notificationSound: $notificationSound, layoutMode: $layoutMode, currency: $currency)';
  }
}
