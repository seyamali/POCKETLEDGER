import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pocketledger/app/app.dart';
import 'package:pocketledger/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const PocketLedgerApp());
}
