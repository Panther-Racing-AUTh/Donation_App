import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum CardType {
  visa,
  masterCard,
  americanExpress,
  discover,
  dinersClub,
  jcb,
  unionPay,
  maestro,
  rupay,
  amazonPay,
  applePay,
  googlePay,
  samsungPay,
  paypal,
  stripe,
  square,
  alipay,
  weChatPay,
}

extension CardTypeExtension on CardType {
  String getString() {
    switch (this) {
      case CardType.visa:
        return 'Visa';
      case CardType.masterCard:
        return 'MasterCard';
      case CardType.americanExpress:
        return 'American Express';
      case CardType.discover:
        return 'Discover';
      case CardType.dinersClub:
        return 'Diners Club';
      case CardType.jcb:
        return 'JCB';
      case CardType.unionPay:
        return 'UnionPay';
      case CardType.maestro:
        return 'Maestro';
      case CardType.rupay:
        return 'RuPay';
      case CardType.amazonPay:
        return 'Amazon Pay';
      case CardType.applePay:
        return 'Apple Pay';
      case CardType.googlePay:
        return 'Google Pay';
      case CardType.samsungPay:
        return 'Samsung Pay';
      case CardType.paypal:
        return 'PayPal';
      case CardType.stripe:
        return 'Stripe';
      case CardType.square:
        return 'Square';
      case CardType.alipay:
        return 'Alipay';
      case CardType.weChatPay:
        return 'WeChat Pay';
    }
  }

  Icon getIcon({Color? color}) {
    switch (this) {
      case CardType.visa:
        return Icon(FontAwesomeIcons.ccVisa, size: 40, color: color ?? Colors.white70);
      case CardType.masterCard:
        return Icon(FontAwesomeIcons.ccMastercard, size: 40, color: color ?? Colors.white70);
      case CardType.americanExpress:
        return Icon(FontAwesomeIcons.ccAmex, size: 40, color: color ?? Colors.white70);
      case CardType.discover:
        return Icon(FontAwesomeIcons.ccDiscover, size: 40, color: color ?? Colors.white70);
      case CardType.dinersClub:
        return Icon(FontAwesomeIcons.ccDinersClub, size: 40, color: color ?? Colors.white70);
      case CardType.jcb:
        return Icon(FontAwesomeIcons.ccJcb, size: 40, color: color ?? Colors.white70);
      case CardType.unionPay:
        return Icon(Icons.credit_card, size: 40, color: color ?? Colors.white70); // No FontAwesome icon
      case CardType.maestro:
        return Icon(Icons.credit_card, size: 40, color: color ?? Colors.white70);
      case CardType.rupay:
        return Icon(Icons.credit_card, size: 40, color: color ?? Colors.white70);
      case CardType.amazonPay:
        return Icon(FontAwesomeIcons.amazonPay, size: 40, color: color ?? Colors.white70);
      case CardType.applePay:
        return Icon(FontAwesomeIcons.applePay, size: 40, color: color ?? Colors.white70);
      case CardType.googlePay:
        return Icon(FontAwesomeIcons.google, size: 40, color: color ?? Colors.white70); // No direct icon
      case CardType.samsungPay:
        return Icon(Icons.credit_card, size: 40, color: color ?? Colors.white70);
      case CardType.paypal:
        return Icon(FontAwesomeIcons.ccPaypal, size: 40, color: color ?? Colors.white70);
      case CardType.stripe:
        return Icon(Icons.credit_card, size: 40, color: color ?? Colors.white70);
      case CardType.square:
        return Icon(Icons.credit_card, size: 40, color: color ?? Colors.white70);
      case CardType.alipay:
        return Icon(Icons.credit_card, size: 40, color: color ?? Colors.white70);
      case CardType.weChatPay:
        return Icon(Icons.credit_card, size: 40, color: color ?? Colors.white70);
    }
  }
  int getID() {
    return this.index;
  }
}
