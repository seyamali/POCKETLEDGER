import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/app/routes.dart';
import 'package:pocketledger/services/auth_service.dart';
import 'package:pocketledger/services/security_service.dart';

class LockScreen extends StatefulWidget {
  final bool isCancelable;
  final VoidCallback onSuccess;

  const LockScreen({
    super.key,
    this.isCancelable = false,
    required this.onSuccess,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  final SecurityService _securityService = SecurityService();
  final AuthService _authService = AuthService();
  String _enteredPin = '';
  bool _showBiometricBtn = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 15.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 15.0, end: -15.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -15.0, end: 15.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 15.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final enabled = await _securityService.isBiometricEnabled();
    final hardwareSupport = await _securityService.canAuthenticateWithBiometrics();
    if (enabled && hardwareSupport) {
      setState(() {
        _showBiometricBtn = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateWithBiometrics();
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final success = await _securityService.authenticateWithBiometrics();
    if (success) {
      widget.onSuccess();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyTap(String value) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += value;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    // Wait briefly for the 4th dot filling animation to display
    await Future.delayed(const Duration(milliseconds: 150));
    final isValid = await _securityService.verifyPin(_enteredPin);
    if (isValid) {
      widget.onSuccess();
    } else {
      HapticFeedback.vibrate();
      _shakeController.forward(from: 0.0);
      setState(() {
        _enteredPin = '';
      });
    }
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Text(
          'Forgot Security PIN?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textBlack),
        ),
        content: Text(
          'To protect your personal ledger, you must sign out of your account and log back in with your password to disable or reset your PIN code.',
          style: GoogleFonts.outfit(color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: AppColors.textGrey, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await _authService.signOut();
              AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Confirm Sign Out',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Frosted background blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen.withValues(alpha: 0.92),
                      const Color(0xFF032219).withValues(alpha: 0.96),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top close action if cancelable
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      if (widget.isCancelable)
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          ),
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Lock Header & Visuals
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.accentGold,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'App Locked',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your 4-digit security PIN',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Dot indicators with shake animation
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final isActive = index < _enteredPin.length;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                width: isActive ? 20 : 16,
                                height: isActive ? 20 : 16,
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.accentGold : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isActive ? AppColors.accentGold : Colors.white.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: AppColors.accentGold.withValues(alpha: 0.5),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : [],
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Keypad Layout
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildKeypadBtn('1'),
                              _buildKeypadBtn('2'),
                              _buildKeypadBtn('3'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildKeypadBtn('4'),
                              _buildKeypadBtn('5'),
                              _buildKeypadBtn('6'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildKeypadBtn('7'),
                              _buildKeypadBtn('8'),
                              _buildKeypadBtn('9'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _showBiometricBtn
                                  ? SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: IconButton(
                                        onPressed: _authenticateWithBiometrics,
                                        icon: const Icon(
                                          Icons.fingerprint_rounded,
                                          color: Colors.white70,
                                          size: 32,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(width: 70, height: 70),
                              _buildKeypadBtn('0'),
                              SizedBox(
                                width: 70,
                                height: 70,
                                child: IconButton(
                                  onPressed: _onBackspace,
                                  icon: const Icon(
                                    Icons.backspace_outlined,
                                    color: Colors.white70,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: _showForgotPinDialog,
                      child: Text(
                        'Forgot Security PIN?',
                        style: GoogleFonts.outfit(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadBtn(String value) {
    return GestureDetector(
      onTap: () => _onKeyTap(value),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
