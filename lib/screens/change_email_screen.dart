import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase package

class ChangeEmailPage extends StatefulWidget {
  @override
  _ChangeEmailPageState createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verifyEmailController = TextEditingController();

  String _errorText = '';
  bool _isLoading = false;
  bool _isOnline = true; // Change this based on your connectivity logic

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text("Change Email"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Connection Status
                if (!_isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "No internet connection",
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Email Input Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "New Email",
                    labelStyle: TextStyle(color: Colors.teal.shade800),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade800),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade800),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade800, width: 2.0),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _verifyEmailController,
                  decoration: InputDecoration(
                    labelText: "Verify Email",
                    labelStyle: TextStyle(color: Colors.teal.shade800),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade800),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade800),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade800, width: 2.0),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _isOnline ? _saveEmail : null,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("Save", style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),

                // Error Message
                if (_errorText.isNotEmpty)
                  Text(
                    _errorText,
                    style: TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 20),

              ],
            ),
          ),
        ),
      ),
    );
  }

  // Placeholder for social icon button
  Widget _buildSocialIcon(IconData icon, String label) {
    return IconButton(
      onPressed: _isOnline ? () {} : null,
      icon: Icon(icon, color: Colors.teal),
      tooltip: label,
      iconSize: 30,
    );
  }

  Future<void> _saveEmail() async {
    String newEmail = _emailController.text.trim();
    String verifyEmail = _verifyEmailController.text.trim();

    if (newEmail.isEmpty || verifyEmail.isEmpty) {
      setState(() {
        _errorText = "Fields cannot be empty.";
      });
      return;
    }


    // Simple email validation
    final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegExp.hasMatch(newEmail) || !emailRegExp.hasMatch(verifyEmail) ) {
      setState(() {
        _errorText = "Please enter a valid email address.";
      });
      return;
    }
    if(newEmail != verifyEmail){
      setState(() {
        _errorText = "Please enter a same email address.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = '';
    });

    try {
      final SupabaseClient supabase = Supabase.instance.client;

      final user = Supabase.instance.client.auth.currentUser; // Get the current user
      if (user != null) {
        // Update user email in Supabase auth
        await supabase.auth.updateUser(UserAttributes(
          email: newEmail

        ));
        print("First update correct");




        // Update the email in the profiles table


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Email updated successfully!")),
        );

        Navigator.pop(context, newEmail); // Return to the previous screen
      }
    } catch (error) {
      setState(() {
        _errorText = "Error updating email. Please try again.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
