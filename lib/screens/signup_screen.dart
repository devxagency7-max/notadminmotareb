import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/auth_service.dart';
import '../utils/custom_snackbar.dart';
import '../utils/error_handler.dart';
import 'package:provider/provider.dart';
import '../features/auth/providers/auth_provider.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isPasswordVisible = false;
  bool _isOwner = false; // false = Seeker (Default), true = Owner
  bool _isConfirmPasswordVisible = false;
  bool _acceptedTerms = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_acceptedTerms) {
      CustomSnackBar.show(
        context: context,
        message: 'يرجى الموافقة على الشروط والأحكام للمتابعة',
        isError: true,
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      CustomSnackBar.show(
        context: context,
        message: 'كلمات المرور غير متطابقة',
        isError: true,
      );
      return;
    }

    try {
      await context.read<AuthProvider>().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        isOwner: _isOwner,
      );

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'تم إنشاء الحساب بنجاح! مرحباً بك',
          isError: false,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarAction? action;
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          action = SnackBarAction(
            label: 'تسجيل الدخول',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pop(context); // Go back to Login Screen
            },
          );
        }

        CustomSnackBar.show(
          context: context,
          message: ErrorHandler.getMessage(e),
          isError: true,
          action: action,
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await context.read<AuthProvider>().signInWithGoogle();
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        CustomSnackBar.show(
          context: context,
          message: 'تم تسجيل الدخول بجوجل بنجاح!',
          isError: false,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: ErrorHandler.getMessage(e),
          isError: true,
        );
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      await context.read<AuthProvider>().signInWithFacebook();
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        CustomSnackBar.show(
          context: context,
          message: 'تم تسجيل الدخول بفيسبوك بنجاح!',
          isError: false,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: ErrorHandler.getMessage(e),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scrollable Layout as requested
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true, // Allow background to go behind AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.teal),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background: Light Green Semi-Circle Top-Right
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE0F2F1).withOpacity(0.8),
              ),
            ),
          ),
          // Background: Light Green Semi-Circle Bottom-Left
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE0F2F1).withOpacity(0.8),
              ),
            ),
          ),
          // Blur Effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.white.withOpacity(0.0)),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  FadeInDown(
                    duration: const Duration(seconds: 1),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 120, // Adjusted size
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ).createShader(bounds),
                      child: Text(
                        'إنشاء حساب جديد',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInDown(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'أدخل بياناتك للبدء في البحث عن سكنك المثالي',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Form
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Type Toggle (Sliding Animation)
                        Container(
                          height: 55,
                          padding: const EdgeInsets.all(4),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Stack(
                            children: [
                              // 1. Sliding Background
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                alignment: !_isOwner
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: Container(
                                  width:
                                      (MediaQuery.of(context).size.width - 96) /
                                      2, // Width adjusted for padding
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // 2. Buttons Row
                              Row(
                                children: [
                                  // Seeker Option
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _isOwner = false),
                                      behavior: HitTestBehavior.opaque,
                                      child: Center(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            fontSize: !_isOwner ? 16 : 14,
                                            color: !_isOwner
                                                ? const Color(0xFF008695)
                                                : Colors.grey,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.person_search_outlined,
                                                size: !_isOwner ? 22 : 18,
                                                color: !_isOwner
                                                    ? const Color(0xFF008695)
                                                    : Colors.grey,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text('عايز سكن'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Owner Option
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _isOwner = true),
                                      behavior: HitTestBehavior.opaque,
                                      child: Center(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            fontSize: _isOwner ? 16 : 14,
                                            color: _isOwner
                                                ? const Color(0xFF39BB5E)
                                                : Colors.grey,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.apartment_rounded,
                                                size: _isOwner ? 22 : 18,
                                                color: _isOwner
                                                    ? const Color(0xFF39BB5E)
                                                    : Colors.grey,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text('صاحب شقة'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        _buildLabel('الاسم الكامل'),
                        TextField(
                          controller: _nameController,
                          decoration: _inputDecoration(
                            'أحمد محمد',
                            Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('البريد الإلكتروني'),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            'example@domain.com',
                            Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('كلمة المرور'),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _inputDecoration(
                            '........',
                            Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('تأكيد كلمة المرور'),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: _inputDecoration(
                            '........',
                            Icons.verified_user_outlined,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                () => _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Terms
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          activeColor: Colors.teal,
                          onChanged: (val) =>
                              setState(() => _acceptedTerms = val!),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.cairo(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                              children: const [
                                TextSpan(text: 'أوافق على '),
                                TextSpan(
                                  text: 'الشروط والأحكام',
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: ' و '),
                                TextSpan(
                                  text: 'سياسة الخصوصية',
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF008695).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Selector<AuthProvider, bool>(
                        selector: (context, auth) => auth.isLoading,
                        builder: (context, isLoading, child) {
                          return ElevatedButton(
                            onPressed: isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'إنشاء الحساب',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Google Sign In Button
                  _buildGoogleButton(),

                  const SizedBox(height: 15),

                  // Facebook Sign In Button
                  _buildFacebookButton(),

                  const SizedBox(height: 20),

                  // Back to Login
                  FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('لديك حساب بالفعل؟'),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Go back to Login
                          },
                          child: const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return FadeInUp(
      delay: const Duration(milliseconds: 700),
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: _signInWithGoogle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/google.png', height: 24, width: 24),
                const SizedBox(width: 15),
                Text(
                  'التسجيل بـ Google',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacebookButton() {
    return FadeInUp(
      delay: const Duration(milliseconds: 750),
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF1877F2), // Facebook Blue
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1877F2).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: _signInWithFacebook,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FontAwesomeIcons.facebook,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 15),
                Text(
                  'التسجيل بـ Facebook',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF004D40),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.teal),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[50], // Light grey background
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  // Widget _socialButton(IconData icon, String label) { ... } // Removed
}
