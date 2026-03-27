import 'dart:async';
import 'package:flutter/material.dart';
import '../models/activity_log.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/activity_tile.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _svc = FirebaseService();
  List<ActivityLog> _logs = [];
  bool _isLoading = true;
  StreamSubscription<List<ActivityLog>>? _activitySub;
  String? _selectedRoom;

  static const _roomFilters = [
    'All',
    'Living Room',
    'Bedroom',
    'Bathroom',
    'Kitchen',
  ];

  @override
  void initState() {
    super.initState();
    _logs = _svc.activityLogs;
    if (_logs.isNotEmpty) {
      _isLoading = false;
    }

    _activitySub = _svc.activityStream.listen((logs) {
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    });

    _seedIfNeeded();
  }

  Future<void> _seedIfNeeded() async {
    await _svc.seedAlertsIfEmpty();
  }

  @override
  void dispose() {
    _activitySub?.cancel();
    super.dispose();
  }

  List<ActivityLog> get _filteredLogs {
    if (_selectedRoom == null || _selectedRoom == 'All') return _logs;
    return _logs.where((l) => l.roomName == _selectedRoom).toList();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _svc.dailyRoomSummary;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Activity',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Daily summary
            _DailySummary(summary: summary),
            const SizedBox(height: 4),

            // Pill filters
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemCount: _roomFilters.length,
                itemBuilder: (_, i) {
                  final filter = _roomFilters[i];
                  final isSelected = (_selectedRoom ?? 'All') == filter;
                  final color = filter == 'All'
                      ? AppColors.charcoal
                      : AppColors.roomColor(filter);
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedRoom = filter;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Timeline label
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark.withAlpha(180),
                ),
              ),
            ),

            // Timeline
            Expanded(
              child: _filteredLogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.show_chart,
                              size: 64,
                              color: AppColors.textMuted.withAlpha(120)),
                          const SizedBox(height: 16),
                          const Text(
                            'No activity yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Activity will appear as sensors detect movement',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredLogs.length,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemBuilder: (context, index) =>
                          ActivityTile(log: _filteredLogs[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailySummary extends StatelessWidget {
  final Map<String, Duration> summary;

  const _DailySummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) return const SizedBox.shrink();

    final totalMinutes =
        summary.values.map((d) => d.inMinutes).fold(0, (a, b) => a + b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: TextStyle(
              color: Colors.white.withAlpha(160),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: summary.entries.map((e) {
                  final fraction = totalMinutes > 0
                      ? e.value.inMinutes / totalMinutes
                      : 0.0;
                  return Expanded(
                    flex: (fraction * 100).round().clamp(1, 100),
                    child: Container(
                      color: AppColors.roomColor(e.key),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: summary.entries.map((e) {
              final mins = e.value.inMinutes;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.roomColor(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${e.key} ${mins >= 60 ? "${mins ~/ 60}h ${mins % 60}m" : "${mins}m"}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
