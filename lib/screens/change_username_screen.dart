import 'package:donation_app_v1/providers/provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeUsernameScreen extends StatefulWidget {
  @override
  _ChangeUsernameScreenState createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<ChangeUsernameScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _usernameController = TextEditingController();
  String _errorText = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();
  }

  /// Fetch the current username from Supabase metadata
  Future<void> _loadCurrentUsername() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata;
      setState(() {
        _usernameController.text = metadata?['username'] ?? '';
      });
    }
  }

  /// Update the username in Supabase metadata
  Future<void> _saveUsername() async {
    String newUsername = _usernameController.text.trim();
    final profileProvider = Provider.of<ProfileProvider>(context,listen: false);
    if (newUsername.isEmpty) {
      setState(() {
        _errorText = "Username cannot be empty.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = '';
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Update user metadata
        await supabase.auth.updateUser(UserAttributes(
          data: {'username': newUsername},
        ));
        print("First update correct");

        // Update the username in the profiles table
        final response = await supabase
            .from('profiles')
            .update({'username': newUsername}) // Update username in profiles table
            .eq('id', profileProvider.profile!.id); // Assuming 'id' is the user ID in the profiles table

        print("Second update correct");


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Username updated successfully!")),
        );
        profileProvider.updateUsername(newUsername);
        Navigator.pop(context, newUsername); // Return to the previous screen
      }
    } catch (error) {
      setState(() {
        _errorText = "Error updating username. Please try again.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal, // Teal background for the AppBar
        title: Text(
          "Change Username",
          style: TextStyle(color: Colors.white), // White text color for the title
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // White color for back button
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter a new username:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]), // Darker teal color for text
            ),
            SizedBox(height: 12), // Increased spacing
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: "New username",
                hintStyle: TextStyle(color: Colors.teal[300]), // Lighter teal for hint text
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal), // Teal border when focused
                ),
                errorText: _errorText.isNotEmpty ? _errorText : null,
              ),
            ),
            SizedBox(height: 20),
            Center( // Center the button for a better layout
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.teal, // Teal background for the button
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Increased padding
                  textStyle: TextStyle(fontSize: 18), // Larger text for the button
                ),
                onPressed: _isLoading ? null : _saveUsername,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
