import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  TimeOfDay fromTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay toTime = const TimeOfDay(hour: 12, minute: 0);

  static const Color oceanBlue = Color(0xFF0077B6);
  double imageHeight = 210;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      fanId = args['id'] ?? '';
      room = args['room'] ?? '';
      isFanOn = args['state'] ?? false;
      fanSpeed = args['speed'] ?? 1;

      if (args['schedule'] != null) {
        final schedule = args['schedule'];
        if (schedule['from'] != null && schedule['to'] != null) {
          final fromParts = (schedule['from'] as String).split(':');
          final toParts = (schedule['to'] as String).split(':');
          if (fromParts.length == 2 && toParts.length == 2) {
            fromTime = TimeOfDay(hour: int.parse(fromParts[0]), minute: int.parse(fromParts[1]));
            toTime = TimeOfDay(hour: int.parse(toParts[0]), minute: int.parse(toParts[1]));
          }
        }
      }
    }
  }

  Future<void> _toggleFan(bool value) async {
    try {
      await ApiService.controlVentilation(
        room: room,
        status: value,
      );
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

    final newSpeed = increase
        ? (fanSpeed < 3 ? fanSpeed + 1 : 3)
        : (fanSpeed > 1 ? fanSpeed - 1 : 1);

    if (newSpeed != fanSpeed) {
      try {
        await ApiService.controlVentilation(
          room: room,
          status: isFanOn,
          speed: newSpeed,
        );
        setState(() => fanSpeed = newSpeed);
      } catch (e) {
        print("Error updating fan speed: $e");
      }
    }
  }

  Future<void> _submitSchedule() async {
    final from = '${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')}';
    final to = '${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')}';

    try {
      await ApiService.controlVentilation(
        room: room,
        status: isFanOn,
        schedule: {
          "from": from,
          "to": to,
          "days": [],
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ventilation schedule set")),
      );
    } catch (e) {
      print("Error setting schedule: $e");
    }
  }

  Future<void> _pickTime(bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? fromTime : toTime,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromTime = picked;
        } else {
          toTime = picked;
        }
      });
      await _submitSchedule();
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
                      const Text(
                        'Cooling',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
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

              // Temperature Circle
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDEE2E7), Color(0xFFDBE0E7)],
                  ),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Center(
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFCBCED3), Color(0xFFFAFBFC)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('COOLING', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        Text('$temperature', style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        const Icon(Icons.eco, color: Color(0xFF09D542), size: 28),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Fan Speed
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

              // Schedule section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              Row(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
