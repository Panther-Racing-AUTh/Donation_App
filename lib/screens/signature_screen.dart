import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureScreen extends StatelessWidget {
  final SignatureController _controller = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 5,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Signature')),
      body: Column(
        children: [
          Signature(
            controller: _controller,
            height: 300,
            width: double.infinity,
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                },
              ),
              IconButton(
                icon: Icon(Icons.check),
                onPressed: () async {
                  final signatureImage = await _controller.toImage(); // Capture the signature as an image
                  Navigator.pop(context, signatureImage);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
