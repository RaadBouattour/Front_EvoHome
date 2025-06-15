import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/device.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.228.166:5000/api';
  static late IO.Socket socket;

  static void initWebSocket() {
    socket = IO.io(
      'http://192.168.228.166:5000',
      IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    socket.connect();

    socket.onConnect((_) => print('✅ WebSocket connected to device control service'));
    socket.onDisconnect((_) => print('❌ Disconnected from device control service'));
  }

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


  static Future<bool?> getDeviceStatusById(String deviceId) async {
    final url = Uri.parse('$baseUrl/devices/grouped-by-room');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Flatten all room arrays into a single list
        for (final roomDevices in data.values) {
          if (roomDevices is List) {
            for (final device in roomDevices) {
              if (device['id'] == deviceId) {
                final status = device['status'];
                if (status is bool) {
                  return status;
                }
              }
            }
          }
        }
        return null; // ID not found
      } else {
        throw Exception('Failed to load devices');
      }
    } catch (e) {
      print('❌ Error in getDeviceStatusById: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchAllDevicesGroupedByRoom() async {
    final response = await http.get(Uri.parse('http://192.168.228.166:5000/api/devices/grouped-by-room'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch device groups');
    }
  }


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
      if (speed != null) 'speed': speed,
      if (schedule != null) 'schedule': schedule,
    };

    debugPrint("📤 Sending controlPump request to $url");
    debugPrint("📦 Request body: ${body.toString()}");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    debugPrint("📥 Response (${response.statusCode}): ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('❌Failed to control pump');
    }
  }



  static Future<void> controlVentilation({
    required String room,
    required bool status,
    int? speed,
    Map<String, dynamic>? schedule,
  }) async {
    final url = Uri.parse('$baseUrl/ventilations/control');

    final payload = {
      "room": room,
      "status": status,
      if (speed != null) "speed": speed,
      if (schedule != null) "schedule": schedule,
    };

    // 🐞 DEBUG: Show request
    print('📤 Sending POST to: $url');
    print('📦 Payload: ${jsonEncode(payload)}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // ✅ DEBUG: Show response
      print('✅ Response Code: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Fluttertoast.showToast(msg: "Ventilation updated ✅");
      } else {
        Fluttertoast.showToast(msg: "Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error sending ventilation control: $e");
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }



  static Future<List<Map<String, dynamic>>> fetchSensorData() async {
    final url = Uri.parse('http://192.168.228.166:3000/api/sensor/data/esp32-001');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        final List<Map<String, dynamic>> sensorList =
        List<Map<String, dynamic>>.from(jsonData['data']);

        print('Raw JSON Response: ${response.body}');
        for (var sensor in sensorList) {
          print('SensorType: ${sensor['sensorType']} → Data: ${sensor['data']}');
        }

        return sensorList;
      } else {
        print('Request failed with status: ${response.statusCode}');
        throw Exception('Failed to load sensor data');
      }
    } catch (e) {
      print('Error during sensor data fetch: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> fetchSchedule({
    required String deviceType,
    required String deviceId,
  }) async {
    final url = Uri.parse('$baseUrl/schedule/$deviceType/$deviceId');

    print("📡 [GET] Fetching schedule from: $url");

    try {
      final response = await http.get(url);

      print("📥 Status: ${response.statusCode}");
      print("📥 Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['schedule'] != null) {
          print("✅ Parsed schedule: ${data['schedule']}");
          return Map<String, dynamic>.from(data['schedule']);
        } else {
          print("ℹ️ No schedule found in response.");
          return null;
        }
      } else {
        print("❌ Failed to fetch schedule: HTTP ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception during schedule fetch: $e");
      return null;
    }
  }




  static Future<bool> deleteScheduleByDevice(String deviceType, String deviceId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/schedule/$deviceType/$deviceId'),
    );
    return response.statusCode == 200;
  }

  static Future<bool?> getDeviceState(String deviceType, String deviceId) async {
    final response = await http.get(Uri.parse('$baseUrl/device_state/$deviceType/$deviceId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] as bool?;
    }
    throw Exception("Failed to get device state");
  }


}
