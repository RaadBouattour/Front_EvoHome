import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/articles_screen.dart';
import '../screens/stream_screen.dart';
import '../widgets/app_drawer.dart';
import '../services/auth_service.dart';

class MainLayout extends StatefulWidget {
  final int selectedIndex;

  const MainLayout({super.key, required this.selectedIndex});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  String _userFirstName = '';

  final List<Widget> _screens = const [
    HomeScreen(),
    StreamScreen(),
    ArticlesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUserProfile();
    setState(() {
      _userFirstName = user['firstname'] ?? '';
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      drawer: const AppDrawer(),
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(child: _screens[_currentIndex]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      Text(
        'Hi, ${_userFirstName.isNotEmpty ? _userFirstName : 'User'}',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
    ],
  );

  Widget _buildBottomNav() => SizedBox(
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

  Widget _buildNavIcon(IconData icon, int index, {double? left, double? right}) => Positioned(
    bottom: 28,
    left: left,
    right: right,
    child: GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _currentIndex == index ? const Color(0xFFC4D0E8) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _currentIndex == index ? Colors.white : Colors.grey),
      ),
    ),
  );
}
