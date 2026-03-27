import 'package:flutter/material.dart';
import '../models/device_node.dart';
import '../theme/app_colors.dart';

class NodeCard extends StatelessWidget {
  final DeviceNode node;
  final ValueChanged<double> onSensitivityChanged;

  const NodeCard({
    super.key,
    required this.node,
    required this.onSensitivityChanged,
  });

  String _lastPingText() {
    final diff = DateTime.now().difference(node.lastPing);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.roomColor(node.roomName);
    final isLowBattery = node.batteryPercent < 30;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Offline/warning stripe
          if (isLowBattery)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: AppColors.critical,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Low Battery',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        node.roomName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Text(
                      'Ping: ${_lastPingText()}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(160),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Stats row
                Row(
                  children: [
                    _PillStat(
                      icon: Icons.battery_std,
                      label: '${node.batteryPercent}%',
                    ),
                    const SizedBox(width: 8),
                    _PillStat(
                      icon: Icons.signal_cellular_alt,
                      label: '${node.signalStrength}%',
                    ),
                    const SizedBox(width: 8),
                    _PillStat(
                      icon: Icons.circle,
                      label: 'Online',
                      iconSize: 8,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Sensitivity slider
                Row(
                  children: [
                    Text(
                      'mmWave',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(node.sensitivity * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withAlpha(50),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withAlpha(30),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: node.sensitivity,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    onChanged: onSensitivityChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double iconSize;

  const _PillStat({
    required this.icon,
    required this.label,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
