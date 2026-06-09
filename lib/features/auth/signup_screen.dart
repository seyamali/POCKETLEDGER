import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/services/auth_service.dart';
import 'package:pocketledger/features/auth/widgets/custom_text_field.dart';
import 'package:pocketledger/app/theme.dart';

class SignupScreen extends StatefulWidget {
   const SignupScreen({super.key});
 
   @override
   State<SignupScreen> createState() => _SignupScreenState();
}
 
class _SignupScreenState extends State<SignupScreen> {
   final AuthService _authService = AuthService();
   final TextEditingController _nameController = TextEditingController();
   final TextEditingController _emailController = TextEditingController();
   final TextEditingController _passwordController = TextEditingController();
   final TextEditingController _confirmPasswordController = TextEditingController();
   bool _isLoading = false;
   bool _isPasswordVisible = false;
 
   final FocusNode _nameFocus = FocusNode();
   final FocusNode _emailFocus = FocusNode();
   final FocusNode _passwordFocus = FocusNode();
   final FocusNode _confirmFocus = FocusNode();
 
   void _handleSignup() async {
     if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Please fill all fields')),
       );
       return;
     }
 
     if (_passwordController.text != _confirmPasswordController.text) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Passwords do not match')),
       );
       return;
     }
 
     setState(() => _isLoading = true);
     try {
       await _authService.signUp(
         email: _emailController.text, 
         password: _passwordController.text,
         name: _nameController.text,
       );
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
     return ThemeBuilder(
       builder: (context) => Scaffold(
         backgroundColor: AppColors.background,
         body: SafeArea(
           child: SingleChildScrollView(
             padding: const EdgeInsets.all(24.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const SizedBox(height: 30),
                 IconButton(
                   icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textBlack),
                   onPressed: () => Navigator.pop(context),
                 ),
                 const SizedBox(height: 20),
                 Text(
                   'Create Account',
                   style: GoogleFonts.outfit(
                     color: AppColors.textBlack,
                     fontSize: 32,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
                 Text(
                   'Start your journey to financial freedom',
                   style: GoogleFonts.outfit(
                     color: AppColors.textGrey,
                     fontSize: 16,
                   ),
                 ),
                 const SizedBox(height: 32),
                 
                 Container(
                   padding: const EdgeInsets.all(24),
                   decoration: BoxDecoration(
                     color: AppColors.cardWhite,
                     borderRadius: BorderRadius.circular(24),
                     border: Border.all(color: AppColors.borderLight),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withValues(alpha: 0.02),
                         blurRadius: 10,
                         offset: const Offset(0, 5),
                       ),
                     ],
                   ),
                   child: Column(
                     children: [
                       ListenableBuilder(
                         listenable: _nameFocus,
                         builder: (context, child) => CustomTextField(
                           controller: _nameController,
                           hintText: 'Full Name',
                           icon: Icons.person_outline,
                           focusNode: _nameFocus,
                           isFocused: _nameFocus.hasFocus,
                         ),
                       ),
                       const SizedBox(height: 20),
                       ListenableBuilder(
                         listenable: _emailFocus,
                         builder: (context, child) => CustomTextField(
                           controller: _emailController,
                           hintText: 'Email Address',
                           icon: Icons.email_outlined,
                           keyboardType: TextInputType.emailAddress,
                           focusNode: _emailFocus,
                           isFocused: _emailFocus.hasFocus,
                         ),
                       ),
                       const SizedBox(height: 20),
                       ListenableBuilder(
                         listenable: _passwordFocus,
                         builder: (context, child) => CustomTextField(
                           controller: _passwordController,
                           hintText: 'Password',
                           icon: Icons.lock_outline,
                           obscureText: !_isPasswordVisible,
                           focusNode: _passwordFocus,
                           isFocused: _passwordFocus.hasFocus,
                           suffixIcon: IconButton(
                             icon: Icon(
                               _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                               color: AppColors.textGrey,
                               size: 20,
                             ),
                             onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                           ),
                         ),
                       ),
                       const SizedBox(height: 20),
                       ListenableBuilder(
                         listenable: _confirmFocus,
                         builder: (context, child) => CustomTextField(
                           controller: _confirmPasswordController,
                           hintText: 'Confirm Password',
                           icon: Icons.lock_reset_outlined,
                           obscureText: true,
                           focusNode: _confirmFocus,
                           isFocused: _confirmFocus.hasFocus,
                         ),
                       ),
                       const SizedBox(height: 32),
                       SizedBox(
                         width: double.infinity,
                         height: 56,
                         child: ElevatedButton(
                           onPressed: _isLoading ? null : _handleSignup,
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppColors.primaryGreen,
                             foregroundColor: Colors.white,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                             elevation: 0,
                           ),
                           child: _isLoading 
                             ? const CircularProgressIndicator(color: Colors.white)
                             : Text(
                                 'Create Account',
                                 style: GoogleFonts.outfit(
                                   fontWeight: FontWeight.bold,
                                   fontSize: 16,
                                 ),
                               ),
                         ),
                       ),
                     ],
                   ),
                 ),
                 
                 const SizedBox(height: 32),
                 Center(
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Text("Already have an account? ", style: GoogleFonts.outfit(color: AppColors.textGrey)),
                       GestureDetector(
                         onTap: () => Navigator.pop(context),
                         child: Text(
                           'Sign In',
                           style: GoogleFonts.outfit(
                             color: AppColors.primaryGreen,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 40),
               ],
             ),
           ),
         ),
       ),
     );
   }
}
