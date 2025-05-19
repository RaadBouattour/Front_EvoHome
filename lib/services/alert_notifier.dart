import 'package:flutter/material.dart';

class AlertNotifier {
  static final AlertNotifier _instance = AlertNotifier._internal();
  factory AlertNotifier() => _instance;
  AlertNotifier._internal();

  OverlayEntry? _overlayEntry;

  void show(BuildContext context, String message) {
    _overlayEntry?.remove(); // Remove existing one if still on screen

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        left: 20,
        right: 20,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context);
    overlay.insert(_overlayEntry!);

    // Auto remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }
}
