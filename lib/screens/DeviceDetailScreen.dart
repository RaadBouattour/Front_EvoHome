import 'package:flutter/material.dart';

class DeviceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${device['type']} - ${device['room']}")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Device Controls", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("ID: ${device['id']}"),
            Text("Type: ${device['type']}"),
            Text("Room: ${device['room']}"),
            // Add more controls like brightness sliders, schedule pickers, etc.
          ],
        ),
      ),
    );
  }
}
