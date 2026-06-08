import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onPasswordToggle;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final bool isFocused;
  final bool? obscureText;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onPasswordToggle,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.isFocused = false,
    this.obscureText,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? AppColors.primaryGreen : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      child: TextField(
        key: ValueKey(hintText),
        controller: controller,
        obscureText: obscureText ?? (isPassword && !isPasswordVisible),
        keyboardType: keyboardType,
        focusNode: focusNode,
        style: GoogleFonts.outfit(color: AppColors.textBlack, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.outfit(color: AppColors.textGrey.withValues(alpha: 0.6)),
          prefixIcon: Icon(icon, color: isFocused ? AppColors.primaryGreen : AppColors.textGrey, size: 22),
          suffixIcon: suffixIcon ?? (isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textGrey,
                  ),
                  onPressed: onPasswordToggle,
                )
              : null),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
