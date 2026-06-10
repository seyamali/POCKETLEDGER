import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:convert';
import 'package:pocketledger/core/utils/image_utils.dart';
import 'package:pocketledger/services/security_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/goal_service.dart';
import 'package:pocketledger/core/constants/app_constants.dart';
import 'package:pocketledger/services/theme_service.dart';
import 'package:pocketledger/core/localization/app_localizations.dart';
import 'package:pocketledger/services/language_service.dart';
import 'package:pocketledger/features/business_card/business_card_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final SecurityService _securityService = SecurityService();
  final ThemeService _themeService = ThemeService();

  String _fmt(double v) => v.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService().languageNotifier,
      builder: (context, lang, _) {
        return ThemeBuilder(builder: (context) => Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: StreamBuilder<DocumentSnapshot>(
            stream: _authService.getUserProfile(),
            builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildMissingProfileState();
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String name = userData['name'] ?? 'User';
          final String email = userData['email'] ?? 'No email';
          final String? profilePic = userData['profilePic'];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Premium Profile Header ──
              SliverToBoxAdapter(child: _buildHeader(name, email, profilePic)),

              // ── Settings List ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    children: [
                      _buildSectionTitle(AppLocalizations.get('account_settings')),
                      const SizedBox(height: 16),
                      _buildSettingItem(
                        icon: Icons.edit_rounded,
                        title: AppLocalizations.get('edit_profile'),
                        subtitle: 'Change your name and avatar',
                        onTap: () => _showEditProfile(name, profilePic),
                      ),
                      _buildSettingItem(
                        icon: Icons.security_rounded,
                        title: 'Privacy & Security',
                        subtitle: 'App lock & security PIN',
                        onTap: _showPrivacySecurityModal,
                      ),
                      _buildSettingItem(
                        icon: Icons.contact_mail_rounded,
                        title: 'Digital Business Card',
                        subtitle: 'Create & share your card via QR/NFC',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BusinessCardScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        icon: Icons.password_rounded,
                        title: 'Change Password',
                        subtitle: 'Update your login password',
                        onTap: _showChangePasswordModal,
                      ),
                      _buildSettingItem(
                        icon: Icons.delete_forever_rounded,
                        title: 'Delete Account',
                        subtitle: 'Permanently remove your data',
                        onTap: _showDeleteAccountModal,
                        iconColor: AppColors.error,
                        textColor: AppColors.error,
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSectionTitle('Preferences'),
                      const SizedBox(height: 16),
                      _buildSettingItem(
                        icon: Icons.category_rounded,
                        title: 'Custom Categories',
                        subtitle: 'Manage and design categories',
                        onTap: () => Navigator.pushNamed(context, '/categories'),
                      ),
                      _buildDarkModeToggle(),
                      _buildSettingItem(
                        icon: Icons.notifications_active_rounded,
                        title: 'Notifications',
                        subtitle: 'Alerts and reminders',
                        onTap: () {},
                      ),
                      _buildLanguageToggle(),

                      const SizedBox(height: 32),
                      _buildSectionTitle('Reports & Data'),
                      const SizedBox(height: 16),
                      _buildSettingItem(
                        icon: Icons.picture_as_pdf_rounded,
                        title: 'Generate PDF Statement',
                        subtitle: 'Export transactions as a printable PDF',
                        onTap: () => _showPDFStatementDialog(name, email),
                      ),

                      const SizedBox(height: 48),
                      // Logout Button
                      GestureDetector(
                        onTap: () async {
                          await _authService.signOut();
                          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Text(AppLocalizations.get('log_out'), style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    )); // closes Scaffold + ThemeBuilder
      },
    );
  }

  Widget _buildHeader(String name, String email, String? profilePic) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background with Gradient and Shape
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryGreen, Color(0xFF2D6A4F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20, right: -20,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                      Text(AppLocalizations.get('profile'), style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Overlapping Avatar and Info
        Positioned(
          top: 100,
          left: 0, right: 0,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppColors.cardWhite, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: ImageUtils.buildProfileImage(profilePic),
                      child: (profilePic == null || profilePic.isEmpty)
                          ? Icon(Icons.person_rounded, size: 50, color: AppColors.primaryGreen)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => _showEditProfile(name, profilePic),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(Icons.edit_rounded, color: AppColors.primaryGreen, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(name, style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(email, style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        // Spacer to account for overlapping content
        const SizedBox(height: 260),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey, letterSpacing: 0.5)),
    );
  }

  Widget _buildSettingItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, Color? iconColor, Color? textColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: (iconColor ?? AppColors.primaryGreen).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor ?? AppColors.primaryGreen, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor ?? AppColors.textBlack)),
                  Text(subtitle, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textGrey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textGrey.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeService.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF52B788) : AppColors.primaryGreen).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? const Color(0xFF52B788) : AppColors.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.get('dark_mode'), style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                    Text(isDark ? 'Sleek dark interface active' : 'Switch to dark interface', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textGrey)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isDark,
                activeColor: AppColors.primaryGreen,
                onChanged: (val) async {
                  await _themeService.toggleTheme(val);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageToggle() {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService().languageNotifier,
      builder: (context, langCode, _) {
        final isBengali = langCode == 'bn';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.get('language'), style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                    Text(isBengali ? 'বাংলা' : 'English', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textGrey)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => LanguageService().setLanguage('en'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: !isBengali ? AppColors.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Eng', style: GoogleFonts.outfit(color: !isBengali ? Colors.white : AppColors.textGrey, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => LanguageService().setLanguage('bn'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isBengali ? AppColors.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('বাং', style: GoogleFonts.outfit(color: isBengali ? Colors.white : AppColors.textGrey, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacySecurityModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return FutureBuilder<List<bool>>(
            future: Future.wait([
              _securityService.isPinEnabled(),
              _securityService.isBiometricEnabled(),
              _securityService.canAuthenticateWithBiometrics(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                );
              }
              final isEnabled = snapshot.data?[0] ?? false;
              final isBiometricEnabled = snapshot.data?[1] ?? false;
              final canCheckBiometrics = snapshot.data?[2] ?? false;

              return Container(
                padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50, height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Privacy & Security', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                            const SizedBox(height: 4),
                            Text('Secure your financial records', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textGrey)),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: Icon(Icons.close_rounded, size: 20, color: AppColors.textBlack),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // PIN Lock Toggle
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isEnabled ? AppColors.primaryGreen.withValues(alpha: 0.05) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isEnabled ? AppColors.primaryGreen.withValues(alpha: 0.2) : Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEnabled ? Icons.shield_rounded : Icons.shield_outlined,
                            color: isEnabled ? AppColors.primaryGreen : AppColors.textGrey,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('App Lock (PIN)', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                                Text(
                                  isEnabled ? 'Lock active (PIN code setup)' : 'Enable to lock your app on launch/resume',
                                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textGrey),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: isEnabled,
                            activeColor: AppColors.primaryGreen,
                            onChanged: (val) {
                              Navigator.pop(context);
                              if (val) {
                                _showSetupPinModal();
                              } else {
                                _showDisablePinModal();
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    if (isEnabled && canCheckBiometrics) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isBiometricEnabled ? AppColors.primaryGreen.withValues(alpha: 0.05) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isBiometricEnabled ? AppColors.primaryGreen.withValues(alpha: 0.2) : Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fingerprint_rounded,
                              color: isBiometricEnabled ? AppColors.primaryGreen : AppColors.textGrey,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Biometric Unlock', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                                  Text(
                                    isBiometricEnabled ? 'Biometrics active (Face ID / Fingerprint)' : 'Unlock instantly using biometrics',
                                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textGrey),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isBiometricEnabled,
                              activeColor: AppColors.primaryGreen,
                              onChanged: (val) async {
                                final success = await _securityService.setBiometricEnabled(val);
                                if (success) {
                                  setModalState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (isEnabled) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showChangePinModal();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.key_rounded, color: AppColors.accentGold, size: 20),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text('Change Lock PIN', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textGrey, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }



  void _showSetupPinModal() {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    bool isConfirmStage = false;
    String errorMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50, height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Text(
                  isConfirmStage ? 'Confirm Lock PIN' : 'Set Lock PIN',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                ),
                const SizedBox(height: 8),
                Text(
                  isConfirmStage ? 'Re-enter your new 4-digit security PIN' : 'Enter a 4-digit security PIN to protect the app',
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textGrey),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: isConfirmStage ? confirmController : pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 20),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: '••••',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey.shade300, letterSpacing: 20),
                    ),
                    onChanged: (val) {
                      if (val.length == 4) {
                        setModalState(() {
                          errorMessage = '';
                        });
                      }
                    },
                  ),
                ),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(errorMessage, style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [AppColors.primaryGreen, Color(0xFF2D6A4F)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!isConfirmStage) {
                        final pin = pinController.text;
                        if (pin.length != 4 || int.tryParse(pin) == null) {
                          setModalState(() {
                            errorMessage = 'PIN must be exactly 4 digits';
                          });
                          return;
                        }
                        setModalState(() {
                          isConfirmStage = true;
                          errorMessage = '';
                        });
                      } else {
                        final pin = pinController.text;
                        final confirm = confirmController.text;
                        if (pin != confirm) {
                          setModalState(() {
                            errorMessage = 'PINs do not match. Try again.';
                            confirmController.clear();
                          });
                          return;
                        }
                        await _securityService.setPin(pin);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('Security PIN lock enabled successfully!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      isConfirmStage ? 'Enable PIN Lock' : 'Next',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showDisablePinModal() {
    final pinController = TextEditingController();
    String errorMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50, height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Text('Disable PIN Lock', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                const SizedBox(height: 8),
                Text('Enter your current 4-digit PIN to disable app lock security', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textGrey)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 20),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: '••••',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey.shade300, letterSpacing: 20),
                    ),
                  ),
                ),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(errorMessage, style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.error.withValues(alpha: 0.9),
                    boxShadow: [
                      BoxShadow(color: AppColors.error.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final pin = pinController.text;
                      final isValid = await _securityService.verifyPin(pin);
                      if (isValid) {
                        await _securityService.disablePin();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('App Lock PIN has been disabled.', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            ),
                          );
                        }
                      } else {
                        setModalState(() {
                          errorMessage = 'Incorrect PIN entered. Please try again.';
                          pinController.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text('Disable App Lock', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showChangePinModal() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isCurrentVerified = false;
    bool isConfirmStage = false;
    String errorMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          String title = 'Verify Current PIN';
          String sub = 'Enter your current PIN to authenticate change';
          TextEditingController activeCtrl = currentController;
          String btnText = 'Verify';

          if (isCurrentVerified) {
            if (isConfirmStage) {
              title = 'Confirm New PIN';
              sub = 'Re-enter your new 4-digit PIN';
              activeCtrl = confirmController;
              btnText = 'Confirm & Save';
            } else {
              title = 'Set New PIN';
              sub = 'Enter your new 4-digit PIN';
              activeCtrl = newController;
              btnText = 'Next';
            }
          }

          return Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50, height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Text(title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                const SizedBox(height: 8),
                Text(sub, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textGrey)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: activeCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 20),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: '••••',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey.shade300, letterSpacing: 20),
                    ),
                  ),
                ),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(errorMessage, style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [AppColors.primaryGreen, Color(0xFF2D6A4F)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!isCurrentVerified) {
                        final isValid = await _securityService.verifyPin(currentController.text);
                        if (isValid) {
                          setModalState(() {
                            isCurrentVerified = true;
                            errorMessage = '';
                          });
                        } else {
                          setModalState(() {
                            errorMessage = 'Incorrect PIN. Try again.';
                            currentController.clear();
                          });
                        }
                      } else if (!isConfirmStage) {
                        final newPin = newController.text;
                        if (newPin.length != 4 || int.tryParse(newPin) == null) {
                          setModalState(() {
                            errorMessage = 'PIN must be exactly 4 digits';
                          });
                          return;
                        }
                        setModalState(() {
                          isConfirmStage = true;
                          errorMessage = '';
                        });
                      } else {
                        final newPin = newController.text;
                        final confirm = confirmController.text;
                        if (newPin != confirm) {
                          setModalState(() {
                            errorMessage = 'PINs do not match. Try again.';
                            confirmController.clear();
                          });
                          return;
                        }
                        await _securityService.setPin(newPin);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('PIN updated successfully!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(btnText, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showEditProfile(String currentName, String? currentPic) {
    final nameController = TextEditingController(text: currentName);
    Uint8List? pickedImageBytes;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50, height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Profile', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                        const SizedBox(height: 4),
                        Text('Personalize your account', style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textGrey)),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(Icons.close_rounded, size: 20, color: AppColors.textBlack),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Premium Avatar Picker
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Glow
                      Container(
                        width: 130, height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.15),
                              blurRadius: 30, spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      // Avatar Container
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.accentGold, AppColors.primaryGreen],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(color: AppColors.cardWhite, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey.shade50,
                            backgroundImage: pickedImageBytes != null 
                                ? MemoryImage(pickedImageBytes!) 
                                : ImageUtils.buildProfileImage(currentPic),
                            child: (pickedImageBytes == null && (currentPic == null || currentPic.isEmpty))
                                ? Icon(Icons.person_rounded, size: 55, color: AppColors.primaryGreen.withValues(alpha: 0.3))
                                : null,
                          ),
                        ),
                      ),
                      // Camera Button
                      Positioned(
                        bottom: 4, right: 4,
                        child: GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            // Resize to 400x400 and set low quality to keep Base64 size small
                            final image = await picker.pickImage(
                              source: ImageSource.gallery, 
                              imageQuality: 30,
                              maxWidth: 400,
                              maxHeight: 400,
                            );
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setModalState(() {
                                pickedImageBytes = bytes;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                Text('User Details', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                const SizedBox(height: 16),
                _buildTextField(nameController, 'Your Full Name', Icons.person_outline_rounded),
                
                const SizedBox(height: 40),
                
                // Gradient Save Button
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [AppColors.primaryGreen, Color(0xFF2D6A4F)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 20, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isUploading ? null : () async {
                      setModalState(() => isUploading = true);
                      
                      String? imageUrl = currentPic;
                      if (pickedImageBytes != null) {
                        imageUrl = await _authService.uploadProfileImage(pickedImageBytes!);
                        if (imageUrl == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to upload image. Please check your connection or Storage rules.')),
                            );
                          }
                          setModalState(() => isUploading = false);
                          return;
                        }
                      }

                      await _authService.updateProfile(
                        name: nameController.text.trim(),
                        profilePic: imageUrl,
                      );
                      
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: isUploading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save Changes', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textBlack, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildMissingProfileState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          Text('No Profile Data', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _authService.createProfile(name: 'User'),
            child: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountModal() {
    final passwordController = TextEditingController();
    String errorMessage = '';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50, height: 5,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Text('Delete Account', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.error)),
                  const SizedBox(height: 8),
                  Text('Warning: This will permanently delete your account, including all your transactions, goals, and categories. This action cannot be undone.', 
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textGrey)),
                  const SizedBox(height: 24),
                  
                  // Current Password
                  Text('Confirm Password', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textBlack),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter your password to confirm',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(errorMessage, style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        final pass = passwordController.text;
                        if (pass.isEmpty) {
                          setModalState(() => errorMessage = 'Please enter your password');
                          return;
                        }

                        setModalState(() {
                          isLoading = true;
                          errorMessage = '';
                        });

                        try {
                          await _authService.deleteAccount(pass);
                          if (context.mounted) {
                            Navigator.pop(context); // Close modal
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          }
                        } catch (e) {
                          setModalState(() {
                            isLoading = false;
                            errorMessage = 'Incorrect password or failed to delete account.';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Permanently Delete', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _showChangePasswordModal() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String errorMessage = '';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50, height: 5,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Text('Change Password', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                  const SizedBox(height: 8),
                  Text('Ensure your new password is at least 6 characters.', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textGrey)),
                  const SizedBox(height: 24),
                  
                  // Current Password
                  Text('Current Password', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: currentController,
                      obscureText: true,
                      style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textBlack),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter current password',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // New Password
                  Text('New Password', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: newController,
                      obscureText: true,
                      style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textBlack),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter new password',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm Password
                  Text('Confirm New Password', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: confirmController,
                      obscureText: true,
                      style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textBlack),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Re-enter new password',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(errorMessage, style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        final current = currentController.text;
                        final newPass = newController.text;
                        final confirm = confirmController.text;

                        if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                          setModalState(() => errorMessage = 'All fields are required');
                          return;
                        }
                        if (newPass.length < 6) {
                          setModalState(() => errorMessage = 'New password must be at least 6 characters');
                          return;
                        }
                        if (newPass != confirm) {
                          setModalState(() => errorMessage = 'New passwords do not match');
                          return;
                        }

                        setModalState(() {
                          isLoading = true;
                          errorMessage = '';
                        });

                        try {
                          await _authService.changePassword(current, newPass);
                          if (context.mounted) {
                            Navigator.pop(context); // Close modal
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.success,
                                content: Text('Password changed successfully!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() {
                            isLoading = false;
                            errorMessage = 'Failed to change password. Make sure current password is correct.';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Change Password', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _showPDFStatementDialog(String name, String email) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _GeneratePDFSheet(userName: name, userEmail: email);
      },
    );
  }
}

class _GeneratePDFSheet extends StatefulWidget {
  final String userName;
  final String userEmail;

  const _GeneratePDFSheet({required this.userName, required this.userEmail});

  @override
  State<_GeneratePDFSheet> createState() => _GeneratePDFSheetState();
}

class _GeneratePDFSheetState extends State<_GeneratePDFSheet> {
  String _selectedRange = 'Current Month';
  bool _isGenerating = false;

  void _generatePDF() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final goalService = GoalService();
      final transactions = await goalService.getAllTransactions().first;

      final now = DateTime.now();
      List<TransactionModel> filtered = [];
      String rangeLabel = '';

      if (_selectedRange == 'Current Month') {
        filtered = transactions.where((tx) =>
          tx.date.month == now.month && tx.date.year == now.year
        ).toList();
        rangeLabel = "${now.month.toString().padLeft(2, '0')}-${now.year}";
      } else if (_selectedRange == 'Last 3 Months') {
        final cutOff = DateTime(now.year, now.month - 2, 1);
        filtered = transactions.where((tx) =>
          tx.date.isAfter(cutOff.subtract(const Duration(days: 1)))
        ).toList();
        rangeLabel = "Last 3 Months";
      } else {
        filtered = transactions;
        rangeLabel = "All Time";
      }

      // Filter for ownerSelf
      final selfTxs = filtered.where((tx) => tx.owner == AppConstants.ownerSelf).toList();
      // Sort descending (newest first)
      selfTxs.sort((a, b) => b.date.compareTo(a.date));

      if (selfTxs.isEmpty) {
        throw Exception("No transactions found for the selected range.");
      }

      // Generate PDF Bytes
      final pdfBytes = await _generatePDFBytes(selfTxs, widget.userName, widget.userEmail, rangeLabel);

      // Share PDF
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'PocketLedger_Statement_${rangeLabel.replaceAll(' ', '_')}.pdf',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryGreen,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Statement shared successfully!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.toString().replaceAll("Exception: ", ""),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _generateCSV() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final goalService = GoalService();
      final transactions = await goalService.getAllTransactions().first;

      final now = DateTime.now();
      List<TransactionModel> filtered = [];
      String rangeLabel = '';

      if (_selectedRange == 'Current Month') {
        filtered = transactions.where((tx) =>
          tx.date.month == now.month && tx.date.year == now.year
        ).toList();
        rangeLabel = "${now.month.toString().padLeft(2, '0')}-${now.year}";
      } else if (_selectedRange == 'Last 3 Months') {
        final cutOff = DateTime(now.year, now.month - 2, 1);
        filtered = transactions.where((tx) =>
          tx.date.isAfter(cutOff.subtract(const Duration(days: 1)))
        ).toList();
        rangeLabel = "Last 3 Months";
      } else {
        filtered = transactions;
        rangeLabel = "All Time";
      }

      final selfTxs = filtered.where((tx) => tx.owner == AppConstants.ownerSelf).toList();
      selfTxs.sort((a, b) => b.date.compareTo(a.date));

      if (selfTxs.isEmpty) {
        throw Exception("No transactions found for the selected range.");
      }

      List<List<dynamic>> rows = [];
      rows.add(["Date", "Category", "Note", "Type", "Amount (BDT)"]);

      for (var tx in selfTxs) {
        final dateStr = "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}";
        final typeStr = tx.type == TransactionType.income ? "Income" : tx.type == TransactionType.expense ? "Expense" : "Transfer";
        rows.add([dateStr, tx.category, tx.note, typeStr, tx.amount]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/PocketLedger_Statement_${rangeLabel.replaceAll(' ', '_')}.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(file.path)], text: 'PocketLedger CSV Statement');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryGreen,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('CSV Exported successfully!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              e.toString().replaceAll("Exception: ", ""),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<Uint8List> _generatePDFBytes(
    List<TransactionModel> transactions,
    String userName,
    String userEmail,
    String rangeLabel,
  ) async {
    final pdf = pw.Document();

    double totalIncome = 0;
    double totalExpense = 0;
    double totalSaved = 0;

    for (var tx in transactions) {
      final cat = tx.category.toLowerCase();
      bool isSavings = cat.contains('sav') || 
                       tx.toAccountName?.toLowerCase().contains('sav') == true;

      if (isSavings) {
        totalSaved += tx.amount;
      } else {
        if (tx.type == TransactionType.income && cat == 'salary') {
          totalIncome += tx.amount;
        }
        if (tx.type == TransactionType.expense) {
          totalExpense += tx.amount;
        }
      }
    }

    final netSaved = totalIncome - totalExpense - totalSaved;

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "POCKET LEDGER",
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 22,
                      color: PdfColor.fromInt(0xFF005F41),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "Personal Financial Statement",
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "Date Range: $rangeLabel",
                    style: pw.TextStyle(font: fontBold, fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "Generated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
                    style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1.5, color: PdfColor.fromInt(0xFF005F41)),
          pw.SizedBox(height: 16),

          pw.Row(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Prepared For:", style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700)),
                  pw.Text(userName, style: pw.TextStyle(font: fontBold, fontSize: 14)),
                  pw.Text(userEmail, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPDFStatCard("Total Income", "BDT ${totalIncome.toInt()}", font, fontBold, PdfColor.fromInt(0xFFE8F5E9), PdfColor.fromInt(0xFF2E7D32)),
              _buildPDFStatCard("Total Expenses", "BDT ${totalExpense.toInt()}", font, fontBold, PdfColor.fromInt(0xFFFFECEB), PdfColor.fromInt(0xFFC62828)),
              _buildPDFStatCard("Net Saved", "BDT ${netSaved.toInt()}", font, fontBold, PdfColor.fromInt(0xFFFFFDE7), PdfColor.fromInt(0xFFF57F17)),
            ],
          ),
          pw.SizedBox(height: 32),

          pw.Text("Transaction Log", style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColor.fromInt(0xFF005F41))),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            headers: ["Date", "Category", "Note", "Flow", "Amount"],
            data: transactions.map((tx) {
              final dateStr = "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}";
              final typeStr = tx.type == TransactionType.income ? "Income" : tx.type == TransactionType.expense ? "Expense" : "Transfer";
              return [
                dateStr,
                tx.category,
                tx.note,
                typeStr,
                "BDT ${tx.amount.toInt()}",
              ];
            }).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
            headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF005F41)),
            cellStyle: pw.TextStyle(font: font, fontSize: 8.5),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              4: pw.Alignment.centerRight,
            },
            rowDecoration: const pw.BoxDecoration(
              color: PdfColors.white,
            ),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColors.grey50,
            ),
          ),
        ],
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              "Page ${context.pageNumber} of ${context.pagesCount}",
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPDFStatCard(
    String title,
    String value,
    pw.Font font,
    pw.Font fontBold,
    PdfColor bgColor,
    PdfColor textColor,
  ) {
    return pw.Container(
      width: 155,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: font, fontSize: 8, color: textColor),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(String range) {
    final isSelected = _selectedRange == range;
    return GestureDetector(
      onTap: () {
        if (!_isGenerating) {
          setState(() {
            _selectedRange = range;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.08) : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              range,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSelected ? AppColors.primaryGreen : AppColors.textBlack,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 20)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        decoration: BoxDecoration(
          color: Color(0xFFF4F6F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Export Statement",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textBlack,
                      ),
                    ),
                    Text(
                      "Select statement period",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildRangeSelector('Current Month'),
            _buildRangeSelector('Last 3 Months'),
            _buildRangeSelector('All Time'),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateCSV,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryGreen,
                      side: BorderSide(color: AppColors.primaryGreen, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isGenerating
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 2.5),
                          )
                        : Text(
                            "Export CSV",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generatePDF,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            "Export PDF",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
