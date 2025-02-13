import 'dart:convert';

import 'package:donation_app_v1/pay_slider_model.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QRCodeScannerPage extends StatefulWidget {
    Map<String,dynamic> data;

  QRCodeScannerPage({required this.data});

  @override
  _QRCodeScannerPageState createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  PageController pageController = PageController(initialPage: 0, keepPage: true);
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
                Colors.teal.shade900,
                Colors.tealAccent.shade400,
                Colors.white
              ],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter
          ),
        ),
        child: Stack(
          children: [
            PageView(
              controller: pageController,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              children: [
                Stack(
                  children: [
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 8.0,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QrImageView(
                              data: "${widget.data}",
                              size: 200.0,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Scan this QR Code",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 30,
                      right: 10,
                      child: IconButton(
                        style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.black26)),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close,size: 25,color: Colors.white,),
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(
                        borderColor: Colors.green,
                        borderRadius: 10,
                        borderLength: 20,
                        borderWidth: 5,
                        cutOutSize: MediaQuery.of(context).size.width * 0.8,
                      ),
                    ),
                    Positioned(
                      top: 30,
                      right: 10,
                      child: IconButton(
                        style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.white24)),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close,size: 25,color: Colors.black,),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BottomNavigationBar(
                  backgroundColor: Colors.teal.shade600,
                  selectedIconTheme: IconThemeData(
                    color: Colors.white,
                    size: 25,
                  ),
                  selectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  iconSize: 30,

                  showSelectedLabels: true,
                  showUnselectedLabels: false,
                  currentIndex: currentIndex,
                  onTap: (index) {
                    setState(() {
                      print(widget.data);
                      currentIndex = index;
                      pageController.jumpToPage(index);
                    });
                  },
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.qr_code),
                      label: "QR Code",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.qr_code_scanner),
                      label: "Scan QR",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      try {
        // Log the raw QR data
        print('Scanned QR Code: ${scanData.code}');
        controller.pauseCamera();

        // Attempt to parse QR data
        final Map<String, dynamic> tempData = parseQRData(scanData.code!);

        // Ensure required fields exist
        if (!tempData.containsKey('id') || !tempData.containsKey('title') ||
            !tempData.containsKey('amount_raised') || !tempData.containsKey('pic')) {
          throw Exception("Missing required fields in QR data.");
        }

        // Navigate to the donation page
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonationPage(tempData: tempData),
          ),
        );

        // Resume the camera when returning
        controller.resumeCamera();
      } catch (e) {
        // Log the error for debugging
        print('Error parsing QR code: $e');

        // Handle invalid QR data
        controller.pauseCamera();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Invalid QR Code'),
            content: Text('The scanned QR code is not valid. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  controller.resumeCamera();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

// Function to parse QR data safely
  Map<String, dynamic> parseQRData(String qrCodeData) {
    try {
      // Convert single quotes to double quotes (if necessary)
      String formattedJson = qrCodeData.replaceAll("'", "\"");

      // Decode the JSON string
      return jsonDecode(formattedJson);
    } catch (e) {
      throw Exception("Invalid QR Code Format");
    }
  }


  void showQRCodeDialog(BuildContext context, String qrCodeData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('QR Code'),
          content: Center(
            child: QrImageView(
              data: qrCodeData,
              size: 200.0,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}


class DonationPage extends StatefulWidget {
  final Map<String,dynamic> tempData;
  const DonationPage({Key? key, required this.tempData}) : super(key: key);

  @override
  _DonationPageState createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  // Default selected donation amount

  final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client
  bool _isLoading=false;

  double _donationAmount = 100.0;
  String formatPoints(int points) {
    if (points >= 1000000) {
      return '${(points / 1000000).toStringAsFixed(points % 1000000 == 0 ? 0 : 1)}M';
    } else if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(points % 1000 == 0 ? 0 : 1)}K';
    } else {
      return points.toString();
    }
  }
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  @override
  Widget build(BuildContext context) {
    final String title = widget.tempData['title'];
    final int amountRaised = widget.tempData['amount_raised'];
    final String picUrl = widget.tempData['pic'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Donate to $title'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card to display image and details
              Card(
                elevation: 5.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                      child: Image.network(
                        picUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Amount Raised: \$${formatPoints(amountRaised)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Title Section
              Text(
                'Choose Your Donation Amount',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
              ),
              SizedBox(height: 16),

              // Predefined donation buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _donationButton(100.0),
                  _donationButton(500.0),
                  _donationButton(1000.0),
                  _donationButton(2000.0),
                ],
              ),
              SizedBox(height: 20),

              // Selected amount
              Text(
                'Selected Amount: \$${_donationAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 20),

              // Slider to adjust the donation amount
              Text(
                'Or, slide to adjust the amount:',
                style: TextStyle(fontSize: 16, color: Colors.teal.shade700),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.teal.shade700,
                  inactiveTrackColor: Colors.teal.shade100,
                  thumbColor: Colors.teal,
                  overlayColor: Colors.teal.withOpacity(0.2),
                  valueIndicatorColor: Colors.teal.shade800,
                ),
                child: Slider(
                  value: _donationAmount,
                  min: 50.0,
                  max: 5000.0,
                  divisions: 500,
                  label: '\$${_donationAmount.toStringAsFixed(0)}',
                  onChanged: (value) {
                    setState(() {
                      _donationAmount = value;
                    });
                  },
                ),
              ),
              SizedBox(height: 20),

              // Donate Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showDonationConfirmationDialog(context);
                  },
                  icon: Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    'Confirm Donation',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Button to select a predefined donation amount
  Widget _donationButton(double amount) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _donationAmount = amount;
        });
      },
      child: Text('\$${formatPoints(amount.toInt())}'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade50,
        foregroundColor: Colors.teal.shade800,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
  Future<void> _insertDonation({int amount=0,required int category,String description=''}) async {
    setState(() {
      _isLoading = true;
    });

    // final amount = double.tryParse(_amountController.text.trim());

    final profileId = _supabaseClient.auth.currentUser!.id;


    if (amount <= 0) {
      _showMessage('Please enter valid donation details.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await _supabaseClient.from('donations').insert({
        "username" : _supabaseClient.auth.currentUser!.userMetadata!['username'] ?? "User",
        "email" : _supabaseClient.auth.currentUser!.email,
        "amount": amount,
        "created_at": DateTime.now().toIso8601String(),
        "donation_item_id" : category,
        'description' : description,
        "profile_id": profileId,
      });

    } catch (e) {
      _showMessage('An unexpected error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  // Show a dialog to confirm the donation
  void _showDonationConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Donation',
            style: TextStyle(color: Colors.teal.shade800),
          ),
          content: Text(
            'You are about to donate \$$_donationAmount to ${widget.tempData['title']}.',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _insertDonation(
                  amount: _donationAmount.toInt(),
                  category: widget.tempData['id'],
                );
                _showDonationSuccessDialog(context);
              },
              child: Text(
                'Confirm',
                style: TextStyle(color: Colors.teal.shade800),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show success message after donation
  void _showDonationSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Donation Successful',
            style: TextStyle(color: Colors.teal.shade800),
          ),
          content: Text(
            'Thank you for donating ₹$_donationAmount to ${widget.tempData['title']}.',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Optionally navigate back after donation
              },
              child: Text(
                'OK',
                style: TextStyle(color: Colors.teal.shade800),
              ),
            ),
          ],
        );
      },
    );
  }
}
