import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../widgets/environment_card.dart';
import '../widgets/device_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedRoom = '';
  List<String> roomNames = [];
  Map<String, List<Map<String, dynamic>>> devicesByRoom = {};
  Map<String, bool> deviceStates = {};
  Map<String, dynamic> environmentData = {};

  final Map<String, List<String>> roomSensors = {
    'living room': ['DHT11'],
    'kitchen': ['DHT11', 'MQ2', 'Flame Sensor'],
    'bedroom': ['DHT11'],
  };

  @override
  void initState() {
    super.initState();
    _fetchDeviceData();
  }

  Future<void> _fetchDeviceData() async {
    final url = Uri.parse('http://localhost:5000/api/devices/grouped-by-room');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final rooms = jsonData.keys.toList();

        final Map<String, List<Map<String, dynamic>>> mappedDevices = {};
        final Map<String, bool> states = {};

        print('✅ Rooms found: $rooms');

        for (var room in rooms) {
          final List<dynamic> deviceList = jsonData[room];
          print('📦 Devices in room "$room":');

          mappedDevices[room] = deviceList.map((e) {
            final device = e as Map<String, dynamic>;
            final id = device['id'].toString(); // ✅ convert to string
            final type = device['type'];
            final status = device['status'] ?? device['state'] ?? false;

            print('🔹 $type → ID: $id → Status: $status');
            states[id] = status;
            return device..['id'] = id;
          }).toList();
        }

        setState(() {
          roomNames = rooms;
          selectedRoom = rooms.isNotEmpty ? rooms.first : '';
          devicesByRoom = mappedDevices;
          deviceStates = states;
        });

        print('✅ deviceStates map: $deviceStates');

        _fetchEnvironmentData();
      } else {
        throw Exception('Failed to load device data');
      }
    } catch (e) {
      print('❌ Error fetching device data: $e');
    }
  }

  Future<void> _fetchEnvironmentData() async {
    try {
      print('🔄 Fetching sensor data for $selectedRoom');
      final sensorList = await ApiService.getSensorData();
      print('✅ Sensor List Fetched: ${sensorList.length} items');

      final allowed = roomSensors[selectedRoom.toLowerCase()] ?? [];
      final allowedNormalized = allowed.map((e) => e.toLowerCase().replaceAll(' ', '')).toList();
      print('📌 Allowed sensors for $selectedRoom → $allowedNormalized');

      final Map<String, dynamic> result = {};

      for (var sensor in sensorList) {
        final rawType = sensor['sensorType'] ?? '';
        final normalized = rawType.toLowerCase().replaceAll(' ', '');
        final data = sensor['data'];

        print('➡️ Checking sensor → rawType: "$rawType", normalized: "$normalized"');

        if (normalized == 'dht11' && allowedNormalized.contains('dht11')) {
          print('🌡 Found DHT11 data → $data');
          if (data?['temperature'] != null) {
            result['temperature'] = '${data['temperature']} °C';
          }
          if (data?['humidity'] != null) {
            result['humidity'] = '${data['humidity']} %';
          }
        } else if (allowedNormalized.contains(normalized)) {
          print('✅ Allowed sensor matched: $normalized → $data');
          String displayKey = normalized;
          if (normalized == 'mq2') displayKey = 'gas';
          if (normalized == 'flamesensor') displayKey = 'flame';
          if (normalized == 'pir') displayKey = 'motion';

          result[displayKey] = data?['value']?.toString() ?? 'N/A';
        } else {
          print('❌ Ignored sensor: $normalized (not in allowed list)');
        }
      }

      setState(() {
        environmentData = result;
      });

      print('📦 Final environment data for $selectedRoom: $environmentData');
    } catch (e) {
      print('❌ Error fetching environment data: $e');
    }
  }

  Future<void> _toggleDevice(String type, String room, bool newState) async {
    String url;
    Map<String, dynamic> body;

    if (type.toLowerCase() == 'door') {
      url = 'http://localhost:5000/api/doors/toggle';
      body = {'room': room, 'status': newState ? 'true' : 'false'};
    } else if (type.toLowerCase() == 'light') {
      url = 'http://localhost:5000/api/lights/toggle';
      body = {'room': room, 'status': newState};
    } else {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      print('$type in $room toggled: ${response.statusCode}');
    } catch (e) {
      print('Error toggling $type: $e');
    }
  }

  void _navigateToDeviceDetail({
    required BuildContext context,
    required String type,
    required String id,
    required String room,
    required bool state,
  }) {
    final device = devicesByRoom[room]?.firstWhere((d) => d['id'].toString() == id, orElse: () => {});
    if (device == null) return;

    switch (type.toLowerCase()) {
      case 'light':
        Navigator.pushNamed(context, '/light-detail', arguments: {
          'id': id,
          'room': room,
          'state': state,
          'brightness': device['brightness'] ?? 70,
          'intensity': device['intensity'] ?? 70,
          'schedule': device['schedule'],
        });
        break;
      case 'fan':
      case 'ventilation':
        Navigator.pushNamed(context, '/fan-detail', arguments: {
          'id': id,
          'room': room,
          'state': state,
          'speed': device['speed'] ?? 0,
          'schedule': device['schedule'] ?? {'from': '00:00', 'to': '12:00', 'days': []},
        });
        break;
      case 'pump':
      case 'watering':
        Navigator.pushNamed(context, '/pump-detail', arguments: {
          'id': id,
          'room': room,
          'state': state,
          'speed': device['speed'] ?? 1,
          'schedule': device['schedule'] ?? {'from': '00:00', 'to': '12:00', 'days': []},
        });
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoomTabs(),
              const SizedBox(height: 24),
              EnvironmentCard(data: environmentData),
              const SizedBox(height: 24),
              _buildDeviceGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomTabs() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: roomNames.map((room) {
      final isSelected = selectedRoom == room;
      return GestureDetector(
        onTap: () {
          setState(() => selectedRoom = room);
          _fetchEnvironmentData();
        },
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
              ),
          ],
        ),
      );
    }).toList(),
  );

  Widget _buildDeviceGrid() {
    final devices = devicesByRoom[selectedRoom] ?? [];

    return Expanded(
      child: GridView.builder(
        itemCount: devices.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final device = devices[index];
          final deviceId = device['id'].toString(); // ✅ ensure string key
          final deviceType = device['type'];

          return DeviceCard(
            icon: _getIconFromType(deviceType),
            name: device['name'] ?? deviceType,
            model: device['model'] ?? '',
            initialState: deviceStates[deviceId] ?? false,
            onToggle: (val) async {
              setState(() => deviceStates[deviceId] = val);
              await _toggleDevice(deviceType, selectedRoom, val);
            },
            onTap: () {
              _navigateToDeviceDetail(
                context: context,
                type: deviceType,
                id: deviceId,
                room: selectedRoom,
                state: deviceStates[deviceId] ?? false,
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconFromType(String type) {
    switch (type.toLowerCase()) {
      case 'light':
      case 'lumiére':
        return Icons.lightbulb_outline;
      case 'climatiseur':
        return Icons.ac_unit;
      case 'tv':
        return Icons.tv;
      case 'music':
      case 'musique':
        return Icons.music_note;
      case 'door':
        return Icons.sensor_door;
      case 'ventilation':
      case 'fan':
        return Icons.air;
      case 'pump':
      case 'watering':
        return Icons.water_drop;
      default:
        return Icons.devices_other;
    }
  }
}
