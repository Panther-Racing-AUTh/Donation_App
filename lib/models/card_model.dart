import 'package:donation_app_v1/enums/card_type_enum.dart';
import 'package:uuid/uuid.dart';

class PaymentCard {
  String uuid;
  String cardNumber;
  String expirationDate;
  CardType cardType; // Use the enum instead of String
  String cvc;
  bool isHidden;

  PaymentCard({
    required this.uuid,
    required this.cardNumber,
    required this.expirationDate,
    required this.cardType,
    required this.cvc,
    this.isHidden=true,
  });

  // Convert a PaymentCard instance to JSON (Map)
  Map<String, dynamic> toJson() {
    return {
      'uuid' : uuid,
      'card_number': cardNumber,
      'card_type': cardType.getID(), // Convert enum to string
      'expiration_date': expirationDate,
      'cvc': cvc,
    };
  }

  // Create a PaymentCard from a JSON object (Map)
  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    return PaymentCard(
      uuid: json['uuid'] as String,
      cardNumber: json['card_number'] as String,
      expirationDate: json['expiration_date'] as String,
      cardType: CardType.values.firstWhere( // Convert string back to enum
            (e) => e.getID() == json['card_type'],
        orElse: () => CardType.visa, // Default to Visa if no match
      ),
      cvc: json['cvc'] as String,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PaymentCard) return false;
    return cardNumber == other.cardNumber &&
        expirationDate == other.expirationDate &&
        cardType == other.cardType &&
        cvc == other.cvc;
  }

  @override
  int get hashCode =>
      cardNumber.hashCode ^
      expirationDate.hashCode ^
      cardType.hashCode ^
      cvc.hashCode;
}
List<Map<String, dynamic>> convertCardsToJson(List<PaymentCard> cards) {
  return cards.map((card) => card.toJson()).toList();
}
List<PaymentCard> convertJsonToCards(List<Map<String,dynamic>> cards) {
  return cards.map((card) => PaymentCard.fromJson(card)).toList();
}