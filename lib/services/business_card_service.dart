import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pocketledger/models/business_card_model.dart';

class BusinessCardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Save card model to Firestore
  Future<void> saveCardData(BusinessCardModel card) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');

    await _db.collection('users').doc(uid).collection('business_card').doc('info').set(
      card.toJson(),
      SetOptions(merge: true),
    );
  }

  // Load card model from Firestore
  Future<BusinessCardModel?> loadCardData() async {
    final uid = _uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).collection('business_card').doc('info').get();
    if (!doc.exists || doc.data() == null) return null;

    return BusinessCardModel.fromJson(doc.data()!);
  }

  // Upload card image to Cloudinary and return public URL
  Future<String> uploadCardImage(Uint8List imageBytes) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');

    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    final apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
    final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
    final folder = 'pocketledger_cards';

    if (cloudName.isEmpty || apiKey.isEmpty || apiSecret.isEmpty) {
      throw Exception('Cloudinary configuration is missing from environment variables');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Generate SHA-1 signature (sorted parameters alphabetical order: folder, timestamp)
    final stringToSign = 'folder=$folder&timestamp=$timestamp$apiSecret';
    final signature = sha1.convert(utf8.encode(stringToSign)).toString();

    final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.fields['api_key'] = apiKey;
    request.fields['timestamp'] = timestamp.toString();
    request.fields['signature'] = signature;
    request.fields['folder'] = folder;
    
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: 'business_card_${uid}_${DateTime.now().millisecondsSinceEpoch}.png',
    ));
    
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = json.decode(responseBody);
      final downloadUrl = jsonResponse['secure_url'] as String;

      // Store image URL in Firestore
      await _db.collection('users').doc(uid).collection('business_card').doc('info').set({
        'imageUrl': downloadUrl,
      }, SetOptions(merge: true));

      return downloadUrl;
    } else {
      throw Exception('Failed to upload image. Status code: ${response.statusCode}, Body: $responseBody');
    }
  }
}
