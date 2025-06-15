import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SensorSocketService {
  static final SensorSocketService _instance = SensorSocketService._internal();
  factory SensorSocketService() => _instance;
  SensorSocketService._internal();

  final _sensorDataController = StreamController<Map<String, dynamic>>.broadcast();
  IO.Socket? _socket;

  Stream<Map<String, dynamic>> get sensorStream => _sensorDataController.stream;

  void connect(String selectedRoom, Map<String, List<String>> roomSensors) {
    if (_socket != null && _socket!.connected) return;

    final allowed = roomSensors[selectedRoom.toLowerCase()] ?? [];
    final allowedNormalized = allowed
        .map((e) => e.toLowerCase().replaceAll(RegExp(r'[\s_]+'), '')) // Remove _ and spaces
        .toList();


    _socket = IO.io(
      'http://192.168.228.166:3000',
      IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Connected to sensor WebSocket');
    });

    _socket!.on('sensor_data', (data) {

      try {
        final dataList = data is List ? data : [data];

        for (final entry in dataList) {
          final updatedData = <String, dynamic>{};
          final sensorTypeRaw = (entry['sensorType'] ?? '').toString();
          final sensorType = sensorTypeRaw.toLowerCase().replaceAll(' ', '').replaceAll('_', '');

          if (sensorType == 'dht11' && allowedNormalized.contains('dht11')) {
            final temp = entry['data']['temperature'];
            final hum = entry['data']['humidity'];
            print('🌡️ DHT11 payload: ${entry['data']}');
            if (temp != null) updatedData['temperature'] = '$temp °C';
            if (hum != null) updatedData['humidity'] = '$hum %';
          }

          if (sensorType == 'mq2' && allowedNormalized.contains('mq2')) {
            final gas = entry['data']['gas'];
            print('🧪 MQ2 payload: ${entry['data']}');
            if (gas != null) updatedData['gas'] = gas.toString();
          }

          if (sensorType == 'flamesensor' && allowedNormalized.contains('flamesensor')) {
            final flame = entry['data']['flame'];
            print('🔥 Flame payload: ${entry['data']}');
            if (flame != null) updatedData['flame'] = flame.toString();
          }

          if (sensorType == 'soilmoisture' && allowedNormalized.contains('soilmoisture')) {
            final moisture = entry['data']['moisture'];
            print('🌱 Soil moisture payload: ${entry['data']}');
            if (moisture != null) updatedData['moisture'] = moisture.toString();
          }


          if (sensorType == 'pir' && allowedNormalized.contains('pir')) {
            final motion = entry['data']['motion'];
            print('🚶 PIR motion payload: ${entry['data']}');
            if (motion != null) updatedData['motion'] = motion.toString();
          }


          if (updatedData.isNotEmpty) {
            print('📡 Parsed sensor data: $updatedData');
            _sensorDataController.add(updatedData);
          }
        }
      } catch (e) {
        print('❌ Error while parsing sensor data: $e');
      }
    });

    _socket!.onDisconnect((_) {
      print('❌ Disconnected from sensor WebSocket');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.destroy();
    _sensorDataController.close();
  }
}
