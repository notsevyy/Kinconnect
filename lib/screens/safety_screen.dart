import 'dart:async';
import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  final _svc = FirebaseService();
  List<Contact> _contacts = [];
  bool _isLoading = true;
  bool _panicTriggered = false;
  Timer? _resetTimer;
  StreamSubscription<List<Contact>>? _contactSub;

  @override
  void initState() {
    super.initState();
    _contacts = _svc.contacts;
    if (_contacts.isNotEmpty) {
      _isLoading = false;
    }

    _contactSub = _svc.contactStream.listen((contacts) {
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      }
    });

    _seedIfNeeded();
  }

  Future<void> _seedIfNeeded() async {
    await _svc.seedContactsIfEmpty();
    // If still loading after seed attempt and stream hasn't fired yet,
    // stop the spinner so we can show the empty state.
    if (mounted && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _contactSub?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  void _onPanicPressed() {
    _svc.triggerPanicAlert();
    setState(() => _panicTriggered = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _panicTriggered = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  color: _panicTriggered
                      ? AppColors.warning
                      : AppColors.critical,
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

            // Contact cards or empty prompt
            if (_contacts.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.charcoal.withAlpha(10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.charcoal.withAlpha(30),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.person_add_outlined,
                        size: 48,
                        color: AppColors.textMuted.withAlpha(150)),
                    const SizedBox(height: 12),
                    const Text(
                      'No emergency contacts',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add contacts so they can be notified in an emergency',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Add Contact',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _contacts.length,
                onReorder: (oldIndex, newIndex) {
                  final mutable = List.of(_contacts);
                  if (newIndex > oldIndex) newIndex--;
                  final item = mutable.removeAt(oldIndex);
                  mutable.insert(newIndex, item);
                  _svc.reorderContacts(mutable);
                  setState(() {});
                },
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  return Container(
                    key: ValueKey(contact.id),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 5),
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
                              Icon(Icons.call,
                                  color: Colors.white, size: 16),
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
            if (_contacts.isNotEmpty)
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
