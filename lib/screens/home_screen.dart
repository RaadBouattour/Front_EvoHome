import 'package:flutter/material.dart';
import '../widgets/environment_card.dart';
import '../widgets/device_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedRoom = 'Living Room';
  int _selectedIndex = 0;

  final List<String> rooms = ['Living Room', 'Bedroom', 'Kitchen'];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
      // TODO: Add navigation if needed between screens
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),

      // Bottom Navigation Bar
      bottomNavigationBar: SizedBox(
        height: 105,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Fond incurvé
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

            // HOME Icone
            Positioned(
              bottom: 28,
              left: 33.62,
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60.94,
                  height: 60.90,
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0 ? const Color(0xFFC4D0E8) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home,
                    color: _selectedIndex == 0 ? Colors.white : Colors.grey,
                    size: _selectedIndex == 0 ? 30 : 24,
                  ),
                ),
              ),
            ),

            // Stream Icone
            Positioned(
              bottom: 28,
              left: MediaQuery.of(context).size.width / 2 - 16,
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1 ? const Color(0xFFC4D0E8) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.stream,
                    color: _selectedIndex == 1 ? Colors.white : Colors.grey,
                    size: _selectedIndex == 1 ? 30 : 24,
                  ),
                ),
              ),
            ),

            // PROFILE Icone
            Positioned(
              bottom: 28,
              right: 30,
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2 ? const Color(0xFFC4D0E8) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: _selectedIndex == 2 ? Colors.white : Colors.grey,
                    size: _selectedIndex == 2 ? 30 : 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),


      // Body
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hi, Drax',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // TODO: handle notification tap
                },
              ),
            ],
          ),
              const SizedBox(height: 16),

              // Room Selector Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: rooms.map((room) {
                  final isSelected = selectedRoom == room;
                  return GestureDetector(
                    onTap: () => setState(() => selectedRoom = room),
                    child: Column(
                      children: [
                        Text(
                          room,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.grey,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 2,
                            width: 40,
                            color: Colors.blueAccent,
                          )
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Environment Info Card
              const EnvironmentCard(),

              const SizedBox(height: 24),

              // Device Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1,
                  children: const [
                    DeviceCard(
                      icon: Icons.lightbulb_outline,
                      title: 'Light',
                      subtitle: 'Philips Hue',
                      initialState: true,
                    ),
                    DeviceCard(
                      icon: Icons.ac_unit,
                      title: 'Air Conditioner',
                      subtitle: 'LG S3',
                      initialState: false,
                    ),
                    DeviceCard(
                      icon: Icons.tv,
                      title: 'Smart TV',
                      subtitle: 'LG AI',
                      initialState: false,
                    ),
                    DeviceCard(
                      icon: Icons.music_note,
                      title: 'Music',
                      subtitle: 'Amazon Echo',
                      initialState: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
