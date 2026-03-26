import 'package:flutter/material.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/dashboard/screens/admin_dashboard.dart';
import 'features/dashboard/screens/student_dashboard.dart';
import 'features/dashboard/screens/teacher_dashboard.dart';
import 'features/grades/screens/grades_screen.dart';
import 'features/attendance/screens/attendance_screen.dart';
import 'features/performance/screens/performance_screen.dart';
import 'features/assignments/screens/assignments_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';

class AppRouter {
  static const String login        = '/login';
  static const String register     = '/register';
  static const String adminHome    = '/admin';
  static const String teacherHome  = '/teacher';
  static const String studentHome  = '/student';
  static const String parentHome   = '/parent';
  static const String grades       = '/grades';
  static const String attendance   = '/attendance';
  static const String performance  = '/performance';
  static const String assignments  = '/assignments';
  static const String profile      = '/profile';
  static const String notifications = '/notifications';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _build(const LoginScreen());
      case register:
        return _build(const RegisterScreen());
      case adminHome:
        return _build(const AdminDashboard());
      case teacherHome:
        return _build(const TeacherDashboard());
      case studentHome:
      case parentHome:
        return _build(const StudentDashboard());
      case grades:
        final args = settings.arguments as Map<String, String?>?;
        return _build(GradesScreen(
          studentId: args?['studentId'],
          teacherId: args?['teacherId'],
        ));
      case attendance:
        final args = settings.arguments as Map<String, String?>?;
        return _build(AttendanceScreen(
          studentId: args?['studentId'],
          teacherId: args?['teacherId'],
        ));
      case performance:
        final args = settings.arguments as Map<String, String?>?;
        return _build(PerformanceScreen(
          studentId: args?['studentId'],
        ));
      case assignments:
        final args = settings.arguments as Map<String, String?>?;
        return _build(AssignmentsScreen(
          teacherId: args?['teacherId'],
          studentId: args?['studentId'],
        ));
      case profile:
        return _build(const ProfileScreen());
      case notifications:
        return _build(const NotificationsScreen());
      default:
        return _build(const LoginScreen());
    }
  }

  static MaterialPageRoute _build(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}
