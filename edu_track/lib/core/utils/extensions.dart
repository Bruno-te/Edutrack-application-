import 'package:flutter/material.dart';

extension ContextExt on BuildContext {
  // Screen dimensions
  double get screenWidth  => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Responsive helpers
  bool get isMobile  => screenWidth < 600;
  bool get isTablet  => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  // Grid column count
  int get gridColumns {
    if (isDesktop) return 4;
    if (isTablet)  return 3;
    return 2;
  }

  // Padding
  EdgeInsets get screenPadding => EdgeInsets.all(isMobile ? 16 : 24);

  // Navigation
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  Future<T?> push<T>(Widget page) =>
      Navigator.of(this).push(MaterialPageRoute(builder: (_) => page));
  Future<T?> pushNamed<T>(String route, {Object? arguments}) =>
      Navigator.of(this).pushNamed(route, arguments: arguments);

  // Snackbars
  void showSuccessSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }

  void showErrorSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFC62828),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }
}

extension StringExt on String {
  String get capitalize =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);

  String get initials {
    final parts = trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return isNotEmpty ? this[0].toUpperCase() : '?';
  }
}

extension DoubleExt on double {
  String get gradeLabel {
    if (this >= 90) return 'A+';
    if (this >= 80) return 'A';
    if (this >= 70) return 'B';
    if (this >= 60) return 'C';
    if (this >= 50) return 'D';
    return 'F';
  }
}
