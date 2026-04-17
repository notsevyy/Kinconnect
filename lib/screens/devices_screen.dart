import 'package:flutter/material.dart';
import '../models/device_node.dart';
import '../services/mock_service.dart';
import '../theme/app_colors.dart';
import '../widgets/node_card.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _mock = MockService();

  @override
  Widget build(BuildContext context) {
    final nodes = _mock.deviceNodes;
    final hub = _mock.hubStatus;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 16),
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Devices',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hub card
            _HubCard(hub: hub),
            const SizedBox(height: 16),

            // Sensor nodes heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Sensor Nodes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark.withAlpha(180),
                ),
              ),
            ),
            const SizedBox(height: 4),

            ...nodes.map((node) => NodeCard(
                  node: node,
                  onSensitivityChanged: (value) {
                    setState(() {
                      _mock.updateNodeSensitivity(node.id, value);
                    });
                  },
                )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final HubStatus hub;

  const _HubCard({required this.hub});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.hubNavy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hub, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'ESP32-S3 Safety Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.activeGreen.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.activeGreen.withAlpha(100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.activeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: AppColors.activeGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HubPill(
                icon: hub.networkMode == NetworkMode.lte
                    ? Icons.signal_cellular_alt
                    : Icons.wifi,
                label: hub.networkMode == NetworkMode.lte
                    ? 'LTE ${hub.lteSignal}%'
                    : 'WiFi ${hub.lteSignal}%',
              ),
              const SizedBox(width: 8),
              _HubPill(
                icon: Icons.battery_charging_full,
                label: 'UPS ${hub.upsBattery}%',
              ),
              const SizedBox(width: 8),
              _HubPill(
                icon: Icons.timer_outlined,
                label:
                    '${hub.uptime.inHours}h ${hub.uptime.inMinutes % 60}m',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HubPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HubPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withAlpha(180)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
