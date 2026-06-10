import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pocketledger/app/app.dart';
import 'package:pocketledger/firebase_options.dart';
import 'package:pocketledger/services/notification_service.dart';
import 'package:pocketledger/services/theme_service.dart';
import 'package:pocketledger/services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Theme and Language Services
  await ThemeService().init();
  await LanguageService().init();

  // Initialize local notifications
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Enable Offline Persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const PocketLedgerApp());
}
