import 'package:flutter/material.dart';
import '../services/mock_service.dart';
import '../theme/app_colors.dart';

class AreYouOkayScreen extends StatefulWidget {
  const AreYouOkayScreen({super.key});

  @override
  State<AreYouOkayScreen> createState() => _AreYouOkayScreenState();
}

class _AreYouOkayScreenState extends State<AreYouOkayScreen>
    with TickerProviderStateMixin {
  final _svc = MockService();

  late AnimationController _countdownController;
  late AnimationController _pulseController;

  bool _escalated = false;

  @override
  void initState() {
    super.initState();

    // 30-second countdown (value goes 1.0 → 0.0)
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_escalated) {
        _escalate();
      }
    });
    _countdownController.forward();

    // Pulsing amber icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.85,
      upperBound: 1.0,
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _dismiss() {
    // Acknowledge all unacknowledged alerts
    for (final alert in _svc.alerts) {
      if (!alert.acknowledged) {
        _svc.acknowledgeAlert(alert.id);
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _escalate() {
    if (_escalated) return;
    setState(() => _escalated = true);
    _countdownController.stop();
    _svc.triggerPanicAlert();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.emergency, color: AppColors.critical, size: 48),
        title: const Text(
          'Help Is On the Way',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Emergency alert has been sent to all your contacts.',
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Text('OK', style: TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Pulsing warning icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseController.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(30),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.warning.withAlpha(120),
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Headline
                const Text(
                  'Are you okay?',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Subtext
                const Text(
                  'We noticed you haven\'t moved in a while.\nLet us know you\'re safe.',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Countdown ring
                AnimatedBuilder(
                  animation: _countdownController,
                  builder: (context, child) {
                    final remaining = (30 * (1.0 - _countdownController.value))
                        .ceil()
                        .clamp(0, 30);
                    return SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: CircularProgressIndicator(
                              value: 1.0 - _countdownController.value,
                              strokeWidth: 8,
                              backgroundColor: AppColors.warning.withAlpha(40),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                remaining <= 10
                                    ? AppColors.critical
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                          Text(
                            '$remaining',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: remaining <= 10
                                  ? AppColors.critical
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const Spacer(flex: 2),

                // Two buttons side by side
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 80,
                        child: ElevatedButton(
                          onPressed: _dismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.activeGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Yes, I\'m\nfine',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 80,
                        child: ElevatedButton(
                          onPressed: _escalate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.critical,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Get Help',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Footer
                const Text(
                  'If you need help, press Get Help\nor wait for auto-escalation',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
