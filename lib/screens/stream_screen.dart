import 'package:flutter/material.dart';

class StreamScreen extends StatelessWidget {
  const StreamScreen({super.key});

  final String streamUrl = 'http://192.168.1.100:81/stream'; // Replace with your actual camera stream URL

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView( // 🛠 Prevent overflow
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Live Camera Stream',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Monitor your room in real-time with live HD streaming.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              _buildLiveCameraBox(),
              const SizedBox(height: 20),
              _buildControlsRow(),
              const SizedBox(height: 30),
              _buildStatusInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveCameraBox() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                streamUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Failed to load stream',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Positioned(
              bottom: 12,
              left: 12,
              child: Text(
                'Room: Living Room',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildControlButton(Icons.mic, 'Mic'),
        _buildControlButton(Icons.screenshot_monitor, 'Snapshot'),
        _buildControlButton(Icons.videocam_off, 'Off'),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, size: 26, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildStatusInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('Status: Connected', style: TextStyle(fontSize: 16)),
          Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }
}
