import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../main.dart';
import 'elder_home_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  String? _selectedMode;
  bool _saving = false;

  Future<void> _continue() async {
    if (_selectedMode == null) return;
    setState(() => _saving = true);

    await AuthService().setUiMode(_selectedMode!);

    if (!mounted) return;

    FirebaseService().startSimulation();

    final Widget destination = _selectedMode == 'elder'
        ? const ElderHomeScreen()
        : const MainShell();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Text(
                'How will you\nuse KinConnect?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'You can change this later in Settings',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Caregiver card
              _ModeCard(
                selected: _selectedMode == 'caregiver',
                icon: Icons.people_outline,
                title: 'I am a Caregiver',
                description:
                    'Managing and monitoring a loved one',
                color: AppColors.bathroom,
                onTap: () => setState(() => _selectedMode = 'caregiver'),
              ),
              const SizedBox(height: 16),

              // Elder card
              _ModeCard(
                selected: _selectedMode == 'elder',
                icon: Icons.person_outline,
                title: 'I am using this\nfor myself',
                description:
                    'Simple, easy-to-use elder mode',
                color: AppColors.livingRoom,
                onTap: () => setState(() => _selectedMode = 'elder'),
              ),

              const Spacer(),

              // Continue button
              ElevatedButton(
                onPressed:
                    _selectedMode != null && !_saving ? _continue : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Continue'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(20) : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected ? color.withAlpha(30) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: selected ? color : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: selected ? color : AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 28)
            else
              Icon(Icons.circle_outlined,
                  color: Colors.grey.shade300, size: 28),
          ],
        ),
      ),
    );
  }
}
