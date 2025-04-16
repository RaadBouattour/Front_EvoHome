import 'package:flutter/material.dart';

class DeviceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool initialState;

  const DeviceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.initialState = false,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 🔁 TODO: navigate to device detail screen
        Navigator.pushNamed(context, '/device-detail');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isOn ? const Color(0xFF1C1C2E) : const Color(0xFF2E2E42),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, color: isOn ? Colors.yellow : Colors.white38, size: 28),
            const Spacer(),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Text(
              widget.subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Switch(
                value: isOn,
                onChanged: (val) {
                  setState(() => isOn = val);
                },
                activeColor: Colors.yellow,
                inactiveTrackColor: Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
