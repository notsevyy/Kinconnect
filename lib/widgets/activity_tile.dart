import 'package:flutter/material.dart';
import '../models/activity_log.dart';
import '../theme/app_colors.dart';

class ActivityTile extends StatelessWidget {
  final ActivityLog log;

  const ActivityTile({super.key, required this.log});

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  IconData _eventIcon() {
    if (log.isAnomaly) return Icons.report_problem;
    switch (log.eventType) {
      case 'Motion Detected':
        return Icons.directions_walk;
      case 'Presence Active':
        return Icons.person;
      case 'Stillness Detected':
        return Icons.accessibility_new;
      case 'Motion Resumed':
        return Icons.directions_walk;
      case 'Room Vacated':
        return Icons.logout;
      default:
        return Icons.sensors;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomColor = AppColors.roomColor(log.roomName);

    if (log.isAnomaly) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.report_problem,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${log.roomName} — ${log.eventType}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    _formatTime(log.timestamp),
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (log.anomalyNote != null) ...[
                const SizedBox(height: 6),
                Text(
                  log.anomalyNote!,
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: roomColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_eventIcon(), color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.roomName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    log.eventType,
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatTime(log.timestamp),
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
