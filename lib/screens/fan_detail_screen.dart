import 'package:flutter/material.dart';

class FanDetailScreen extends StatefulWidget {
  const FanDetailScreen({super.key});

  @override
  State<FanDetailScreen> createState() => _FanDetailScreenState();
}

class _FanDetailScreenState extends State<FanDetailScreen> {
  bool isFanOn = false;
  int temperature = 22;
  int fanSpeed = 1;

  TimeOfDay fromTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay toTime = const TimeOfDay(hour: 12, minute: 0);

  double imageHeight = 210;
  static const Color oceanBlue = Color(0xFF0077B6);

  void _changeFanSpeed(bool increase) {
    setState(() {
      if (increase) {
        fanSpeed = fanSpeed < 5 ? fanSpeed + 1 : 5;
      } else {
        fanSpeed = fanSpeed > 1 ? fanSpeed - 1 : 1;
      }
    });
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                        onChanged: (val) => setState(() => isFanOn = val),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: imageHeight,
                    child: Image.asset(
                      'assets/images/fan.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Temperature circle
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment(0.33, 0.04),
                    end: Alignment(0.74, 0.94),
                    colors: [Color(0xFFDEE2E7), Color(0xFFDBE0E7)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 40,
                      offset: Offset(0, 20),
                    ),
                    BoxShadow(
                      color: Color(0x7F8E9BAE),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment(0.58, 0.07),
                        end: Alignment(0.63, 0.12),
                        colors: [Color(0xFFCBCED3), Color(0xFFFAFBFC)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'COOLING',
                          style: TextStyle(
                            color: Color(0x993C3C43),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.38,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$temperature',
                          style: const TextStyle(
                            color: Color(0xFF3C3C43),
                            fontSize: 50,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
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
                  Text(
                    'Speed $fanSpeed',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: oceanBlue,
                    ),
                  ),
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Schedule',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('From ', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  TextButton(
                    onPressed: () => _pickTime(true),
                    child: Row(
                      children: [
                        Text(
                          fromTime.format(context),
                          style: const TextStyle(color: Colors.black, fontSize: 16),
                        ),
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
                        Text(
                          toTime.format(context),
                          style: const TextStyle(color: Colors.black, fontSize: 16),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
