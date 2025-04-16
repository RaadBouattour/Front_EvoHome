import 'package:flutter/material.dart';
import '../widgets/loading_spinner.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showFullLogo = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _showFullLogo = true;
      });
    });

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/intro');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              child: _showFullLogo
                  ? Image.asset(
                'assets/images/evo_logo_full.png',
                key: const ValueKey('full'),
                width: 350
              )
                  : Image.asset(
                'assets/images/evo_logo_part.png',
                key: const ValueKey('part'),
                width: 350,
              ),
            ),

            const SizedBox(height: 24),

            const LoadingSpinner(),
          ],
        ),
      ),
    );
  }
}
