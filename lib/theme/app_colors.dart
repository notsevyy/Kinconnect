import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFFF5F4F0);
  static const Color cardWhite = Color(0xFFFFFFFF);

  // Text
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF6B6B6B);
  static const Color textLight = Color(0xFFFFFFFF);

  // Room colors
  static const Color livingRoom = Color(0xFFC05A3B);
  static const Color bedroom = Color(0xFF6B4C8A);
  static const Color bathroom = Color(0xFF5A7A8A);
  static const Color kitchen = Color(0xFF6B7B3A);

  // Status colors
  static const Color critical = Color(0xFFB22222);
  static const Color warning = Color(0xFFD4920A);
  static const Color allClear = Color(0xFF2A2A2A);

  // System
  static const Color hubNavy = Color(0xFF1A2744);
  static const Color primary = Color(0xFF3A7BD5);
  static const Color charcoal = Color(0xFF2A2A2A);

  // State badge backgrounds (lighter tints for badges on colored cards)
  static const Color activeGreen = Color(0xFF4CAF50);
  static const Color stillAmber = Color(0xFFE6A817);
  static const Color emptyGrey = Color(0xFF9E9E9E);

  static Color roomColor(String roomName) {
    switch (roomName) {
      case 'Living Room':
        return livingRoom;
      case 'Bedroom':
        return bedroom;
      case 'Bathroom':
        return bathroom;
      case 'Kitchen':
        return kitchen;
      default:
        return charcoal;
    }
  }

  static IconData roomIcon(String iconKey) {
    switch (iconKey) {
      case 'weekend':
        return Icons.weekend;
      case 'bed':
        return Icons.bed;
      case 'bathtub':
        return Icons.bathtub;
      case 'kitchen':
        return Icons.kitchen;
      default:
        return Icons.room;
    }
  }
}
