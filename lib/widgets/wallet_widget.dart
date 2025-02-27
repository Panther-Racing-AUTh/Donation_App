import 'package:donation_app_v1/const_values/profile_page_values.dart';
import 'package:donation_app_v1/enums/card_type_enum.dart';
import 'package:donation_app_v1/models/card_model.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:donation_app_v1/screens/lock_screen.dart';
import 'package:donation_app_v1/screens/otp_verification_screen.dart';
import 'package:donation_app_v1/screens/welcome_digit_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
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
  bool authChecked=false;
  bool authRemoveChecked=false;
  @override
  void initState() {
    super.initState();
    _loadCardDetails();
    authChecked==false;
    authRemoveChecked=false;
    for(var card in widget.cards){
      card.isHidden=true;
    }
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
  String getCurrentLanguage()  {
    // Ensure that the Hive box is open. If already open, this returns the box immediately.
    final Box<Settings> settingsBox = Hive.box<Settings>('settingsBox');

    // Retrieve stored settings or use default settings if none are stored.
    final Settings settings = settingsBox.get('userSettings', defaultValue: Settings.defaultSettings)!;

    // Return the current language as an enum.
    return  settings.language;
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

  Future<void> removePaymentCard(PaymentCard cardToRemove) async {
    ProfileProvider profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    try {
      // Get the current user
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated.");
      }

      // Remove the card from the profile provider's payment cards list
      profileProvider.profile!.paymentCards.removeWhere(
            (card) => card.cardNumber == cardToRemove.cardNumber &&
            card.expirationDate == cardToRemove.expirationDate &&
            card.uuid == cardToRemove.uuid,
      );

      // Get the updated list of cards
      List<dynamic> updatedCards = convertCardsToJson(profileProvider.profile!.paymentCards) ?? [];

      // Update the database with the new list of cards
      await _supabaseClient
          .from('profiles')
          .update({'payment_cards': updatedCards})
          .eq('username', user.userMetadata?['username']);

      _showMessage("Card removed successfully!");
    } catch (e) {
      print("Error removing card: $e");
      _showMessage("Failed to remove card. Please try again.");
    }
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
            ProfileLabels.getLabel(getCurrentLanguage(), 'No cards available'),
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _addCard,
            icon: Icon(Icons.add_card,color: Colors.white70,),
            label: Text(ProfileLabels.getLabel(getCurrentLanguage(), 'Add Card'),style: TextStyle(color: Colors.white70),),
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
            ProfileLabels.getLabel(getCurrentLanguage(), 'Your Wallet'),
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20),
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
          label: Text(ProfileLabels.getLabel(getCurrentLanguage(), ProfileLabels.getLabel(getCurrentLanguage(), 'Add Card')),style: TextStyle(color: Colors.white70),),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(6, 0),spreadRadius: 0),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Front Side of Card
              Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.teal.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/panther_transparent_logo.png',width: 60,height: 60,),
                    const Spacer(),
                    Text(
                      maskedCardNumber,
                      style: GoogleFonts.robotoMono(fontSize: 17, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Exp: ${card.expirationDate.substring(0, 2)}/${card.expirationDate.substring(2)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        SizedBox(
                          width: 40,
                        ),
                        Text(
                          'CVC: $maskedCVC',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Back Side of Card (Simulating magnetic stripe)
            ],
          ),
          Positioned(
            right: 20,
            bottom: 40,
            child: card.cardType.getIcon(),

          ),
          Positioned(
            right: 10,
            top: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    if (!authChecked) {
                      card.isHidden=true;
                      setState(() {

                      });
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LockScreen(
                            isAuthCheck: true,
                            isLockSetup: false,
                          ),
                        ),
                      );

                      if (result == true) {
                        authChecked = true;
                        print("Access Granted!");
                      } else {
                        authChecked = false;
                        print("Access Denied.");
                      }
                    }
                    if (authChecked) {
                      card.isHidden = !card.isHidden;
                      setState(() {});
                    }
                  },
                  child: Icon(card.isHidden ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTapDown: (TapDownDetails details) {
                    final tapPosition = details.globalPosition;
                    final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;
                    showMenu<String>(
                      context: context,
                      position: RelativeRect.fromRect(
                        tapPosition & const Size(40, 40),
                        Offset.zero & overlay.size,
                      ),
                      items: [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text(
                              ProfileLabels.getLabel(getCurrentLanguage(), 'Edit')),
                        ),
                        PopupMenuItem<String>(
                          value: 'remove',
                          child: Text(
                              ProfileLabels.getLabel(getCurrentLanguage(), 'Remove')),
                        ),
                      ],
                    ).then((value) async{
                      if (value == 'edit') {
                        print("Edit selected");
                      } else if (value == 'remove') {
                        if (!authRemoveChecked) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LockScreen(
                                isAuthCheck: true,
                                isLockSetup: false,
                              ),
                            ),
                          );

                          if (result == true) {
                            authRemoveChecked = true;
                            print("Access Granted!");
                          } else {
                            authRemoveChecked = false;
                            print("Access Denied.");
                          }
                        }
                        if (authRemoveChecked) {
                          removePaymentCard(card);
                          setState((){

                          });
                        }

                      }
                    });
                  },
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }}




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
  String getCurrentLanguage()  {
    // Ensure that the Hive box is open. If already open, this returns the box immediately.
    final Box<Settings> settingsBox = Hive.box<Settings>('settingsBox');

    // Retrieve stored settings or use default settings if none are stored.
    final Settings settings = settingsBox.get('userSettings', defaultValue: Settings.defaultSettings)!;

    // Return the current language as an enum.
    return  settings.language;
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
              Text(ProfileLabels.getLabel(getCurrentLanguage(), 'Add New Card'), style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 10),
              DropdownButtonFormField<CardType>(
                decoration: InputDecoration(
                  labelText: ProfileLabels.getLabel(getCurrentLanguage(), 'Card Type'),
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
                label: ProfileLabels.getLabel(getCurrentLanguage(), 'Card Number'),
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
                    child: Text(ProfileLabels.getLabel(getCurrentLanguage(), 'Cancel')),
                  ),
                  ElevatedButton(
                    onPressed: _saveCard,
                    child: Text(ProfileLabels.getLabel(getCurrentLanguage(), 'Save')),
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
