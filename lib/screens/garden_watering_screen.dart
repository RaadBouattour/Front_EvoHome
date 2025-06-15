import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/sensor_socket_service.dart';
import '../services/api_service.dart';

class GardenWateringScreen extends StatefulWidget {
  const GardenWateringScreen({super.key});

  @override
  State<GardenWateringScreen> createState() => _GardenWateringScreenState();
}

class _GardenWateringScreenState extends State<GardenWateringScreen> {
  String pumpId = '';
  String room = 'garden';
  bool isPumpOn = false;
  int moistureRaw = 600;
  TimeOfDay fromTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay toTime = const TimeOfDay(hour: 12, minute: 0);

  static const Color greenAccent = Color(0xFF4CAF50);

  bool _isScheduled = false;
  bool _initialized = false;

  late StreamSubscription _sensorSubscription;

  double _convertToPercentage(double rawValue) {
    const double minValue = 0;
    const double maxValue = 1300;
    double percentage = 100 - ((rawValue - minValue) / (maxValue - minValue)) * 100;
    return percentage.clamp(0.0, 100.0);
  }

  @override
  void initState() {
    super.initState();

    SensorSocketService().connect('garden', {
      'garden': ['soil_moisture', 'pir', 'mq2', 'dht11', 'flame sensor'],
    });

    _fetchInitialMoisture();
    _listenToSensorStream();
  }

  @override
  void dispose() {
    _sensorSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchInitialMoisture() async {
    try {
      final dataList = await ApiService.fetchSensorData();
      for (final entry in dataList) {
        final type = (entry['sensorType'] ?? '').toString().toLowerCase();
        if (type == 'soil_moisture') {
          final val = entry['data']['moisture'];
          if (val != null) {
            if (!mounted) return;
            setState(() => moistureRaw = int.tryParse(val.toString()) ?? 200);
            break;
          }
        }
      }
    } catch (_) {}
  }

  void _listenToSensorStream() {
    _sensorSubscription = SensorSocketService().sensorStream.listen((data) {
      final raw = data['moisture'];
      if (raw != null) {
        final val = int.tryParse(raw.toString());
        if (val != null && val != moistureRaw) {
          if (!mounted) return;
          setState(() => moistureRaw = val);
          debugPrint('📡 Moisture updated from WebSocket: $val');
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      pumpId = args['id'] ?? '';
      room = args['room'] ?? 'garden';

      final schedule = args['schedule'];
      if (schedule != null) {
        final fromParts = (schedule['from'] as String?)?.split(':');
        final toParts = (schedule['to'] as String?)?.split(':');
        if (fromParts?.length == 2 && toParts?.length == 2) {
          fromTime = TimeOfDay(hour: int.parse(fromParts![0]), minute: int.parse(fromParts[1]));
          toTime = TimeOfDay(hour: int.parse(toParts![0]), minute: int.parse(toParts[1]));
          _isScheduled = true;
        }
      }

      if (pumpId.isNotEmpty) {
        _fetchSchedule();           // ⏰ for scheduling
        _fetchCurrentPumpState();   // ✅ for switch consistency
      }
    }
  }


  Future<void> _fetchSchedule() async {
    try {
      final schedule = await ApiService.fetchSchedule(
        deviceType: 'pump',      // or 'ventilation', 'light', etc.
        deviceId: pumpId,
      );

      if (schedule != null && schedule['from'] != null && schedule['to'] != null) {
        final fromParts = (schedule['from'] as String).split(':');
        final toParts = (schedule['to'] as String).split(':');

        if (fromParts.length == 2 && toParts.length == 2) {
          if (!mounted) return;
          setState(() {
            fromTime = TimeOfDay(hour: int.parse(fromParts[0]), minute: int.parse(fromParts[1]));
            toTime = TimeOfDay(hour: int.parse(toParts[0]), minute: int.parse(toParts[1]));
            _isScheduled = true;
          });
        }
      } else {
        if (!mounted) return;
        setState(() => _isScheduled = false);
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch schedule: $e');
    }
  }

  Future<void> _togglePump(bool value) async {
    setState(() {
      isPumpOn = value;
    });

    try {
      await ApiService.controlPump(room: room, status: value);
      Fluttertoast.showToast(
        msg: "Pump turned ${value ? 'ON' : 'OFF'} ✅",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to toggle pump ❌",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }


  Future<void> _submitSchedule() async {
    // 🛑 Check if pump is ON
    if (isPumpOn) {
      Fluttertoast.showToast(
        msg: "Please turn off the pump to apply a schedule ❌",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    // ⏳ Validate time
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final fromMinutes = fromTime.hour * 60 + fromTime.minute;
    final toMinutes = toTime.hour * 60 + toTime.minute;

    if (fromMinutes < nowMinutes || toMinutes < nowMinutes) {
      Fluttertoast.showToast(
        msg: "From and To times must be in the future ⏳",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // 🕒 Prepare and send schedule
    final from = '${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')}';
    final to = '${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')}';

    try {
      await ApiService.controlPump(
        room: room,
        status: false,
        schedule: {"from": from, "to": to},
      );

      debugPrint("✅ Schedule submitted with from: $from, to: $to, pump: OFF");

      if (!mounted) return;
      setState(() => _isScheduled = true);

      // ✅ Success Toast
      Fluttertoast.showToast(
        msg: "Schedule applied successfully ✅",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint("❌ Failed to submit schedule: $e");
      Fluttertoast.showToast(
        msg: "Schedule error: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }



  Future<void> _deleteSchedule() async {
    final success = await ApiService.deleteScheduleByDevice("pump",pumpId);
    if (success) {
      if (!mounted) return;
      setState(() {
        fromTime = const TimeOfDay(hour: 0, minute: 0);
        toTime = const TimeOfDay(hour: 0, minute: 0);
        _isScheduled = false;
      });
    }
  }

  Future<void> _pickTime(bool isFrom) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? fromTime : toTime,
    );

    if (picked != null) {
      final pickedMinutes = picked.hour * 60 + picked.minute;
      final nowMinutes = now.hour * 60 + now.minute;

      if (pickedMinutes < nowMinutes) {
        Fluttertoast.showToast(
          msg: "Time cannot be earlier than now ⏰",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      setState(() {
        if (isFrom) {
          fromTime = picked;
        } else {
          toTime = picked;
        }
      });
    }
  }

  Future<void> _fetchCurrentPumpState() async {
    try {
      final status = await ApiService.getDeviceStatusById(pumpId);
      debugPrint('🔍 Retrieved status for pump $pumpId: $status');

      if (!mounted) return;
      setState(() {
        isPumpOn = status == true;
      });
    } catch (e) {
      debugPrint('❌ Failed to fetch pump status by ID: $e');
    }
  }





  @override
  Widget build(BuildContext context) {
    final bool scheduleIsSet = _isScheduled;
    final percentage = _convertToPercentage(moistureRaw.toDouble());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 8),
                      const Text('Garden Pump', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Switch(
                        value: isPumpOn,
                        activeColor: greenAccent,
                        onChanged: _togglePump,
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 180,
                    child: Image.asset('assets/images/pump.png', fit: BoxFit.contain),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F6F2), Color(0xFFD7F0E7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 25,
                      spreadRadius: 1,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'SOIL MOISTURE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 30),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteSchedule,
                    tooltip: 'Delete schedule',
                  )
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheduleIsSet ? greenAccent.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheduleIsSet ? greenAccent : Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Text('From ', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    TextButton(
                      onPressed: () => _pickTime(true),
                      child: Row(
                        children: [
                          Text(fromTime.format(context), style: const TextStyle(fontSize: 16)),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text('To ', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    TextButton(
                      onPressed: () => _pickTime(false),
                      child: Row(
                        children: [
                          Text(toTime.format(context), style: const TextStyle(fontSize: 16)),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.check, color: _isScheduled ? Colors.green : Colors.grey),
                      onPressed: _submitSchedule,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
