import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), shape: BoxShape.circle),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                      Text('Profile', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 48), // Spacer to center title
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accentGold, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            backgroundImage: (profilePic != null && profilePic.isNotEmpty) ? NetworkImage(profilePic) : null,
                            child: (profilePic == null || profilePic.isEmpty)
                                ? const Icon(Icons.person_rounded, size: 60, color: Colors.white)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => _showEditProfile(name, profilePic),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: AppColors.accentGold, shape: BoxShape.circle),
                              child: const Icon(Icons.edit_rounded, color: AppColors.primaryGreen, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(email, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
    final picController = TextEditingController(text: currentPic);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Edit Profile', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
            const SizedBox(height: 8),
            Text('Update your personal information', style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textGrey)),
            const SizedBox(height: 32),
            _buildTextField(nameController, 'Full Name', Icons.person_outline_rounded),
            const SizedBox(height: 20),
            _buildTextField(picController, 'Profile Image URL', Icons.image_outlined),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  await _authService.updateProfile(
                    name: nameController.text.trim(),
                    profilePic: picController.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Save Changes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
