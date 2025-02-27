import 'package:donation_app_v1/enums/currency_enum.dart';
import 'package:donation_app_v1/enums/drawer_enum.dart';
import 'package:donation_app_v1/models/card_model.dart';
import 'package:donation_app_v1/models/profile_model.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:flutter/foundation.dart';

class ProfileProvider extends ChangeNotifier {
  Profile? _profile;
  int _drawerIndex=DrawerItem.home.getInt();
  bool _isLocked=true;

  /// Returns the current profile.
  Profile? get profile => _profile;
  int get drawerIndex => _drawerIndex;
  bool get isLocked => _isLocked;

  /// Loads the profile from a data source (e.g., API, local storage).
  Future<void> loadProfile() async {
    // Simulate a delay for fetching data.
    await Future.delayed(const Duration(seconds: 1));

    // Example JSON data that you might fetch from an API.
    final Map<String, dynamic> json = {
      'id': '1',
      'username': 'User',
      'email': 'johndoe@example.com',
      'image_url': 'https://example.com/avatar.png',
      'settings': {
        'theme': 'dark',
        'language': 'en',
        'notifications_enabled': true,
      },
      'payment_cards': [
        // You can add example payment cards here if needed.
      ],
    };

    _profile = Profile.fromJson(json);
    notifyListeners();
  }
  void updateDrawerIndex(int newDrawerIndex) {
    _drawerIndex = newDrawerIndex;
    notifyListeners();
  }
  /// Updates the entire profile.
  void updateProfile(Profile newProfile) {
    _profile = newProfile;
    notifyListeners();
  }

  void updateIsLocked(bool isNewLocked) {
    _isLocked = isNewLocked;
    notifyListeners();
  }

  /// Updates the username.
  void updateUsername(String username) {
    if (_profile != null) {
      _profile = _profile!.copyWith(username: username);
      notifyListeners();
    }
  }
  void updateCurrency(Currency currencyCode) {
    if (_profile != null) {
      _profile = _profile!.copyWith(
        settings: _profile!.settings.copyWith(currency: currencyCode.code),
      );
      notifyListeners();
    }
  }
  /// Updates the settings.
  void updateSettings(Settings newSettings) {
    if (_profile != null) {
      _profile = _profile!.copyWith(settings: newSettings);
      notifyListeners();
    }
  }

  /// Adds a payment card to the profile.
  void addPaymentCard(PaymentCard card) {
    if (_profile != null) {
      final updatedCards = List<PaymentCard>.from(_profile!.paymentCards);
      updatedCards.add(card);
      _profile = _profile!.copyWith(paymentCards: updatedCards);
      notifyListeners();
    }
  }
}
