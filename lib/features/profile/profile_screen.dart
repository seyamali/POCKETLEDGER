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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  String _fmt(double v) => v.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _authService.getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
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
                      _buildSectionTitle('Account Management'),
                      const SizedBox(height: 16),
                      _buildSettingItem(
                        icon: Icons.edit_rounded,
                        title: 'Edit Profile',
                        subtitle: 'Change your name and avatar',
                        onTap: () => _showEditProfile(name, profilePic),
                      ),
                      _buildSettingItem(
                        icon: Icons.security_rounded,
                        title: 'Privacy & Security',
                        subtitle: 'Manage your passwords',
                        onTap: () {},
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSectionTitle('Preferences'),
                      const SizedBox(height: 16),
                      _buildSettingItem(
                        icon: Icons.notifications_active_rounded,
                        title: 'Notifications',
                        subtitle: 'Alerts and reminders',
                        onTap: () {},
                      ),
                      _buildSettingItem(
                        icon: Icons.language_rounded,
                        title: 'Language',
                        subtitle: 'English (US)',
                        onTap: () {},
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
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Text('Sign Out', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
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
          decoration: const BoxDecoration(
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
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
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
                      Text('Profile', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: ImageUtils.buildProfileImage(profilePic),
                      child: (profilePic == null || profilePic.isEmpty)
                          ? const Icon(Icons.person_rounded, size: 50, color: AppColors.primaryGreen)
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
                        child: const Icon(Icons.edit_rounded, color: AppColors.primaryGreen, size: 16),
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

  Widget _buildSettingItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: AppColors.primaryGreen, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                  Text(subtitle, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textGrey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textGrey.withOpacity(0.3), size: 16),
          ],
        ),
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
            decoration: const BoxDecoration(
              color: Colors.white,
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
                        child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textBlack),
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
                              color: AppColors.primaryGreen.withOpacity(0.15),
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
                          gradient: const LinearGradient(
                            colors: [AppColors.accentGold, AppColors.primaryGreen],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey.shade50,
                            backgroundImage: pickedImageBytes != null 
                                ? MemoryImage(pickedImageBytes!) 
                                : ImageUtils.buildProfileImage(currentPic),
                            child: (pickedImageBytes == null && (currentPic == null || currentPic.isEmpty))
                                ? Icon(Icons.person_rounded, size: 55, color: AppColors.primaryGreen.withOpacity(0.3))
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
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
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
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryGreen, Color(0xFF2D6A4F)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.3),
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
        color: const Color(0xFFF8FAF9),
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

}
