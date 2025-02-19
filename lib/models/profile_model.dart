import 'package:donation_app_v1/models/card_model.dart';
import 'package:donation_app_v1/models/settings_model.dart';



class Profile {
  final String id;
  final String username;
  final String email;
  final String imageUrl;
  final Settings settings;
  final List<PaymentCard> paymentCards;

  Profile({
    required this.id,
    required this.username,
    required this.email,
    required this.imageUrl,
    required this.settings,
    required this.paymentCards,
  });

  /// Creates a Profile instance from a JSON object.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      // Convert id to string, even if it's an int.
      id: json['id'] != null ? json['id'].toString() : '',
      // Provide a default empty string if email is not provided.
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      settings: json['settings'] != null
          ? Settings.fromJson(Map<String, dynamic>.from(json['settings']))
          : Settings(theme: 'light', language: 'en', notificationsEnabled: true),
      paymentCards: (json['payment_cards'] as List<dynamic>?)
          ?.map((e) =>
          PaymentCard.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
          [],
    );
  }

  /// Converts the Profile instance into a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'image_url': imageUrl,
      'settings': settings.toJson(),
      'payment_cards': paymentCards.map((card) => card.toJson()).toList(),
    };
  }

  /// Creates a copy of this Profile with updated fields.
  Profile copyWith({
    String? id,
    String? username,
    String? email,
    String? imageUrl,
    Settings? settings,
    List<PaymentCard>? paymentCards,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      settings: settings ?? this.settings,
      paymentCards: paymentCards ?? this.paymentCards,
    );
  }
}
