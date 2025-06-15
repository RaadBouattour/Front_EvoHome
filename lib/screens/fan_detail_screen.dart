import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/sensor_socket_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FanDetailScreen extends StatefulWidget {
  const FanDetailScreen({super.key});

  @override
  State<FanDetailScreen> createState() => _FanDetailScreenState();
}

class _FanDetailScreenState extends State<FanDetailScreen> {
  String fanId = '';
  String room = '';
  bool isFanOn = false;
  int fanSpeed = 1;
  int temperature = 22;
  String temperatureStatus = 'Checking...';
  bool _initialized = false;
  bool _isScheduled = false;

  TimeOfDay fromTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay toTime = const TimeOfDay(hour: 0, minute: 0);

  static const Color oceanBlue = Color(0xFF0077B6);
  double imageHeight = 210;

  @override
  void initState() {
    super.initState();
    _fetchInitialTemperature();
    _listenToSensorStream();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      fanId = args['id'] ?? '';
      room = args['room'] ?? '';
      isFanOn = args['state'] ?? false;
      fanSpeed = args['speed'] ?? 1;

      final schedule = args['schedule'];
      if (schedule != null) {
        try {
          final fromParts = (schedule['from'] as String).split(':');
          final toParts = (schedule['to'] as String).split(':');
          if (fromParts.length == 2 && toParts.length == 2) {
            fromTime = TimeOfDay(hour: int.parse(fromParts[0]), minute: int.parse(fromParts[1]));
            toTime = TimeOfDay(hour: int.parse(toParts[0]), minute: int.parse(toParts[1]));
            _isScheduled = true;
          }
        } catch (_) {}
      }

      _checkSchedule();
      _fetchCurrentFanState(); // 🟢 Sync fan switch with backend
    }
  }

  Future<void> _checkSchedule() async {
    try {
      final schedule = await ApiService.fetchSchedule(deviceType: 'ventilation', deviceId: fanId);
      if (schedule != null && schedule['from'] != null && schedule['to'] != null) {
        final fromParts = (schedule['from'] as String).split(':');
        final toParts = (schedule['to'] as String).split(':');

        if (fromParts.length == 2 && toParts.length == 2) {
          setState(() {
            fromTime = TimeOfDay(hour: int.parse(fromParts[0]), minute: int.parse(fromParts[1]));
            toTime = TimeOfDay(hour: int.parse(toParts[0]), minute: int.parse(toParts[1]));
            _isScheduled = true;
          });
        }
      } else {
        setState(() => _isScheduled = false);
      }
    } catch (e) {
      print("❌ Error checking schedule: $e");
    }
  }

  void _evaluateTemperatureStatus(int temp) {
    if (temp > 30) {
      temperatureStatus = 'Temperature too high ($temp°C). Turn on fan recommended.';
    } else if (temp >= 20) {
      temperatureStatus = 'Temperature good ($temp°C). Fan optional.';
    } else {
      temperatureStatus = 'Temperature low ($temp°C). Turn off fan recommended.';
    }
  }

  Future<void> _fetchInitialTemperature() async {
    try {
      final dataList = await ApiService.fetchSensorData();
      for (final entry in dataList) {
        final type = (entry['sensorType'] ?? '').toString().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
        if (type == 'dht11') {
          final tempVal = entry['data']['temperature'];
          if (tempVal != null) {
            setState(() {
              temperature = int.tryParse(tempVal.toString().split('.')[0]) ?? 22;
              _evaluateTemperatureStatus(temperature);
            });
            return;
          }
        }
      }
    } catch (e) {
      print('Error fetching initial temperature: $e');
    }
  }

  void _listenToSensorStream() {
    SensorSocketService().sensorStream.listen((data) {
      final tempRaw = data['temperature'];
      if (tempRaw != null) {
        final tempStr = tempRaw.toString().replaceAll('°C', '').trim();
        final newTemp = double.tryParse(tempStr)?.round();
        if (newTemp != null && newTemp != temperature && mounted) {
          setState(() {
            temperature = newTemp;
            _evaluateTemperatureStatus(temperature);
          });
        }
      }
    });
  }

  Future<void> _toggleFan(bool value) async {
    try {
      await ApiService.controlVentilation(room: room, status: value);
      setState(() {
        isFanOn = value;
        if (isFanOn && fanSpeed == 0) fanSpeed = 1;
      });
    } catch (e) {
      print("Error toggling fan: $e");
    }
  }

  Future<void> _changeFanSpeed(bool increase) async {
    if (!isFanOn) return;

    final newSpeed = increase ? (fanSpeed < 3 ? fanSpeed + 1 : 3) : (fanSpeed > 1 ? fanSpeed - 1 : 1);

    if (newSpeed != fanSpeed) {
      try {
        await ApiService.controlVentilation(room: room, status: isFanOn, speed: newSpeed);
        setState(() => fanSpeed = newSpeed);
      } catch (e) {
        print("Error updating fan speed: $e");
      }
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


  Future<void> _submitSchedule() async {
    final now = TimeOfDay.now();
    final fromMinutes = fromTime.hour * 60 + fromTime.minute;
    final toMinutes = toTime.hour * 60 + toTime.minute;
    final nowMinutes = now.hour * 60 + now.minute;

    if (fromMinutes < nowMinutes || toMinutes < nowMinutes) {
      Fluttertoast.showToast(
        msg: "Schedule must start and end in the future ⏳",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final fromStr = "${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')}";
    final toStr = "${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')}";

    try {
      await ApiService.controlVentilation(
        room: room,
        status: false,
        schedule: {
          "from": fromStr,
          "to": toStr,
        },
      );

      setState(() {
        _isScheduled = true;
      });

      Fluttertoast.showToast(msg: "Schedule saved ✅");
    } catch (e) {
      print("Schedule error: $e");
      Fluttertoast.showToast(msg: "Schedule error: $e");
    }
  }


  Future<void> _deleteSchedule() async {
    try {
      await ApiService.deleteScheduleByDevice("ventilation", fanId);
      setState(() {
        _isScheduled = false;
        fromTime = const TimeOfDay(hour: 0, minute: 0);
        toTime = const TimeOfDay(hour: 0, minute: 0);
      });
      Fluttertoast.showToast(msg: "Schedule deleted 🗑️");
    } catch (e) {
      print("Failed to delete schedule: $e");
      Fluttertoast.showToast(msg: "Failed to delete schedule ❌");
    }
  }

  Future<void> _fetchCurrentFanState() async {
    try {
      final status = await ApiService.getDeviceStatusById(fanId);
      debugPrint('🌀 Fan $fanId fetched status: $status');

      if (!mounted) return;
      setState(() {
        isFanOn = status == true;
      });
    } catch (e) {
      debugPrint('❌ Failed to fetch fan status: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
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
                      const Text('Cooling', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 10),
                      Switch(
                        value: isFanOn,
                        activeColor: oceanBlue,
                        onChanged: _toggleFan,
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: imageHeight,
                    child: Image.asset('assets/images/fan.png', fit: BoxFit.contain),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFDEE2E7), Color(0xFFDBE0E7)]),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Center(
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFFCBCED3), Color(0xFFFAFBFC)]),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('COOLING', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        Text('$temperature°C', style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        const Icon(Icons.eco, color: Color(0xFF09D542), size: 28),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    iconSize: 32,
                    color: oceanBlue,
                    onPressed: () => _changeFanSpeed(false),
                  ),
                  Text('Speed $fanSpeed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: oceanBlue)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    iconSize: 32,
                    color: oceanBlue,
                    onPressed: () => _changeFanSpeed(true),
                  ),
                ],
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
                  color: _isScheduled ? oceanBlue.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isScheduled ? oceanBlue : Colors.grey.withOpacity(0.3)),
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
