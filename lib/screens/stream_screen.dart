import 'package:flutter/material.dart';

class StreamScreen extends StatefulWidget {
  const StreamScreen({super.key});

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  final String streamUrl = 'http://192.168.40.166:5000'; // your stream URL
  bool streamLoaded = false;
  bool hasError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
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
              _buildFullScreenButton(),
              const SizedBox(height: 30),
              _buildDynamicStatusInfo(),
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
                  if (progress == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!streamLoaded) {
                        setState(() {
                          streamLoaded = true;
                          hasError = false;
                        });
                      }
                    });
                    return child;
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!hasError) {
                      setState(() {
                        streamLoaded = false;
                        hasError = true;
                      });
                    }
                  });
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
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenButton() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenStreamView(streamUrl: streamUrl),
            ),
          );
        },
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.fullscreen, size: 30, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            const Text('Open Stream', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicStatusInfo() {
    final isConnected = streamLoaded && !hasError;

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
        children: [
          Text(
            'Status: ${isConnected ? 'Connected' : 'Not Connected'}',
            style: TextStyle(fontSize: 16, color: isConnected ? Colors.green : Colors.red),
          ),
          Icon(
            isConnected ? Icons.check_circle : Icons.cancel,
            color: isConnected ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}

class FullScreenStreamView extends StatelessWidget {
  final String streamUrl;

  const FullScreenStreamView({super.key, required this.streamUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Live Stream', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Image.network(
          streamUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'Failed to load stream',
              style: TextStyle(color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}
