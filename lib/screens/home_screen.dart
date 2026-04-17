import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/room.dart';
import '../models/device_node.dart';
import '../services/auth_service.dart';
import '../services/mock_service.dart';
import '../theme/app_colors.dart';
import '../widgets/alert_banner.dart';
import '../widgets/room_card.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _mock = MockService();
  late List<Room> _rooms;
  Alert? _activeAlert;
  StreamSubscription<List<Room>>? _roomSub;
  StreamSubscription<Alert>? _alertSub;

  @override
  void initState() {
    super.initState();
    _rooms = _mock.rooms;
    _activeAlert = _mock.alerts.where((a) => !a.acknowledged).isNotEmpty
        ? _mock.alerts.lastWhere((a) => !a.acknowledged)
        : null;

    _roomSub = _mock.roomStream.listen((rooms) {
      if (mounted) setState(() => _rooms = rooms);
    });

    _alertSub = _mock.alertStream.listen((alert) {
      if (mounted) setState(() => _activeAlert = alert);
    });
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _alertSub?.cancel();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final hub = _mock.hubStatus;
    final auth = AuthService();
    final userName = auth.userName ?? 'Caregiver';
    final seniorName = auth.seniorName ?? 'your loved one';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() => _rooms = _mock.rooms),
          child: ListView(
            padding: const EdgeInsets.only(top: 16),
            children: [
              // Greeting header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_greeting()}, $userName',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Monitoring $seniorName',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/images/logo.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: AppColors.charcoal,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status banner
              AlertBanner(
                activeAlert: _activeAlert,
                onAcknowledge: _activeAlert != null
                    ? () {
                        _mock.acknowledgeAlert(_activeAlert!.id);
                        setState(() => _activeAlert = null);
                      }
                    : null,
              ),
              const SizedBox(height: 8),

              // Rooms section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'Rooms',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark.withAlpha(180),
                  ),
                ),
              ),
              ..._rooms.map((room) => RoomCard(room: room)),
              const SizedBox(height: 16),

              // Connectivity pills
              _ConnectivityStrip(hub: hub),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectivityStrip extends StatelessWidget {
  final HubStatus hub;

  const _ConnectivityStrip({required this.hub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _Pill(
            icon: hub.networkMode == NetworkMode.lte
                ? Icons.signal_cellular_alt
                : Icons.wifi,
            label: hub.networkMode == NetworkMode.lte
                ? 'LTE ${hub.lteSignal}%'
                : 'WiFi ${hub.lteSignal}%',
          ),
          const SizedBox(width: 8),
          _Pill(
            icon: Icons.battery_charging_full,
            label: 'UPS ${hub.upsBattery}%',
          ),
          const SizedBox(width: 8),
          _Pill(
            icon: Icons.timer_outlined,
            label: '${hub.uptime.inHours}h ${hub.uptime.inMinutes % 60}m',
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.charcoal.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
