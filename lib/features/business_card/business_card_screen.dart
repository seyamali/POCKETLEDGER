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
import 'package:pocketledger/core/widgets/scale_on_tap.dart';
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
  final _exportBoundaryKey = GlobalKey();
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
    [const Color(0xFF1E1E24), const Color(0xFF2E2E38), const Color(0xFF1E1E24)], // Midnight Obsidian (Slate/Gold Theme)
    [const Color(0xFF0D3E2F), const Color(0xFF186851), const Color(0xFF0D3E2F)], // Royal Emerald (Green/Gold Theme)
    [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)], // Deep Sapphire (Classic Blue Theme)
    [const Color(0xFFE2B4AC), const Color(0xFFC5958E), const Color(0xFF9E6D67)], // Frosted Champagne (Rose Gold Theme)
    [const Color(0xFF8A2387), const Color(0xFFE94057), const Color(0xFFF27121)], // Sunset Gold (Vibrant Orange Theme)
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

    // 1. Start loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Prepare the updated card model with new input values
      final updatedCard = BusinessCardModel(
        name: _nameController.text,
        jobTitle: _titleController.text,
        company: _companyController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        website: _websiteController.text,
        address: _addressController.text,
        cardThemeIndex: _selectedThemeIndex,
        imageUrl: _card.imageUrl, // keeps old URL temporarily
      );

      // Update the local state so the widget tree redraws with the new text fields
      setState(() {
        _card = updatedCard;
      });

      // 3. Wait for the widgets to rebuild and paint with the new values
      await WidgetsBinding.instance.endOfFrame;

      // 4. Capture the newly updated visual card layout (Front & Back combined)
      Uint8List? pngBytes;
      try {
        final RenderRepaintBoundary? boundary = _exportBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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

      // 5. Upload the captured card image to Cloudinary
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

      // 6. Save final card data (text + new imageUrl) to Firestore & local SharedPreferences
      await _cardService.saveCardData(finalCard);
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_business_card', json.encode(finalCard.toJson()));
      } catch (e) {
        print('DEBUG: Failed to save card to SharedPreferences: $e');
      }

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
            content: Text('Failed to save: $e', style: GoogleFonts.outfit()),
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
      final RenderRepaintBoundary boundary = _exportBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
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
      final RenderRepaintBoundary boundary = _exportBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
                child: GlassCard(
                  borderRadius: 16,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isEditing ? Icons.close : Icons.edit_rounded,
                          color: AppColors.primaryGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isEditing ? 'Cancel' : 'Edit',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Hidden combined card layout for high-quality exporting (both Front & Back)
          // Rendered underneath the background cover so it is 100% painted but invisible to the user.
          RepaintBoundary(
            key: _exportBoundaryKey,
            child: Container(
              width: 382, // Width of card (350) + 32 transparent padding
              color: Colors.transparent,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCardFront(isDark),
                  const SizedBox(height: 16),
                  _buildCardBack(isDark),
                ],
              ),
            ),
          ),
          // Background cover to hide the export layout
          Positioned.fill(
            child: Container(
              color: AppColors.pageBackground,
            ),
          ),
          // Background ambient glowing circles
          Positioned(
            top: -20, right: -40,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.08 : 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 150, left: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: isDark ? 0.06 : 0.04),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
          _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
        ],
      ),
    );
  }

  Widget _buildCardFront(bool isDark) {
    final hasData = _card.name.isNotEmpty;
    final isGoldTheme = _selectedThemeIndex == 0 || _selectedThemeIndex == 1;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: _cardGradients[_selectedThemeIndex],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Geometric Luxury Overlay Lines & Curves
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isGoldTheme ? const Color(0xFFFFD700) : Colors.white).withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isGoldTheme ? const Color(0xFFFFD700) : Colors.white).withValues(alpha: 0.12),
                  width: 1.0,
                ),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Opacity(
              opacity: 0.04,
              child: Icon(Icons.qr_code_2_rounded, size: 200, color: isGoldTheme ? const Color(0xFFFFD700) : Colors.white),
            ),
          ),
          // Front Side Content Layout
          Padding(
            padding: const EdgeInsets.all(26.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isGoldTheme ? const Color(0xFFFFD700) : Colors.white).withValues(alpha: 0.12),
                            border: Border.all(
                              color: (isGoldTheme ? const Color(0xFFFFD700) : Colors.white).withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: isGoldTheme ? const Color(0xFFFFD700) : Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasData ? _card.company.toUpperCase() : 'COMPANY NAME',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.bold,
                            color: isGoldTheme ? const Color(0xFFFFD700) : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.nfc_rounded,
                      color: (isGoldTheme ? const Color(0xFFFFD700) : Colors.white).withValues(alpha: 0.8),
                      size: 22,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasData ? _card.name : 'Your Full Name',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 1.5,
                          color: isGoldTheme ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasData ? _card.jobTitle.toUpperCase() : 'JOB TITLE / DESIGNATION',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                            color: (isGoldTheme ? const Color(0xFFFFD700) : Colors.white).withValues(alpha: 0.75),
                          ),
                        ),
                      ],
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
    final isGoldTheme = _selectedThemeIndex == 0 || _selectedThemeIndex == 1;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: _cardGradients[_selectedThemeIndex],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background graphic elements
          Positioned(
            left: -50,
            bottom: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isGoldTheme ? const Color(0xFFFFD700) : Colors.white).withValues(alpha: 0.06),
                  width: 1.0,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // Left Column: Modern Emblem/Logo container
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (isGoldTheme ? const Color(0xFFFFD700) : Colors.white).withValues(alpha: 0.25),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          color: isGoldTheme ? const Color(0xFFFFD700) : Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          hasData ? _getMonikerName(_card.name) : 'SHARE',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        'CONTACT INFO',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: (isGoldTheme ? const Color(0xFFFFD700) : Colors.white).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Vertical divider line
                Container(
                  width: 1,
                  height: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: (isGoldTheme ? const Color(0xFFFFD700) : Colors.white).withValues(alpha: 0.15),
                ),
                // Right Column: Contact Details Rows
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildContactRow(Icons.phone_iphone_rounded, hasData ? _card.phone : '+880 17XXXXXXXX', isGoldTheme),
                      const SizedBox(height: 10),
                      _buildContactRow(Icons.email_outlined, hasData ? _card.email : 'you@example.com', isGoldTheme),
                      const SizedBox(height: 10),
                      _buildContactRow(Icons.language_rounded, hasData ? _card.website : 'www.yourwebsite.com', isGoldTheme),
                      const SizedBox(height: 10),
                      _buildContactRow(Icons.location_on_outlined, hasData ? _card.address : 'City, Bangladesh', isGoldTheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonikerName(String name) {
    if (name.isEmpty) return 'CONTACT';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      final firstLower = parts[0].toLowerCase();
      if (firstLower == 'md' || firstLower == 'md.' || firstLower == 'mr' || firstLower == 'mr.' || firstLower == 'ms' || firstLower == 'ms.' || firstLower == 'dr' || firstLower == 'dr.') {
        return '${parts[0]} ${parts[1]}';
      }
    }
    return parts[0];
  }

  Widget _buildContactRow(IconData icon, String value, bool isGoldTheme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: isGoldTheme ? const Color(0xFFFFD700).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getThemeHighlightColor() {
    switch (_selectedThemeIndex) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFF00E676); // Emerald Green
      case 2:
        return const Color(0xFF00B0FF); // Sapphire Blue
      case 3:
        return const Color(0xFFE2B4AC); // Rose Gold / Champagne
      case 4:
        return const Color(0xFFF27121); // Sunset Gold
      default:
        return AppColors.primaryGreen;
    }
  }

  Widget _buildShareOptions(bool isDark) {
    final highlightColor = _getThemeHighlightColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SHARE & EXPORT',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.25,
          children: [
            _buildShareGridItem(
              icon: Icons.qr_code_2_rounded,
              title: 'QR Code',
              subtitle: 'Scan contact info',
              gradientColors: [Colors.deepPurple, Colors.indigo],
              onTap: _showQrCode,
              isDark: isDark,
            ),
            _buildShareGridItem(
              icon: Icons.nfc_rounded,
              title: 'NFC Write',
              subtitle: 'Write to NFC Tag',
              gradientColors: [Colors.teal, const Color(0xFF00E676)],
              onTap: _showNfcWrite,
              isDark: isDark,
            ),
            _buildShareGridItem(
              icon: Icons.share_rounded,
              title: 'Share vCard',
              subtitle: 'Send contact file',
              gradientColors: [AppColors.primaryGreen, Colors.teal],
              onTap: _shareVCard,
              isDark: isDark,
            ),
            _buildShareGridItem(
              icon: Icons.image_rounded,
              title: 'Share Image',
              subtitle: 'Export card image',
              gradientColors: [Colors.blue, Colors.lightBlueAccent],
              onTap: _shareCardAsImage,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildShareLargeItem(
          icon: Icons.download_for_offline_rounded,
          title: 'Save to Device Gallery',
          subtitle: 'Store your luxury business card image locally in high quality',
          gradientColors: [const Color(0xFFFF9100), const Color(0xFFFF3D00)],
          onTap: _saveCardToGallery,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildShareGridItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : AppColors.borderLight,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 20, color: Colors.white),
                ),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareLargeItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : AppColors.borderLight,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white60 : Colors.black45,
                size: 20,
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16201D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12.5),
          prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
