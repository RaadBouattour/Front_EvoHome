import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LightDetailScreen extends StatefulWidget {
  const LightDetailScreen({super.key});

  @override
  State<LightDetailScreen> createState() => _LightDetailScreenState();
}

class _LightDetailScreenState extends State<LightDetailScreen> {
  bool isLightOn = false;
  double brightness = 70;
  TimeOfDay fromTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay toTime = const TimeOfDay(hour: 12, minute: 0);

  String lightId = '';
  String roomName = '';

  bool _isScheduled = false;

  double imageHeight = 200;
  double imageTopOffset = -47;
  double imageLeftOffset = 290;

  double arcTopOffset = 40;
  double arcLeftOffset = 10;
  double arcSize = 310;
  double rotationAngleDeg = 90;
  double brightnessTextTop = 150;
  double brightnessTextLeft = 270;

  double labelLowX = -30;
  double labelLowY = 5;
  double labelHighX = -10;
  double labelHighY = 5;
  double labelLowRotationDeg = -77;
  double labelHighRotationDeg = -100;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      setState(() {
        isLightOn = args['state'] ?? false;
        brightness = (args['brightness'] ?? 70).toDouble();
        lightId = args['id'] ?? '';
        roomName = args['room'] ?? '';
      });
    }

    if (lightId.isNotEmpty) {
      _fetchSchedule();          // ⏰ fetch schedule
      _fetchCurrentLightState(); // ✅ sync light toggle
    }

  }

  Future<void> _fetchSchedule() async {
    try {
      final schedule = await ApiService.fetchSchedule(
        deviceType: 'light',
        deviceId: lightId,
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

  Future<void> _toggleLight(bool value) async {
    setState(() => isLightOn = value);
    try {
      await ApiService.toggleLight(room: roomName, status: value);
      Fluttertoast.showToast(msg: "Light \${value ? 'ON' : 'OFF'}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  Future<void> _updateSchedule() async {
    if (isLightOn) {
      Fluttertoast.showToast(msg: "Please turn off the light to schedule it ❌");
      return;
    }

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

    final from = '${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')}';
    final to = '${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')}';

    try {
      await ApiService.toggleLight(
        room: roomName,
        status: false,
        schedule: {"from": from, "to": to},
      );
      Fluttertoast.showToast(msg: "Schedule updated ✅");
      setState(() => _isScheduled = true);
    } catch (e) {
      Fluttertoast.showToast(msg: "Schedule error: $e");
    }
  }

  Future<void> _fetchCurrentLightState() async {
    try {
      final status = await ApiService.getDeviceStatusById(lightId);
      debugPrint('🔦 Light $lightId fetched status: $status');

      if (!mounted) return;
      setState(() {
        isLightOn = status == true;
      });
    } catch (e) {
      debugPrint('❌ Failed to fetch light status: $e');
    }
  }


  Future<void> _deleteSchedule() async {
    final success = await ApiService.deleteScheduleByDevice("light", lightId);
    if (success) {
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


  void _updateBrightness(Offset localPosition, Size size) async {
    final center = Offset(size.width / 2, size.height);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    double angle = math.atan2(dy, dx);
    angle -= rotationAngleDeg * math.pi / 180;
    double percent = ((angle + math.pi) / math.pi).clamp(0.0, 1.0);
    double newBrightness = (percent * 100).clamp(0, 100);

    setState(() {
      brightness += (newBrightness - brightness) * 0.2;
    });

    try {
      await ApiService.toggleLight(
        room: roomName,
        status: isLightOn,
        brightness: brightness.round(),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Brightness error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Positioned(
                    top: imageTopOffset,
                    left: imageLeftOffset,
                    child: SizedBox(
                      height: imageHeight,
                      child: Image.asset('assets/images/light.png', fit: BoxFit.contain),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 10),
                            const Text('Smart Light', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Switch(
                              value: isLightOn,
                              activeColor: Colors.yellow[700],
                              onChanged: _toggleLight,
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 350,
                child: Stack(
                  children: [
                    Positioned(
                      top: arcTopOffset,
                      left: arcLeftOffset,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          _updateBrightness(details.localPosition, Size(arcSize, arcSize));
                        },
                        child: Transform.rotate(
                          angle: rotationAngleDeg * math.pi / 180,
                          child: CustomPaint(
                            painter: BrightnessArcPainter(
                              brightness,
                              labelLowX,
                              labelLowY,
                              labelHighX,
                              labelHighY,
                              labelLowRotationDeg,
                              labelHighRotationDeg,
                            ),
                            size: Size(arcSize, arcSize),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: brightnessTextTop,
                      left: brightnessTextLeft,
                      child: Column(
                        children: [
                          Text('${brightness.round()}%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          const Text('Brightness', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _deleteSchedule,
                      tooltip: 'Delete schedule',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isScheduled ? Colors.yellow.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isScheduled ? Colors.yellow[800]! : Colors.grey.withOpacity(0.3)),
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
                        onPressed: _updateSchedule,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class BrightnessArcPainter extends CustomPainter {
  final double brightness;
  final double labelLowX;
  final double labelLowY;
  final double labelHighX;
  final double labelHighY;
  final double labelLowRotationDeg;
  final double labelHighRotationDeg;

  BrightnessArcPainter(
      this.brightness,
      this.labelLowX,
      this.labelLowY,
      this.labelHighX,
      this.labelHighY,
      this.labelLowRotationDeg,
      this.labelHighRotationDeg,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height), radius: size.width / 2);
    final startAngle = math.pi;
    final sweepAngle = math.pi * (brightness / 100);

    final arcPaint = Paint()
      ..shader = const LinearGradient(colors: [Colors.greenAccent, Colors.yellowAccent]).createShader(rect)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final knobPaint = Paint()..color = Colors.orangeAccent;

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    final knobAngle = startAngle + sweepAngle;
    final knobX = size.width / 2 + (size.width / 2) * math.cos(knobAngle);
    final knobY = size.height + (size.width / 2) * math.sin(knobAngle);
    canvas.drawCircle(Offset(knobX, knobY), 10, knobPaint);

    final textPainterLow = TextPainter(
      text: const TextSpan(text: 'Low', style: TextStyle(color: Colors.black, fontSize: 12)),
      textDirection: TextDirection.ltr,
    )..layout();

    final textPainterHigh = TextPainter(
      text: const TextSpan(text: 'High', style: TextStyle(color: Colors.black, fontSize: 12)),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(labelLowX, size.height - labelLowY);
    canvas.rotate(labelLowRotationDeg * math.pi / 180);
    textPainterLow.paint(canvas, Offset.zero);
    canvas.restore();

    canvas.save();
    canvas.translate(size.width - labelHighX, size.height - labelHighY);
    canvas.rotate(labelHighRotationDeg * math.pi / 180);
    textPainterHigh.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}