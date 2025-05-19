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

  static Future<Map<String, dynamic>> toggleLight({
    required String room,
    required bool status,
    int? brightness,
    int? intensity,
    Map<String, String>? schedule,
  }) async {
    final url = Uri.parse('$baseUrl/lights/toggle');

    final Map<String, dynamic> body = {
      'room': room,
      'status': status,
      if (brightness != null) 'brightness': brightness,
      if (intensity != null) 'intensity': intensity,
      if (schedule != null) 'schedule': schedule,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          throw Exception("Invalid JSON response from server");
        }
      } else {
        // Try parsing error message from backend
        try {
          final error = jsonDecode(response.body);
          throw Exception("Server error: ${error['error'] ?? 'Unknown error'}");
        } catch (_) {
          // Fallback for HTML or non-JSON errors
          throw Exception("Server returned error ${response.statusCode}: ${response.reasonPhrase}");
        }
      }
    } catch (e) {
      throw Exception('Failed to toggle light: $e');
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

  static Future<void> controlPump({
    required String room,
    required bool status,
    int? speed,
    Map<String, String>? schedule,
  }) async {
    final url = Uri.parse('$baseUrl/pump/control');

    final body = {
      'room': room,
      'status': status,
    };

    if (speed != null) body['speed'] = speed;
    if (schedule != null) body['schedule'] = schedule;

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      try {
        final error = jsonDecode(response.body);
        throw Exception('Pump error: ${error['error'] ?? 'Unknown error'}');
      } catch (_) {
        throw Exception('Failed to control pump. Status: ${response.statusCode}');
      }
    }
  }


  static Future<void> controlVentilation({
    required String room,
    required bool status,
    int? speed,
    Map<String, dynamic>? schedule,
  }) async {
    final url = Uri.parse('$baseUrl/ventilations/control');

    final Map<String, dynamic> body = {
      'room': room,
      'status': status,
      if (speed != null) 'speed': speed,
      if (schedule != null) 'schedule': schedule,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) return;

      // Try to parse JSON error from backend
      try {
        final error = jsonDecode(response.body);
        throw Exception('Ventilation error: ${error['error'] ?? 'Unknown error'}');
      } catch (_) {
        throw Exception('Ventilation failed with status ${response.statusCode}');
      }

    } catch (e) {
      throw Exception('Failed to control ventilation: $e');
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
