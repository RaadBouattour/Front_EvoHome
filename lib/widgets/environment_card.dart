import 'package:flutter/material.dart';

class EnvironmentCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const EnvironmentCard({super.key, this.data = const {}});

  bool _isDanger(String key, String value) {
    try {
      final val = double.parse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
      switch (key.toLowerCase()) {
        case 'temperature':
          return val > 40 || val < 0;
        case 'humidity':
          return val > 80 || val < 20;
        case 'gas':
          return val > 300;
        case 'flame':
          return val > 0;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  IconData _getIconForSensor(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat_outlined;
      case 'humidity':
        return Icons.water_drop_outlined;
      case 'gas':
      case 'mq2':
        return Icons.warning_amber_rounded;
      case 'flame':
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
      case 'gas':
        return 'Gas Level';
      case 'flame':
        return 'Flame Detection';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temperature = data['temperature'] ?? '25 °C';
    final humidity = data['humidity'] ?? '66 %';
    final gas = data['gas']?.toString() ?? '477';
    final flame = data['flame']?.toString() ?? 'false';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF828094),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoItem(
                icon: _getIconForSensor('temperature'),
                value: temperature,
                label: 'Temperature',
                isDanger: _isDanger('temperature', temperature),
              ),
              _InfoItem(
                icon: _getIconForSensor('humidity'),
                value: humidity,
                label: 'Humidity',
                isDanger: _isDanger('humidity', humidity),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoItem(
                icon: _getIconForSensor('gas'),
                value: gas,
                label: 'Gas Level',
                isDanger: _isDanger('gas', gas),
              ),
              _InfoItem(
                icon: _getIconForSensor('flame'),
                value: flame,
                label: 'Flame Detection',
                isDanger: _isDanger('flame', flame),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDanger;

  const _InfoItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDanger,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDanger ? Colors.redAccent : Colors.white,
          size: 26,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: isDanger ? Colors.redAccent : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
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
