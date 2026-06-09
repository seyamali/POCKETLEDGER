import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/services/auth_service.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketledger/core/localization/app_localizations.dart';
import 'package:pocketledger/services/language_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  void _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('remember_email') ?? '';
      _passwordController.text = prefs.getString('remember_password') ?? '';
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remember_email', _emailController.text);
        await prefs.setString('remember_password', _passwordController.text);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('remember_email');
        await prefs.remove('remember_password');
        await prefs.setBool('remember_me', false);
      }

      await _authService.signIn(_emailController.text, _passwordController.text);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService().languageNotifier,
      builder: (context, lang, _) {
        return ThemeBuilder(
          builder: (context) => Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textBlack),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            _buildLanguageToggle(),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(child: Image.asset('assets/images/logo.png', height: 60)),
                const SizedBox(height: 40),
                Text(
                  AppLocalizations.get('welcome_back'),
                  style: GoogleFonts.outfit(
                    color: AppColors.textBlack,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.get('login_subtitle'),
                  style: GoogleFonts.outfit(
                    color: AppColors.textGrey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                
                Text(
                  AppLocalizations.get('email'),
                  style: GoogleFonts.outfit(
                    color: AppColors.textBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _emailController,
                  hint: AppLocalizations.get('email_hint'),
                  icon: Icons.email_outlined,
                  focusNode: _emailFocus,
                  isFocused: _emailFocus.hasFocus,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                
                Text(
                  AppLocalizations.get('password'),
                  style: GoogleFonts.outfit(
                    color: AppColors.textBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _passwordController,
                  hint: AppLocalizations.get('password_hint'),
                  icon: Icons.lock_outline,
                  focusNode: _passwordFocus,
                  isFocused: _passwordFocus.hasFocus,
                  isPassword: true,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textGrey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 24, width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: AppColors.primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember Me',
                            style: GoogleFonts.outfit(
                              color: AppColors.textBlack,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Forgot Password?',
                      style: GoogleFonts.outfit(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            AppLocalizations.get('sign_in'),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.get('no_account'),
                      style: GoogleFonts.outfit(color: AppColors.textGrey),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      child: Text(
                        AppLocalizations.get('sign_up_now'),
                        style: GoogleFonts.outfit(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    required bool isFocused,
    bool isPassword = false,
    bool? obscureText,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return CustomTextField(
      controller: controller,
      hintText: hint,
      icon: icon,
      focusNode: focusNode,
      isFocused: isFocused,
      obscureText: obscureText,
      suffixIcon: suffixIcon,
      keyboardType: keyboardType ?? TextInputType.text,
    );
  }

  Widget _buildLanguageToggle() {
    final bool isBengali = LanguageService().isBengali;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => LanguageService().setLanguage('en'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: !isBengali ? AppColors.primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Eng',
                style: GoogleFonts.outfit(
                  color: !isBengali ? Colors.white : AppColors.textGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => LanguageService().setLanguage('bn'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isBengali ? AppColors.primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'বাং',
                style: GoogleFonts.outfit(
                  color: isBengali ? Colors.white : AppColors.textGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
