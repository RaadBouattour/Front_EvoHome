import 'package:flutter/material.dart';
import 'dart:async';

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  int _secondsRemaining = 59;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              Image.asset('assets/images/verify_code_illustration.png', height: 200),
              const SizedBox(height: 16),
              Text(
                '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Verification Code',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please confirm the security code received on your registered email.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 40,
                    child: TextField(
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: const InputDecoration(counterText: ''),
                      keyboardType: TextInputType.number,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/reset-password');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF62A7FA),
                    elevation: 0, // 👈 No shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // 👈 Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      color: Colors.white,        // 👈 White text
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
              ,
              const SizedBox(height: 12),
              const Text("Did not receive the code?"),
              TextButton(
                onPressed: () {
                  setState(() {
                    _secondsRemaining = 59;
                  });
                  _timer.cancel();
                  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                    setState(() {
                      _secondsRemaining--;
                    });
                    if (_secondsRemaining <= 0) {
                      timer.cancel();
                    }
                  });
                },
                child: const Text(
                  'Send Again',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
