import 'package:flutter/material.dart';
import 'dart:convert';

class ImageUtils {
  static ImageProvider? buildProfileImage(String? profilePic) {
    if (profilePic == null || profilePic.isEmpty) return null;
    
    if (profilePic.startsWith('base64:')) {
      try {
        final base64String = profilePic.replaceFirst('base64:', '');
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return null;
      }
    }
    
    return NetworkImage(profilePic);
  }
}
