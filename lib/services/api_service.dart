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


  Future<List<dynamic>> fetchTips() async {
    final String url = 'http://127.0.0.1:5000/get-tips';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> tips = json.decode(response.body);
        return tips;
      } else {
        throw Exception('Failed to load tips');
      }
    } catch (e) {
      print('Error fetching tips: $e');
      return [];
    }
  }



  static Future<List<Map<String, dynamic>>> getSensorData() async {
    final url = Uri.parse('http://localhost:3000/api/sensor/data/esp32-001');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        final List<Map<String, dynamic>> sensorList =
        List<Map<String, dynamic>>.from(jsonData['data']);

        // ✅ DEBUG: Print the raw response
        print('✅ Raw JSON Response: ${response.body}');

        // ✅ DEBUG: Print parsed sensor list
        for (var sensor in sensorList) {
          print('📡 SensorType: ${sensor['sensorType']} → Data: ${sensor['data']}');
        }

        return sensorList;
      } else {
        print('❌ Request failed with status: ${response.statusCode}');
        throw Exception('Failed to load sensor data');
      }
    } catch (e) {
      print('❌ Error during sensor data fetch: $e');
      rethrow;
    }
  }



}
