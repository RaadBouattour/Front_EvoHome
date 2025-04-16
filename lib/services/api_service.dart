import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api'; // Replace with your IP if needed

  // Fetch all devices grouped by room
  static Future<Map<String, List<Device>>> fetchDevicesGroupedByRoom() async {
    final response = await http.get(Uri.parse('$baseUrl/devices/grouped-by-room'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      Map<String, List<Device>> groupedDevices = {};

      data.forEach((room, deviceList) {
        groupedDevices[room] = List<Device>.from(
          deviceList.map((device) => Device.fromJson(device)),
        );
      });

      return groupedDevices;
    } else {
      throw Exception('Failed to load devices');
    }
  }

  // Toggle device state
  static Future<void> toggleDevice(Device device) async {
    final endpoint = getEndpointForType(device.type);
    if (endpoint == null) throw Exception('Unknown device type: ${device.type}');

    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint/${device.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'state': !device.state}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle ${device.name}');
    }
  }

  // Get the correct endpoint path based on device type
  static String? getEndpointForType(String type) {
    switch (type.toLowerCase()) {
      case 'light':
        return 'lights';
      case 'ventilation':
      case 'air conditioner':
        return 'ventilations';
      case 'door':
        return 'doors';
      default:
        return null;
    }
  }
}
