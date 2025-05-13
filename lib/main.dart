import 'package:evo_home_app/screens/DeviceDetailScreen.dart';
import 'package:evo_home_app/screens/articles_screen.dart';
import 'package:evo_home_app/screens/door_detail_screen.dart';
import 'package:evo_home_app/screens/fan_detail_screen.dart';
import 'package:evo_home_app/screens/forgot_password_screen.dart';
import 'package:evo_home_app/screens/home_screen.dart';
import 'package:evo_home_app/screens/light_detail_screen.dart';
import 'package:evo_home_app/screens/login_screen.dart';
import 'package:evo_home_app/screens/reset_password_screen.dart';
import 'package:evo_home_app/screens/signup_screen.dart';
import 'package:evo_home_app/screens/stream_screen.dart';
import 'package:evo_home_app/screens/verify_code_screen.dart';
import 'package:evo_home_app/widgets/app_drawer.dart';
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart';
import 'services/auth_service.dart';

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
        '/home': (_) => const MainScaffold(index: 0),
        '/stream': (_) => const MainScaffold(index: 1),
        '/articles': (_) => const MainScaffold(index: 2),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/verify-code': (_) => const VerifyCodeScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/light-detail': (_) => const LightDetailScreen(),
        '/fan-detail': (_) => const FanDetailScreen(),
        '/door-detail': (_) => const DoorDetailScreen(),
      },
    );
  }
}

// ✅ Scaffold wrapper to keep nav bar and drawer fixed across main sections
class MainScaffold extends StatefulWidget {
  final int index;
  const MainScaffold({super.key, required this.index});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int currentIndex = 0;
  String userFirstName = '';

  final screens = const [
    HomeScreen(),
    StreamScreen(),
    ArticlesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.index;
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await AuthService.getUserProfile();
      setState(() {
        userFirstName = user['firstname'] ?? '';
      });
    } catch (e) {
      debugPrint("Failed to load user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // 🔷 Header (Hi, user + Notification)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  Text(
                    'Hi, ${userFirstName.isNotEmpty ? userFirstName : 'User'}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 🔷 Active Screen
            Expanded(child: screens[currentIndex]),
          ],
        ),
      ),
      // 🔷 Fixed Bottom Nav Bar
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return SizedBox(
      height: 105,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 84,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.58),
                  topRight: Radius.circular(8.58),
                  bottomLeft: Radius.circular(32.16),
                  bottomRight: Radius.circular(32.16),
                ),
              ),
            ),
          ),
          _buildNavIcon(Icons.home, 0, left: 33.62),
          _buildNavIcon(Icons.stream, 1, left: MediaQuery.of(context).size.width / 2 - 16),
          _buildNavIcon(Icons.article, 2, right: 30),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, {double? left, double? right}) {
    return Positioned(
      bottom: 28,
      left: left,
      right: right,
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: currentIndex == index ? const Color(0xFFC4D0E8) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: currentIndex == index ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
