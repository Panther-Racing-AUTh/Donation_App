enum Currency {
  usd('USD', '\$'),
  eur('EUR', '€'),
  gbp('GBP', '£'),
  jpy('JPY', '¥'),
  inr('INR', '₹');

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
  };

  /// Converts a given [amount] from the current currency to the [targetCurrency].
  double convert(double amount, Currency targetCurrency) {
    // First, convert the amount from the current currency to USD.
    final double rateFromCurrentToUSD = 1 / conversionRatesFromUSD[this]!;
    final double amountInUSD = amount * rateFromCurrentToUSD;

    // Then, convert from USD to the target currency.
    final double rateUSDToTarget = conversionRatesFromUSD[targetCurrency]!;
    return amountInUSD * rateUSDToTarget;
  }
}
