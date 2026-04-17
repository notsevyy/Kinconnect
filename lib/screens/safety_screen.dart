import 'dart:async';
import 'package:flutter/material.dart';
import '../services/mock_service.dart';
import '../theme/app_colors.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  final _mock = MockService();
  bool _panicTriggered = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _onPanicPressed() {
    _mock.triggerPanicAlert();
    setState(() => _panicTriggered = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _panicTriggered = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _mock.contacts;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 16),
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Safety',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Panic button card
            GestureDetector(
              onLongPress: _panicTriggered ? null : _onPanicPressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color:
                      _panicTriggered ? AppColors.warning : AppColors.critical,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Icon(
                      _panicTriggered
                          ? Icons.check_circle
                          : Icons.emergency,
                      color: Colors.white,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _panicTriggered ? 'ALERT SENT' : 'EMERGENCY',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _panicTriggered
                          ? 'Emergency contacts have been notified'
                          : 'Press and hold to send emergency alert',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Emergency contacts heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark.withAlpha(180),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Contact cards
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contacts.length,
              onReorder: (oldIndex, newIndex) {
                final mutable = List.of(contacts);
                if (newIndex > oldIndex) newIndex--;
                final item = mutable.removeAt(oldIndex);
                mutable.insert(newIndex, item);
                _mock.reorderContacts(mutable);
                setState(() {});
              },
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Container(
                  key: ValueKey(contact.id),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      // Order badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${contact.escalationOrder}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              contact.relationship,
                              style: TextStyle(
                                color: Colors.white.withAlpha(140),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Call pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.activeGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Call',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.drag_handle,
                          color: Colors.white.withAlpha(80)),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Drag contacts to change escalation order',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted.withAlpha(150),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
