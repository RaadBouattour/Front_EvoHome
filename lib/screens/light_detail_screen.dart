import 'package:flutter/material.dart';
import 'dart:math' as math;

class LightDetailScreen extends StatefulWidget {
  const LightDetailScreen({super.key});

  @override
  State<LightDetailScreen> createState() => _LightDetailScreenState();
}

class _LightDetailScreenState extends State<LightDetailScreen> {
  bool isLightOn = false;
  double brightness = 70;
  double intensity = 70;

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

  TimeOfDay fromTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay toTime = const TimeOfDay(hour: 12, minute: 0);

  void _updateBrightness(Offset localPosition, Size size) {
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
              // ✅ Lamp image that scrolls with content
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
                            const Text(
                              'Smart Light',
                              style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Switch(
                              value: isLightOn,
                              activeColor: Colors.yellow[700],
                              onChanged: (val) => setState(() => isLightOn = val),
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
                          Text('${brightness.round()}%',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          const Text('Brightness', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schedule',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('From ', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        TextButton(
                          onPressed: () async {
                            TimeOfDay? picked =
                            await showTimePicker(context: context, initialTime: fromTime);
                            if (picked != null) setState(() => fromTime = picked);
                          },
                          child: Row(
                            children: [
                              Text(fromTime.format(context),
                                  style: const TextStyle(color: Colors.black, fontSize: 16)),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text('To ', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        TextButton(
                          onPressed: () async {
                            TimeOfDay? picked =
                            await showTimePicker(context: context, initialTime: toTime);
                            if (picked != null) setState(() => toTime = picked);
                          },
                          child: Row(
                            children: [
                              Text(toTime.format(context),
                                  style: const TextStyle(color: Colors.black, fontSize: 16)),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Intensity',
                          style: TextStyle(
                            fontSize: 20.17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text('${intensity.round()}%',
                          style: const TextStyle(
                            fontSize: 17.48,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbColor: Colors.yellow,
                        activeTrackColor: Colors.black,
                        inactiveTrackColor: Colors.black12,
                      ),
                      child: Slider(
                        value: intensity,
                        min: 0,
                        max: 100,
                        divisions: 10,
                        onChanged: (value) => setState(() => intensity = value),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('off', style: TextStyle(color: Color(0xFF9CABC2))),
                        Text('100%', style: TextStyle(color: Color(0xFF9CABC2))),
                      ],
                    ),
                  ],
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
