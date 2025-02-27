import 'package:donation_app_v1/providers/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum Currency {
  usd('USD', '\$'),
  eur('EUR', '€'),
  gbp('GBP', '£'),
  jpy('JPY', '¥'),
  inr('INR', '₹'),
  aud('AUD', 'A\$'),
  cad('CAD', 'C\$'),
  chf('CHF', 'CHF'),
  cny('CNY', '¥'),
  sek('SEK', 'kr'),
  nzd('NZD', 'NZ\$');

  final String code;
  final String symbol;

  const Currency(this.code, this.symbol);
}

extension CurrencyExtension on Currency {
  /// Returns a user-friendly string representation of the currency.
  String get getString {
    switch (this) {
      case Currency.usd:
        return "United States Dollar";
      case Currency.eur:
        return "Euro";
      case Currency.gbp:
        return "British Pound";
      case Currency.jpy:
        return "Japanese Yen";
      case Currency.inr:
        return "Indian Rupee";
      case Currency.aud:
        return "Australian Dollar";
      case Currency.cad:
        return "Canadian Dollar";
      case Currency.chf:
        return "Swiss Franc";
      case Currency.cny:
        return "Chinese Yuan";
      case Currency.sek:
        return "Swedish Krona";
      case Currency.nzd:
        return "New Zealand Dollar";
    }
  }

  /// Returns the currency's symbol.
  String get getSymbol => symbol;
}

extension CurrencyConversion on Currency {
  // Sample conversion rates with respect to 1 USD.
  static const Map<Currency, double> conversionRatesFromUSD = {
    Currency.usd: 1.0,
    Currency.eur: 0.85,
    Currency.gbp: 0.75,
    Currency.jpy: 110.0,
    Currency.inr: 74.0,
    Currency.aud: 1.35,
    Currency.cad: 1.25,
    Currency.chf: 0.92,
    Currency.cny: 6.45,
    Currency.sek: 8.6,
    Currency.nzd: 1.4,
  };

  /// Converts a given [amount] from the current currency to the [targetCurrency].
  double convert(double amount, Currency targetCurrency) {
    if (targetCurrency == Currency.usd) return amount;

    // Convert from USD to target currency
    return amount * conversionRatesFromUSD[targetCurrency]!;
  }
}

extension CurrencyFormatting on Currency {
  /// Formats an amount according to the currency's locale.
  String format(double amount) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }
}

/// Changes the currency of a given amount from [currentCurrency] to [newCurrency].
String changeCurrency(double amount, Currency currentCurrency, Currency newCurrency) {
  double convertedAmount = currentCurrency.convert(amount, newCurrency);
  return newCurrency.format(convertedAmount);
}
