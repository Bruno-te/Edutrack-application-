import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1565C0);      // Deep Blue
  static const Color primaryLight = Color(0xFF1976D2); // Medium Blue
  static const Color primaryDark = Color(0xFF0D47A1);  // Dark Blue
  static const Color accent = Color(0xFF42A5F5);        // Light Blue
  static const Color secondary = Color(0xFF26C6DA);     // Cyan

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57F17);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF0277BD);

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFF0F4F8);
  static const Color cardBg = Colors.white;

  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);

  // Chart colors
  static const Color chartBlue = Color(0xFF1565C0);
  static const Color chartGreen = Color(0xFF2E7D32);
  static const Color chartOrange = Color(0xFFF57F17);
  static const Color chartRed = Color(0xFFC62828);
  static const Color chartPurple = Color(0xFF6A1B9A);

  // Role badge colors
  static const Color adminBadge = Color(0xFF7B1FA2);
  static const Color teacherBadge = Color(0xFF0277BD);
  static const Color studentBadge = Color(0xFF2E7D32);
  static const Color parentBadge = Color(0xFFF57F17);

  static Color roleColor(String role) {
    switch (role) {
      case 'admin':   return adminBadge;
      case 'teacher': return teacherBadge;
      case 'parent':  return parentBadge;
      case 'student':
      default:        return studentBadge;
    }
  }
}
