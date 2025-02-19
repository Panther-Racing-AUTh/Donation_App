import 'package:donation_app_v1/enums/card_type_enum.dart';
import 'package:donation_app_v1/models/card_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';


final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client

class WalletWidget extends StatefulWidget {
  List<PaymentCard> cards;
  WalletWidget({required this.cards});
  @override
  _WalletWidgetState createState() => _WalletWidgetState();
}

class _WalletWidgetState extends State<WalletWidget> {
  @override
  void initState() {
    super.initState();
    _loadCardDetails();
  }

  Future<void> _loadCardDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, String>> loadedCards = [];

    for (int index = 0; index < 3; index++) {
      String? cardNumber = prefs.getString('cardNumber$index');
      if (cardNumber != null) {
        loadedCards.add({
          'cardNumber': cardNumber,
          'expirationDate': prefs.getString('expirationDate$index') ?? '01/${25 + index}',
          'balance': prefs.getString('balance$index') ?? (1000 + index * 500).toString(),
          'cvc': prefs.getString('cvc$index') ?? '***',
        });
      }
    }
  }

  Future<void> addPaymentCard(PaymentCard newCard) async {

    try {
      // Get the current user
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated.");
      }
      widget.cards.add(newCard);

      // Get the existing cards or initialize an empty list
      List<dynamic> existingCards = convertCardsToJson(widget.cards) ?? [];


      // Update the profile with the new list of cards
      await _supabaseClient
          .from('profiles')
          .update({'payment_cards': existingCards})
          .eq('username', user.userMetadata?['username']);

      _showMessage("Card added successfully!");
    } catch (e) {
      print("Error adding card: $e");
      _showMessage("Failed to add card. Please try again.");
    }
  }
  void _addCard() {
    showDialog(
      context: context,
      builder: (context) {
        return AddCardDialog(
          onSave: (cardData) {
            setState(() {
              addPaymentCard(cardData);
            });
          },
        );
      },
    );
  }
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  @override
  Widget build(BuildContext context) {
    return widget.cards.isEmpty
        ? Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FontAwesomeIcons.wallet, size: 50, color: Colors.grey.shade400),
          SizedBox(height: 10),
          Text(
            'No cards available',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _addCard,
            icon: Icon(Icons.add_card,color: Colors.white70,),
            label: Text('Add Card',style: TextStyle(color: Colors.white70),),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    )
        : Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
          decoration: BoxDecoration(
            color: Colors.teal.shade100.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Your Wallet',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 220,
          width: double.infinity,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.cards.length,
            itemBuilder: (context, index) => _buildCard(widget.cards[index]),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _addCard,
          icon: Icon(Icons.add_card,color: Colors.white70,),
          label: Text('Add Card',style: TextStyle(color: Colors.white70),),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
  String _formatCardNumber(String cardNumber) {
    return cardNumber.replaceAllMapped(RegExp(r".{4}"), (match) => "${match.group(0)} ");
  }
  Widget _buildCard(PaymentCard card) {
    String maskedCardNumber = card.isHidden
        ? '**** **** **** ${card.cardNumber.substring(12)}'
        : _formatCardNumber(card.cardNumber);

    String maskedCVC = card.isHidden ? '***' : card.cvc;

    return Container(
      width: 300,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(3, 3)),
        ],
      ),
      child: Stack(
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade700, Colors.teal.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Spacer(),
                  Text(
                    maskedCardNumber,
                    style: GoogleFonts.robotoMono(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Exp: ${card.expirationDate.substring(0, 2)}/${card.expirationDate.substring(2)}',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'CVC: $maskedCVC',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 20,
            child: card.cardType.getIcon(),
          ),
          Positioned(
            right: 10,
            top: 27,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        card.isHidden = !card.isHidden;
                      });
                    },
                    child: Icon(card.isHidden ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                  ),
                  SizedBox(
                    width: 10,
                  ),
      GestureDetector(
        onTapDown: (TapDownDetails details) {
          final tapPosition = details.globalPosition;
          final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
          showMenu<String>(
            context: context,
            position: RelativeRect.fromRect(
              tapPosition & const Size(40, 40), // the position & size of the tap area
              Offset.zero & overlay.size,       // area of the screen
            ),
            items: [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem<String>(
                value: 'remove',
                child: Text('Remove'),
              ),
            ],
          ).then((value) {
            if (value == 'edit') {
              // Handle edit action here.
              print("Edit selected");
            } else if (value == 'remove') {
              // Handle remove action here.

            }
          });
        },
        child: const Icon(
          Icons.more_vert,
          color: Colors.white70,
        ),
      )

      ],
              ),
          )
        ],
      ),
    );
  }
}




class AddCardDialog extends StatefulWidget {
  final Function(PaymentCard) onSave;
  const AddCardDialog({Key? key, required this.onSave}) : super(key: key);

  @override
  _AddCardDialogState createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  CardType? _selectedCardType;
  String? errorText;

  final List<CardType> _cardTypes = CardType.values;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expController.dispose();
    _cvcController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _saveCard() {
    String cardNumber = _cardNumberController.text.replaceAll(" ", "");
    String exp = _expController.text.replaceAll("/", "");
    String cvc = _cvcController.text;
    String balanceText = _balanceController.text.trim();

    if (cardNumber.length != 16) {
      setState(() => errorText = 'Card number must be exactly 16 digits.');
      return;
    }
    if (exp.length != 4) {
      setState(() => errorText = 'Expiration date must be MM/YY format.');
      return;
    }
    if (cvc.length != 3) {
      setState(() => errorText = 'CVC must be exactly 3 digits.');
      return;
    }
    if (balanceText.isEmpty || double.tryParse(balanceText) == null) {
      setState(() => errorText = 'Balance must be a valid number.');
      return;
    }
    if (_selectedCardType == null) {
      setState(() => errorText = 'Please select a card type.');
      return;
    }

    PaymentCard card = PaymentCard(
      uuid: Uuid().v4(),
      cardNumber: cardNumber,
      expirationDate: exp,
      cardType: _selectedCardType!,
      cvc: cvc,
    );
    print("Niaou: ${card.toString()}");

    widget.onSave(card);
    Navigator.of(context).pop();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
    String hintText = '',
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlign: TextAlign.center,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add New Card', style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 10),
              DropdownButtonFormField<CardType>(
                decoration: InputDecoration(
                  labelText: 'Card Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                value: _selectedCardType,
                items: CardType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                            child: type.getIcon(color: Colors.black)), // Use the icon from the enum
                        SizedBox(width: 10),
                        Text(type.getString()), // Convert enum to readable string
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCardType = value);
                },
              ),
              _buildTextField(
                label: 'Card Number',
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                hintText: '1234 5678 9012 3456',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  CardNumberInputFormatter(),
                ],
              ),
              _buildTextField(
                label: 'Expiration Date',
                controller: _expController,
                keyboardType: TextInputType.number,
                hintText: 'MM/YY',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  ExpirationDateFormatter(),
                ],
              ),
              _buildTextField(
                label: 'CVC',
                controller: _cvcController,
                keyboardType: TextInputType.number,
                hintText: '123',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
              _buildTextField(
                label: 'Balance',
                controller: _balanceController,
                keyboardType: TextInputType.number,
                hintText: '1000',
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              if (errorText != null) ...[
                SizedBox(height: 10),
                Text(errorText!, style: TextStyle(color: Colors.red)),
              ],
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _saveCard,
                    child: Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Custom Input Formatters
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(' ', '');
    String formatted = '';

    for (int i = 0; i < text.length; i++) {
      formatted += text[i];
      if ((i + 1) % 4 == 0 && i != text.length - 1) formatted += ' ';
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpirationDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('/', '');
    String formatted = '';

    if (text.length > 2) {
      formatted = text.substring(0, 2) + '/' + text.substring(2);
    } else {
      formatted = text;
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
