// lib/services/image_upload_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase/firebase_config.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // Take picture with camera
  static Future<XFile?> takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  // Upload image to Firebase Storage
  static Future<String?> uploadImage(
    String productId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final Reference storageRef = FirebaseConfig.storage
          .ref()
          .child('product_images')
          .child(productId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Delete image from Firebase Storage
  static Future<void> deleteImage(String image) async {
    try {
      if (image.isNotEmpty && image.contains('firebasestorage.googleapis.com')) {
        final Reference storageRef = FirebaseConfig.storage.refFromURL(image);
        await storageRef.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Get image bytes from file
  static Future<Uint8List?> getImageBytes(File imageFile) async {
    try {
      return await imageFile.readAsBytes();
    } catch (e) {
      print('Error reading image bytes: $e');
      return null;
    }
  }

  // Validate image URL
  static bool isValidimage(String? url) {
    if (url == null || url.isEmpty) return false;
    
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    final validSchemes = ['http', 'https'];
    if (!validSchemes.contains(uri.scheme)) return false;
    
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    final path = uri.path.toLowerCase();
    
    return imageExtensions.any((ext) => path.endsWith(ext));
  }
}