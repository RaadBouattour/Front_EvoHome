import 'package:flutter/material.dart';
import '../services/socket_service.dart'; // use your SocketService with getNotifications()

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);
    try {
      final res = await SocketService.getNotifications();
      setState(() {
        notifications = res;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Failed to fetch notifications: $e");
      setState(() => isLoading = false);
    }
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'alarm':
        return Icons.warning_amber;
      case 'system':
        return Icons.memory;
      case 'performance':
        return Icons.bar_chart;
      case 'intervention':
        return Icons.build_circle;
      case 'alert':
        return Icons.notifications_active;
      default:
        return Icons.notifications;
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return Colors.redAccent;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("No notifications yet"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final type = notif['type'] ?? 'alert';
          final message = notif['message'] ?? '';
          final level = notif['level'] ?? 'info';
          final room = notif['room'] ?? 'Unknown room';
          final receivedAt = notif['receivedAt'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getLevelColor(level),
                child: Icon(_getIcon(type), color: Colors.white),
              ),
              title: Text(message),
              subtitle: Text("Room: $room"),
              trailing: Text(
                receivedAt.toString().substring(0, 10),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
