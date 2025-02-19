import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:donation_app_v1/providers/provider.dart';

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
    final String fullPath = path.isNotEmpty ? '$path/${_supabaseClient.auth.currentUser!.userMetadata!['username']}_${_supabaseClient.auth.currentUser!.id}/$fileName' : fileName;

    // Upload the file to your Supabase storage bucket.
    final response = await _supabaseClient.storage
        .from(bucketName)
        .upload(fullPath, file);

    if (response.isEmpty) {
      // Handle the error if needed.
      print("Upload error: ${response}");
      return;
    }

    // Get the public URL for the uploaded image.
    final publicUrlResponse = _supabaseClient.storage
        .from(bucketName)
        .getPublicUrl(fullPath);
    final String imageUrl = publicUrlResponse;

    // Update the image_url column in the profiles table.
    final String username = _supabaseClient.auth.currentUser!.userMetadata!["username"];
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
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return GestureDetector(
      onTap: () {
        _pickAndUploadImage(bucketName: 'myBucket',path: 'profiles/');
      },
      child: CircleAvatar(
      radius: 42,
      backgroundColor: Colors.teal.shade700,
      foregroundImage: _hasImageError ? null : NetworkImage(profileProvider.profile!.imageUrl),
      onForegroundImageError: (exception, stackTrace) {
        // When error occurs, update state to show fallback text.
        setState(() {
          _hasImageError = true;
        });
        print("Error loading image: $exception");
      },
      child: _hasImageError
          ? Text(
        ( _supabaseClient.auth.currentUser!.userMetadata!['username'] ?? "User" )[0].toUpperCase(),
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
