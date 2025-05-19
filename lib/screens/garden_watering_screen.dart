import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GardenWateringScreen extends StatefulWidget {
  const GardenWateringScreen({super.key});

  @override
  State<GardenWateringScreen> createState() => _GardenWateringScreenState();
}

class _GardenWateringScreenState extends State<GardenWateringScreen> {
  String pumpId = '';
  String room = '';
  bool isPumpOn = false;
  int pumpSpeed = 1;
  double humidityLevel = 42.2;

  TimeOfDay fromTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay toTime = const TimeOfDay(hour: 12, minute: 0);

  static const Color greenAccent = Color(0xFF4CAF50);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      pumpId = args['id'] ?? '';
      room = args['room'] ?? 'jardin';
      isPumpOn = args['state'] ?? false;
      pumpSpeed = args['speed'] ?? 1;

      final schedule = args['schedule'];
      if (schedule != null) {
        final fromParts = (schedule['from'] as String?)?.split(':');
        final toParts = (schedule['to'] as String?)?.split(':');
        if (fromParts?.length == 2 && toParts?.length == 2) {
          fromTime = TimeOfDay(hour: int.parse(fromParts![0]), minute: int.parse(fromParts[1]));
          toTime = TimeOfDay(hour: int.parse(toParts![0]), minute: int.parse(toParts[1]));
        }
      }

      debugPrint("🆔 Pump ID: $pumpId");
      debugPrint("📍 Room: $room");
      debugPrint("🔘 State: $isPumpOn");
      debugPrint("⚙️ Speed: $pumpSpeed");
      debugPrint("🗓 Schedule: ${fromTime.format(context)} → ${toTime.format(context)}");
    }
  }

  Future<void> _togglePump(bool value) async {
    try {
      await ApiService.controlPump(
        room: room,
        status: value,
      );
      setState(() {
        isPumpOn = value;
        if (isPumpOn && pumpSpeed == 0) pumpSpeed = 1;
      });
    } catch (e) {
      print("❌ Error toggling pump: $e");
    }
  }

  Future<void> _changePumpSpeed(bool increase) async {
    if (!isPumpOn) return;

    final newSpeed = increase
        ? (pumpSpeed < 3 ? pumpSpeed + 1 : 3)
        : (pumpSpeed > 1 ? pumpSpeed - 1 : 1);

    if (newSpeed != pumpSpeed) {
      try {
        await ApiService.controlPump(
          room: room,
          status: isPumpOn,
          speed: newSpeed,
        );
        setState(() => pumpSpeed = newSpeed);
      } catch (e) {
        print("❌ Error updating pump speed: $e");
      }
    }
  }

  Future<void> _submitSchedule() async {
    final from = '${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')}';
    final to = '${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')}';

    try {
      await ApiService.controlPump(
        room: room,
        status: isPumpOn,
        schedule: {
          "from": from,
          "to": to,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Pump schedule set")),
      );
    } catch (e) {
      print("❌ Error setting schedule: $e");
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
              // Header
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

              // Humidity circle
              Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFDAEFEA), Color(0xFFE6F4EA)]),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('HUMIDITY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 5),
                      Text('${humidityLevel.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 46, fontWeight: FontWeight.bold)),
                      const Icon(Icons.grass, color: greenAccent, size: 28),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Speed controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    iconSize: 32,
                    color: isPumpOn ? greenAccent : Colors.grey,
                    onPressed: () => _changePumpSpeed(false),
                  ),
                  Text('Speed $pumpSpeed',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: isPumpOn ? greenAccent : Colors.grey)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    iconSize: 32,
                    color: isPumpOn ? greenAccent : Colors.grey,
                    onPressed: () => _changePumpSpeed(true),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Schedule
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
