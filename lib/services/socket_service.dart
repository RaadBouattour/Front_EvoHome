import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? alertSocket;
  static IO.Socket? sensorSocket;

  // ✅ Base URL for REST API
  static const String _baseUrl = 'http://localhost:4010/api';

  /// Connects to alert WebSocket (Port 4010)
  static void connectToAlertServer(Function(String message) onAlertReceived) {
    print('📡 Connecting to Alert WebSocket...');

    alertSocket = IO.io('http://192.168.228.150:4010', {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    alertSocket!.onConnect((_) {
      print('✅ Connected to Alert Server');
    });

    alertSocket!.on('alert', (data) {
      final message = data['message'] ?? '⚠️ Danger Alert!';
      print('📳 Alert received: $message');
      onAlertReceived(message);
    });
  }

  /// Connects to sensor data WebSocket (Port 3000)
  static void connectToSensorServer(Function(Map<String, dynamic>) onSensorUpdate) {
    print('📡 Connecting to Sensor WebSocket...');

    sensorSocket = IO.io('http://192.168.228.150:3000', {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    sensorSocket!.onConnect((_) {
      print('✅ Connected to Sensor Server');
    });

    sensorSocket!.on('new_sensor_data', (data) {
      print('📡 Sensor Data Received: $data');
      onSensorUpdate(Map<String, dynamic>.from(data));
    });
  }

  static void disconnectAll() {
    alertSocket?.disconnect();
    sensorSocket?.disconnect();
  }

  // ✅ GET notifications from REST API
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/notifications'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }
}
