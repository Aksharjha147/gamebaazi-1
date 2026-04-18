import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/colors.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      
      if (mounted) {
        _navigateToHome();
      }
    } catch (e) {
      debugPrint("ERROR DURING GOOGLE SIGN IN: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Sign-in failed. Please ensure you have added your SHA-1 to Firebase.');
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppColors.neonGlow(AppColors.primary),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: AppColors.background, size: 64),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'GAMEBAAZI',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            fontSize: 38,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'PREMIUM BETTING EXPERIENCE',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                  
                  // Action Section
                  const Text(
                    'Welcome',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The fastest and most secure way to play. Sign in with your Google account to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 48),
                  
                  // Single Unified Auth Button
                  _buildGoogleButton(),
                  
                  const SizedBox(height: 60),
                  
                  // Footer
                  Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted.withOpacity(0.5), fontSize: 10),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _handleGoogleSignIn,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.glowPrimary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.network(
                  'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                  height: 18,
                  width: 18,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.g_mobiledata,
                    color: Colors.blue,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'CONTINUE WITH GOOGLE',
                  style: TextStyle(
                    color: AppColors.background,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
