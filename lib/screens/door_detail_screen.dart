import 'package:flutter/material.dart';

class DoorDetailScreen extends StatefulWidget {
  const DoorDetailScreen({super.key});

  @override
  State<DoorDetailScreen> createState() => _DoorDetailScreenState();
}

class _DoorDetailScreenState extends State<DoorDetailScreen> {
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final room = args['room'];

    return Scaffold(
      appBar: AppBar(title: const Text('Door Details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room: $room', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("Door Status"),
              value: isOpen,
              onChanged: (value) {
                setState(() => isOpen = value);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: send door update
              },
              child: const Text('Update Door Status'),
            )
          ],
        ),
      ),
    );
  }
}
