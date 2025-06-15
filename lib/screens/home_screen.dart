import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart';
import '../services/sensor_socket_service.dart';
import '../widgets/environment_card.dart';
import '../widgets/device_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _latestSensorData = {
    'temperature': '–',
    'humidity': '–',
    'gas': '–',
    'flame': '–',
  };

  String selectedRoom = '';
  List<String> roomNames = [];
  Map<String, List<Map<String, dynamic>>> devicesByRoom = {};
  Map<String, bool> deviceStates = {};
  Map<String, dynamic> environmentData = {};
  OverlayEntry? _alertOverlay;

  final Map<String, List<String>> roomSensors = {
    'living room': ['DHT11', 'MQ2', 'Flame Sensor'],
    'garden': ['DHT11', 'MQ2', 'Flame Sensor'],
    'bedroom': ['DHT11', 'MQ2', 'Flame Sensor'],
  };

  @override
  void initState() {
    super.initState();
    _fetchDeviceData();
    _fetchInitialSensorData();
    _setupAlertWebSocket();
    ApiService.initWebSocket();
    Future.delayed(Duration(milliseconds: 500), () {
      _refreshDeviceStates();   // ✅ Fetch real-time status
    });
  }

  void _initializeSensorWebSocket() {
    if (selectedRoom.isNotEmpty) {
      final normalizedRoom = selectedRoom.toLowerCase();
      final allowedSensors = roomSensors[normalizedRoom] ?? [];
      print('🧭 Initializing Sensor WebSocket for: $normalizedRoom with sensors: $allowedSensors');
      SensorSocketService().connect(normalizedRoom, {normalizedRoom: allowedSensors});

      SensorSocketService().sensorStream.listen((data) {
        print('📡 Incoming sensor data: $data');
        if (!mounted) return;

        setState(() {
          data.forEach((key, value) {
            _latestSensorData[key] = value.toString(); // Update only the changed key
          });
        });
      });

    } else {
      print('⚠️ selectedRoom is empty, skipping WebSocket setup');
    }
  }
  void _fetchInitialSensorData() async {
    try {
      final List<Map<String, dynamic>> initialData = await ApiService.fetchSensorData();

      // Convert list to map
      for (var sensor in initialData) {
        final type = sensor['sensorType']?.toLowerCase();
        final value = sensor['data'];
        if (type != null && value != null) {
          setState(() {
            _latestSensorData[type] = value.toString();
          });
        }
      }
    } catch (e) {
      print('❌ Error loading initial sensor data: $e');
    }
  }


  void _setupAlertWebSocket() {
    final socket = IO.io(
      'http://192.168.228.150:4010',
      IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    socket.connect();

    socket.onConnect((_) {
      if (mounted) print('Connected to alert WebSocket server');
    });

    socket.on('alert', (data) {
      if (!mounted) return;
      final message = data['message'] ?? 'Danger Alert!';
      print('Alert received: $message');
      _showGlobalAlert(message);
    });

    socket.onDisconnect((_) {
      if (mounted) print('Disconnected from alert WebSocket');
    });
  }

  void _showGlobalAlert(String message) {
    _alertOverlay?.remove();
    _alertOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        left: 20,
        right: 20,
        child: Material(
          elevation: 8,
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(_alertOverlay!);
    Future.delayed(const Duration(seconds: 3), () {
      _alertOverlay?.remove();
      _alertOverlay = null;
    });
  }

  Future<void> _fetchDeviceData() async {
    final url = Uri.parse('http://192.168.228.166:5000/api/devices/grouped-by-room');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final rooms = jsonData.keys.toList();
        final Map<String, List<Map<String, dynamic>>> mappedDevices = {};
        final Map<String, bool> states = {};

        for (var room in rooms) {
          final List<dynamic> deviceList = jsonData[room];
          mappedDevices[room] = deviceList.map((e) {
            final device = e as Map<String, dynamic>;
            final id = device['id'].toString();
            final type = device['type'];
            final status = device['status'] ?? device['state'] ?? false;
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

        _initializeSensorWebSocket();
      } else {
        throw Exception('Failed to load device data');
      }
    } catch (e) {
      print('Error fetching device data: $e');
    }
  }

  // Removed _fetchEnvironmentData since WebSocket handles it

  Future<void> _toggleDevice(String type, String room, bool newState) async {
    String url;
    Map<String, dynamic> body;

    switch (type.toLowerCase()) {
      case 'door':
        url = 'http://192.168.228.166:5000/api/doors/toggle';
        body = {'room': room, 'status': newState};
        break;

      case 'light':
        url = 'http://192.168.228.166:5000/api/lights/toggle';
        body = {'room': room, 'status': newState};
        break;

      case 'ventilation':
        url = 'http://192.168.228.166:5000/api/ventilations/control';
        body = {
          'room': room,
          'status': newState
        };
        break;

      case 'pump':
        url = 'http://192.168.228.166:5000/api/pump/control';
        body = {
          'room': room,
          'status': newState
        };
        break;

      default:
        print('Unsupported device type: $type');
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

  Future<void> _refreshDeviceStates() async {
    try {
      final allDevices = await ApiService.fetchAllDevicesGroupedByRoom();

      final Map<String, bool> newStates = {};

      for (final room in allDevices.keys) {
        final devices = allDevices[room] as List<dynamic>;
        for (final d in devices) {
          final device = d as Map<String, dynamic>;
          final id = device['id'].toString();
          final status = device['status'] ?? device['state'] ?? false;
          newStates[id] = status;
        }
      }

      setState(() => deviceStates = newStates);
    } catch (e) {
      print('❌ Failed to refresh device states: $e');
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
              EnvironmentCard(data: _latestSensorData),
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
          // WebSocket will update environmentData for the new room
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
          final deviceId = device['id'].toString();
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