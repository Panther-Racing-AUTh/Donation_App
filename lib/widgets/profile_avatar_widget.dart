import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Added for QR Code generation

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({Key? key}) : super(key: key);

  @override
  _ProfileAvatarState createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  bool _hasImageError = false;

  Future<void> _pickAndUploadImage({
    required String bucketName,
    required String path,
  }) async {
    // Pick an image from the gallery.
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return; // User canceled picking.

    // Create a unique file name for the image.
    final String fileName =
        'profile_${_supabaseClient.auth.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.png';
    final File file = File(image.path);

    // Construct the full path for the file.
    final String fullPath = path.isNotEmpty
        ? '$path/${_supabaseClient.auth.currentUser!.userMetadata!['username']}_${_supabaseClient.auth.currentUser!.id}/$fileName'
        : fileName;

    // Upload the file to your Supabase storage bucket.
    final response = await _supabaseClient.storage
        .from(bucketName)
        .upload(fullPath, file);

    if (response.isEmpty) {
      // Handle the error if needed.
      print("Upload error: $response");
      return;
    }

    // Get the public URL for the uploaded image.
    final publicUrlResponse =
    _supabaseClient.storage.from(bucketName).getPublicUrl(fullPath);
    final String imageUrl = publicUrlResponse;

    // Update the image_url column in the profiles table.
    final String username =
    _supabaseClient.auth.currentUser!.userMetadata!["username"];
    final updateResponse = await _supabaseClient
        .from('profiles')
        .update({'image_url': imageUrl})
        .eq('username', username);

    // Update the profile in the provider.
    final profileProvider =
    Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.updateProfile(
      profileProvider.profile!.copyWith(imageUrl: imageUrl),
    );
    setState(() {});
  }

  void _showQrDialog() {
    // Using the current user's ID for QR data.
    final String qrData = "user:${_supabaseClient.auth.currentUser!.id}";
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.teal.shade900,
                Colors.tealAccent.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // QR Code widget with a white background.
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
                        data: "asdasd",
                        size: 200.0,
                      ),
                      SizedBox(height: 10),
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
              SizedBox(
                height: 30,
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  "Close",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return GestureDetector(
      onLongPress: () {
        _pickAndUploadImage(bucketName: 'myBucket', path: 'profiles/');
      },
      onTap: _showQrDialog, // Long press shows the QR code dialog.
      child: CircleAvatar(
        radius: 42,
        backgroundColor: Colors.teal.shade700,
        foregroundImage: _hasImageError
            ? const AssetImage('assets/images/default.png')
            : NetworkImage(profileProvider.profile!.imageUrl) as ImageProvider,
        onForegroundImageError: (exception, stackTrace) {
          // When error occurs, update state to show fallback text.
          setState(() {
            _hasImageError = true;
          });
          print("Error loading image: $exception");
        },
        child: _hasImageError
            ? Text(
          (_supabaseClient.auth.currentUser!.userMetadata!['username'] ??
              "User")[0]
              .toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: Colors.white,
          ),
        )
            : null,
      ),
    );
  }
}
