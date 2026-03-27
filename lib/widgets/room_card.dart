import 'package:flutter/material.dart';
import '../models/room.dart';
import '../theme/app_colors.dart';

class RoomCard extends StatelessWidget {
  final Room room;

  const RoomCard({super.key, required this.room});

  String _timeAgo() {
    final diff = DateTime.now().difference(room.lastMotion);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.roomColor(room.name);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last motion: ${_timeAgo()}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StateBadge(state: room.state),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.sensors,
                      color: Colors.white.withAlpha(120),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'mmWave',
                      style: TextStyle(
                        color: Colors.white.withAlpha(120),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              AppColors.roomIcon(room.icon),
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  final RoomState state;

  const _StateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    switch (state) {
      case RoomState.active:
        badgeColor = AppColors.activeGreen;
      case RoomState.still:
        badgeColor = AppColors.stillAmber;
      case RoomState.empty:
        badgeColor = AppColors.emptyGrey;
    }

    final label = switch (state) {
      RoomState.active => 'Active',
      RoomState.still => 'Still',
      RoomState.empty => 'Empty',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withAlpha(100), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
