import 'package:flutter/material.dart';

class CreateHomeScreen extends StatefulWidget {
  const CreateHomeScreen({super.key});

  @override
  State<CreateHomeScreen> createState() => _CreateHomeScreenState();
}

class _CreateHomeScreenState extends State<CreateHomeScreen> {
  final Map<String, RoomConfig> _rooms = {
    'Living Room': RoomConfig(roomType: 'Living Room'),
    'Bedroom': RoomConfig(roomType: 'Bedroom'),
    'Kitchen': RoomConfig(roomType: 'Kitchen'),
    'Garden': RoomConfig(roomType: 'Garden'),
  };

  final List<String> devices = [
    'Light',
    'Fan',
    'Door',
    'TV',
    'Mic',
    'Speaker',
    'MQ2 Gas Sensor',
    'Flame Sensor',
    'DHT11 (Temp/Humidity)',
    'PIR Motion Sensor',
  ];

  void _showDeviceSelector(String roomType) async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        final tempSelected = [..._rooms[roomType]!.devices];
        return AlertDialog(
          title: Text('Select devices for $roomType'),
          content: SingleChildScrollView(
            child: Column(
              children: devices
                  .map((device) => CheckboxListTile(
                title: Text(device),
                value: tempSelected.contains(device),
                onChanged: (value) {
                  setState(() {
                    value!
                        ? tempSelected.add(device)
                        : tempSelected.remove(device);
                  });
                },
              ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, tempSelected),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      setState(() {
        _rooms[roomType]!.devices = selected;
      });
    }
  }

  void _createHome() {
    // You can print the home configuration here
    for (var room in _rooms.values) {
      if (room.count > 0) {
        print("🧱 ${room.roomType} x${room.count}: ${room.devices.join(', ')}");
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🏠 Home created (frontend only)!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create a Home")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Select Room Types & Count",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._rooms.keys.map((room) {
              final roomConfig = _rooms[room]!;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room, style: const TextStyle(fontSize: 18)),
                      Row(
                        children: [
                          const Text("Number: "),
                          IconButton(
                              onPressed: () {
                                if (roomConfig.count > 0) {
                                  setState(() => roomConfig.count--);
                                }
                              },
                              icon: const Icon(Icons.remove)),
                          Text(roomConfig.count.toString()),
                          IconButton(
                              onPressed: () =>
                                  setState(() => roomConfig.count++),
                              icon: const Icon(Icons.add)),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () => _showDeviceSelector(room),
                            child: const Text("Configure Devices"),
                          ),
                        ],
                      ),
                      if (roomConfig.devices.isNotEmpty)
                        Wrap(
                          children: roomConfig.devices
                              .map((e) => Chip(label: Text(e)))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _createHome,
              icon: const Icon(Icons.check),
              label: const Text("Create Home"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.blueAccent,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class RoomConfig {
  final String roomType;
  int count;
  List<String> devices;

  RoomConfig({required this.roomType, this.count = 0, this.devices = const []});
}
