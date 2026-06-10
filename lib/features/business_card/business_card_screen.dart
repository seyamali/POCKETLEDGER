import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/core/widgets/glass_card.dart';
import 'package:pocketledger/models/business_card_model.dart';
import 'package:pocketledger/features/business_card/widgets/qr_code_dialog.dart';
import 'package:pocketledger/features/business_card/widgets/nfc_write_dialog.dart';
import 'package:pocketledger/services/business_card_service.dart';

class BusinessCardScreen extends StatefulWidget {
  const BusinessCardScreen({super.key});

  @override
  State<BusinessCardScreen> createState() => _BusinessCardScreenState();
}

class _BusinessCardScreenState extends State<BusinessCardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showFrontSide = true;

  final _boundaryKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();
  final BusinessCardService _cardService = BusinessCardService();
  bool _isEditing = false;
  bool _isLoading = true;

  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;

  int _selectedThemeIndex = 0;
  BusinessCardModel _card = BusinessCardModel.empty();

  final List<List<Color>> _cardGradients = [
    [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)], // Midnight Deep Blue
    [const Color(0xFF00b4db), const Color(0xFF0083b0)], // Cool Blue
    [const Color(0xFF134e5e), const Color(0xFF71b280)], // Forest Wave Green
    [const Color(0xFF8a2387), const Color(0xFFe94057), const Color(0xFFf27121)], // Warm Sunset Orange/Pink
    [const Color(0xFF141e30), const Color(0xFF243b55)], // Royal Navy Slate
  ];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _nameController = TextEditingController();
    _titleController = TextEditingController();
    _companyController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _addressController = TextEditingController();

    _loadCardData();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadCardData() async {
    try {
      final firebaseCard = await _cardService.loadCardData();
      if (firebaseCard != null) {
        setState(() {
          _card = firebaseCard;
          _selectedThemeIndex = _card.cardThemeIndex;
        });
      } else {
        final prefs = await SharedPreferences.getInstance();
        final cardJson = prefs.getString('saved_business_card');
        if (cardJson != null) {
          try {
            setState(() {
              _card = BusinessCardModel.fromJson(json.decode(cardJson));
              _selectedThemeIndex = _card.cardThemeIndex;
            });
          } catch (_) {}
        }
      }
    } catch (e) {
      print('DEBUG: Failed to load card details from Firebase: $e');
      // Fallback to local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        final cardJson = prefs.getString('saved_business_card');
        if (cardJson != null) {
          setState(() {
            _card = BusinessCardModel.fromJson(json.decode(cardJson));
            _selectedThemeIndex = _card.cardThemeIndex;
          });
        }
      } catch (_) {}
    } finally {
      _nameController.text = _card.name;
      _titleController.text = _card.jobTitle;
      _companyController.text = _card.company;
      _phoneController.text = _card.phone;
      _emailController.text = _card.email;
      _websiteController.text = _card.website;
      _addressController.text = _card.address;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveCardData() async {
    if (!_formKey.currentState!.validate()) return;

    Uint8List? pngBytes;
    try {
      // 1. Try capturing card image (optional / fail-safe)
      final RenderRepaintBoundary? boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          pngBytes = byteData.buffer.asUint8List();
        }
      }
    } catch (e) {
      print('DEBUG: RepaintBoundary capture skipped/failed: $e');
    }

    // 2. Start loading state
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedCard = BusinessCardModel(
        name: _nameController.text,
        jobTitle: _titleController.text,
        company: _companyController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        website: _websiteController.text,
        address: _addressController.text,
        cardThemeIndex: _selectedThemeIndex,
        imageUrl: _card.imageUrl,
      );

      // Save fields to Firestore (mandatory)
      await _cardService.saveCardData(updatedCard);
      
      String uploadedUrl = _card.imageUrl;
      String? uploadErrorMsg;
      if (pngBytes != null) {
        try {
          // Upload with 12 second timeout to prevent infinite hangs
          uploadedUrl = await _cardService.uploadCardImage(pngBytes).timeout(const Duration(seconds: 12));
        } catch (uploadError) {
          print('DEBUG: Cloud image upload failed: $uploadError');
          uploadErrorMsg = uploadError.toString();
        }
      }

      final finalCard = BusinessCardModel(
        name: updatedCard.name,
        jobTitle: updatedCard.jobTitle,
        company: updatedCard.company,
        phone: updatedCard.phone,
        email: updatedCard.email,
        website: updatedCard.website,
        address: updatedCard.address,
        cardThemeIndex: updatedCard.cardThemeIndex,
        imageUrl: uploadedUrl,
      );

      setState(() {
        _card = finalCard;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uploadErrorMsg == null 
                ? 'Business Card saved & uploaded to Cloud!' 
                : 'Card details saved locally! (Image upload failed: $uploadErrorMsg)',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: uploadErrorMsg == null ? AppColors.primaryGreen : Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save to cloud: $e', style: GoogleFonts.outfit()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleFlip() {
    if (_showFrontSide) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _showFrontSide = !_showFrontSide;
    });
  }

  void _shareVCard() async {
    if (_card.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill out and save your card details first.', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (kIsWeb) {
      await Share.share(_card.toVCardString(), subject: '${_card.name}\'s Business Card');
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${_card.name.replaceAll(" ", "_")}.vcf');
      await file.writeAsString(_card.toVCardString());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${_card.name}\'s Business Card',
        text: 'Hi, here is my digital business card!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _shareCardAsImage() async {
    if (_card.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill out and save your card details first.', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (kIsWeb) {
      if (_card.imageUrl.isNotEmpty) {
        await Share.share('Hi, check out my digital business card image: ${_card.imageUrl}', subject: '${_card.name}\'s Business Card Image');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please save and upload your card design to the cloud first.', style: GoogleFonts.outfit()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    try {
      final RenderRepaintBoundary boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${_card.name.replaceAll(" ", "_")}_card.png');
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: '${_card.name}\'s Business Card Image',
          text: 'Hi, check out my digital business card!',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export card image: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _saveCardToGallery() async {
    if (_card.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill out and save your card details first.', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final RenderRepaintBoundary boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        
        await Gal.putImageBytes(pngBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Business card image saved to Gallery!', style: GoogleFonts.outfit()),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        }
      } else {
        throw Exception('Failed to generate image bytes.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save to gallery: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showQrCode() {
    if (_card.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill out and save your card details first.', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => QrCodeDialog(
        vCardData: _card.imageUrl.isNotEmpty ? _card.imageUrl : _card.toVCardString(),
        contactName: _card.name,
      ),
    );
  }

  void _showNfcWrite() {
    if (_card.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill out and save your card details first.', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => NfcWriteDialog(
        vCardData: _card.imageUrl.isNotEmpty ? _card.imageUrl : _card.toVCardString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          'Digital Business Card',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.textBlack,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // Visual Flip Card
                  RepaintBoundary(
                    key: _boundaryKey,
                    child: GestureDetector(
                      onTap: _toggleFlip,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final angle = _flipAnimation.value * pi;
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // perspective
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: angle < pi / 2
                                ? _buildCardFront(isDark)
                                : Transform(
                                    transform: Matrix4.identity()..rotateY(pi),
                                    alignment: Alignment.center,
                                    child: _buildCardBack(isDark),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Tap card to flip',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black45,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_isEditing) ...[
                    _buildEditForm(isDark),
                  ] else ...[
                    _buildShareOptions(isDark),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCardFront(bool isDark) {
    final hasData = _card.name.isNotEmpty;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: _cardGradients[_selectedThemeIndex],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.15,
              child: Icon(Icons.wallet_membership_rounded, size: 180, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasData ? _card.company.toUpperCase() : 'COMPANY NAME',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    Icon(Icons.nfc_rounded, color: Colors.white.withOpacity(0.8), size: 24),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasData ? _card.name : 'Your Full Name',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasData ? _card.jobTitle : 'Job Title / Designation',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(bool isDark) {
    final hasData = _card.name.isNotEmpty;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: _cardGradients[_selectedThemeIndex],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -20,
            top: -20,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.qr_code_2_rounded, size: 160, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONTACT DETAILS',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const Icon(Icons.contact_phone_rounded, color: Colors.white, size: 20),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContactRow(Icons.phone_android_rounded, hasData ? _card.phone : '+880 17XXXXXXXX'),
                    const SizedBox(height: 8),
                    _buildContactRow(Icons.email_outlined, hasData ? _card.email : 'you@example.com'),
                    const SizedBox(height: 8),
                    _buildContactRow(Icons.language_rounded, hasData ? _card.website : 'www.yourwebsite.com'),
                    const SizedBox(height: 8),
                    _buildContactRow(Icons.location_on_outlined, hasData ? _card.address : 'City, Bangladesh'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.85)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildShareOptions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Share Options',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textBlack,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildShareButton(
                icon: Icons.qr_code_2_rounded,
                label: 'QR Code',
                color: Colors.deepPurple,
                onTap: _showQrCode,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildShareButton(
                icon: Icons.nfc_rounded,
                label: 'NFC Write',
                color: Colors.teal,
                onTap: _showNfcWrite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildShareButton(
                icon: Icons.share_rounded,
                label: 'Share vCard',
                color: AppColors.primaryGreen,
                onTap: _shareVCard,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildShareButton(
                icon: Icons.image_rounded,
                label: 'Share Image',
                color: Colors.blue,
                onTap: _shareCardAsImage,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildShareButton(
          icon: Icons.download_for_offline_rounded,
          label: 'Save to Gallery',
          color: Colors.orange,
          onTap: _saveCardToGallery,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit Card Details',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),

          // Theme Selector
          Text(
            'Choose Card Template Color:',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _cardGradients.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final isSelected = _selectedThemeIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedThemeIndex = index;
                    });
                  },
                  child: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _cardGradients[index],
                      ),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3.0,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          _buildInputField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _titleController,
            label: 'Job Title / Designation',
            icon: Icons.badge_outlined,
            isDark: isDark,
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _companyController,
            label: 'Company Name',
            icon: Icons.business_outlined,
            isDark: isDark,
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            isDark: isDark,
            keyboardType: TextInputType.phone,
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            isDark: isDark,
            keyboardType: TextInputType.emailAddress,
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _websiteController,
            label: 'Website Link',
            icon: Icons.language_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _addressController,
            label: 'Work Address',
            icon: Icons.location_on_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 28),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saveCardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Save Card Details',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black54),
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        filled: true,
        fillColor: isDark ? const Color(0xFF16201D) : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
      ),
    );
  }
}
