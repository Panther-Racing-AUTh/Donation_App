import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrCodeScanner extends StatefulWidget {
  const QrCodeScanner({super.key});

  @override
  State<QrCodeScanner> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

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

  @override
  Widget build(BuildContext context) {
    return Stack(
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
    );
  }
}
