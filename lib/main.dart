import 'package:evo_home_app/screens/forgot_password_screen.dart';
import 'package:evo_home_app/screens/home_screen.dart';
import 'package:evo_home_app/screens/login_screen.dart';
import 'package:evo_home_app/screens/reset_password_screen.dart';
import 'package:evo_home_app/screens/signup_screen.dart';
import 'package:evo_home_app/screens/verify_code_screen.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart';

void main() {
  runApp(const EvoHomeApp());
}

class EvoHomeApp extends StatelessWidget {
  const EvoHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (_) => const SplashScreen(),
        '/intro': (_) => const IntroScreen(),
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/verify-code': (_) => const VerifyCodeScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
      },
    );
  }
}
