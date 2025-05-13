import 'package:flutter/material.dart';

class EnvironmentCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const EnvironmentCard({super.key, this.data = const {}});

  @override
  Widget build(BuildContext context) {
    final items = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF828094),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate((items.length / 2).ceil(), (rowIndex) {
          final rowItems = items.skip(rowIndex * 2).take(2).toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: rowItems.map((entry) {
                final sensorType = entry.key;
                final value = entry.value.toString();
                return _InfoItem(
                  icon: _getIconForSensor(sensorType),
                  value: value,
                  label: _getLabelForSensor(sensorType),
                );
              }).toList(),
            ),
          );
        }),
      ),
    );
  }

  IconData _getIconForSensor(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.opacity;
      case 'mq2':
        return Icons.warning_amber;
      case 'flame sensor':
        return Icons.local_fire_department;
      default:
        return Icons.sensors;
    }
  }

  String _getLabelForSensor(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
        return 'Temperature';
      case 'humidity':
        return 'Humidity';
      case 'mq2':
        return 'Gas Level';
      case 'flame sensor':
        return 'Flame Detection';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 26),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
