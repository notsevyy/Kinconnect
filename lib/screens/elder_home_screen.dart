import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact.dart';
import '../services/auth_service.dart';
import '../services/mock_service.dart';
import '../theme/app_colors.dart';
import 'are_you_okay_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class ElderHomeScreen extends StatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  State<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends State<ElderHomeScreen>
    with SingleTickerProviderStateMixin {
  final _svc = MockService();
  final _auth = AuthService();
  bool _sosHolding = false;
  double _sosProgress = 0.0;
  AnimationController? _sosController;
  Timer? _sosTimer;
  Timer? _checkTimer;
  StreamSubscription? _alertSub;
  bool _checkShown = false;

  @override
  void initState() {
    super.initState();
    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _sosController!.addListener(() {
      setState(() => _sosProgress = _sosController!.value);
    });
    _sosController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerSos();
      }
    });

    // Check if alert already active
    if (_svc.hasActiveAlert && !_checkShown) {
      _scheduleCheck();
    }

    // Listen for new alerts
    _alertSub = _svc.alertStream.listen((_) {
      if (_svc.hasActiveAlert && !_checkShown) {
        _scheduleCheck();
      }
    });
  }

  void _scheduleCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted || _checkShown) return;
      _checkShown = true;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AreYouOkayScreen()),
      );
    });
  }

  @override
  void dispose() {
    _sosController?.dispose();
    _sosTimer?.cancel();
    _checkTimer?.cancel();
    _alertSub?.cancel();
    super.dispose();
  }

  void _onSosStart() {
    setState(() => _sosHolding = true);
    _sosController!.forward(from: 0.0);
  }

  void _onSosEnd() {
    if (_sosController!.status != AnimationStatus.completed) {
      _sosController!.reset();
      setState(() {
        _sosHolding = false;
        _sosProgress = 0.0;
      });
    }
  }

  void _triggerSos() {
    _svc.triggerPanicAlert();
    setState(() {
      _sosHolding = false;
      _sosProgress = 0.0;
    });
    _sosController!.reset();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.check_circle, color: AppColors.activeGreen, size: 48),
        title: const Text(
          'SOS Sent',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Emergency alert has been sent to all your contacts.',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('OK', style: TextStyle(fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }

  String _currentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[now.month - 1]} ${now.day}, $hour:$minute $period';
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontSize: 22)),
        content: const Text('Are you sure?', style: TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _auth.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.critical, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seniorName = _auth.seniorName ?? _auth.userName ?? 'Friend';
    final hasAlert = _svc.hasActiveAlert;
    final contacts = _svc.contacts.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with settings
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $seniorName',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentTime(),
                          style: const TextStyle(
                            fontSize: 20,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: AppColors.charcoal,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Status pill
              _StatusPill(hasAlert: hasAlert),
              const SizedBox(height: 32),

              // SOS Button
              _SosButton(
                holding: _sosHolding,
                progress: _sosProgress,
                onLongPressStart: _onSosStart,
                onLongPressEnd: _onSosEnd,
              ),
              const SizedBox(height: 32),

              // Quick call buttons
              if (contacts.isNotEmpty) ...[
                const Text(
                  'Quick Call',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _ContactGrid(contacts: contacts),
                const SizedBox(height: 32),
              ],

              // Footer
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.activeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Monitored by KinConnect',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Sign out
              Center(
                child: TextButton(
                  onPressed: _signOut,
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------- Status Pill ---------------

class _StatusPill extends StatelessWidget {
  final bool hasAlert;

  const _StatusPill({required this.hasAlert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: hasAlert
            ? AppColors.critical.withAlpha(12)
            : AppColors.activeGreen.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasAlert
              ? AppColors.critical.withAlpha(50)
              : AppColors.activeGreen.withAlpha(50),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: hasAlert ? AppColors.critical : AppColors.activeGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            hasAlert ? 'Alert Active' : 'All is Well',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: hasAlert ? AppColors.critical : AppColors.activeGreen,
            ),
          ),
        ],
      ),
    );
  }
}

// --------------- SOS Button ---------------

class _SosButton extends StatelessWidget {
  final bool holding;
  final double progress;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const _SosButton({
    required this.holding,
    required this.progress,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.critical.withAlpha(220),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.critical.withAlpha(50),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Progress overlay
            if (holding)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: MediaQuery.of(context).size.width * progress,
                    color: Colors.white.withAlpha(40),
                  ),
                ),
              ),
            // Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emergency, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    holding
                        ? 'Hold... ${(2 - (progress * 2)).clamp(0, 2).toStringAsFixed(0)}s'
                        : 'SOS — Call for Help',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (!holding)
                    Text(
                      'Press and hold for 2 seconds',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(180),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------- Contact Grid ---------------

class _ContactGrid extends StatelessWidget {
  final List<Contact> contacts;

  const _ContactGrid({required this.contacts});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: contacts.map((c) => _ContactButton(contact: c)).toList(),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final Contact contact;

  const _ContactButton({required this.contact});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 60) / 2,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.cardWhite.withAlpha(180),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200.withAlpha(120)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              final phone = contact.phone.replaceAll(RegExp(r'[^\d+]'), '');
              final uri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name.split(' ').first,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          contact.relationship,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


