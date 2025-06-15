import 'package:flutter/material.dart';

class DeviceCard extends StatefulWidget {
  final IconData icon;
  final String name;
  final String model;
  final bool initialState;
  final Future<void> Function(bool)? onToggle;
  final VoidCallback? onTap;

  const DeviceCard({
    super.key,
    required this.icon,
    required this.name,
    required this.model,
    this.initialState = false,
    this.onToggle,
    this.onTap,
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
    return SizedBox( // 👈 constrain box size here
      width: 140,     // adjust width as needed
      height: 160,    // adjust height as needed
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOn ? const Color(0xFF1C1C2E) : const Color(0xFF2E2E42),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.icon, color: isOn ? Colors.yellow : Colors.white38, size: 32),
              const Spacer(),
              Text(
                widget.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.model,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Switch(
                  value: isOn,
                  onChanged: (val) async {
                    setState(() => isOn = val);
                    if (widget.onToggle != null) {
                      await widget.onToggle!(val);
                    }
                  },
                  activeColor: Colors.yellow,
                  inactiveTrackColor: Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
