import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/assignment_model.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../assignments/screens/assignments_screen.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../grades/screens/grades_screen.dart';
import '../../performance/screens/performance_screen.dart';
import 'admin_dashboard.dart';

// ═══════════════════════════════════════════════════════════════
// STUDENT DASHBOARD
// ═══════════════════════════════════════════════════════════════

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user =
        (context.read<AuthBloc>().state as AuthAuthenticated).user;

    final pages = [
      _StudentHome(user: user),
      GradesScreen(studentId: user.id),
      AttendanceScreen(studentId: user.id),
      PerformanceScreen(studentId: user.id),
      AssignmentsScreen(studentId: user.id),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.grade_outlined),
              selectedIcon: Icon(Icons.grade, color: AppColors.primary),
              label: 'Grades'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon:
                  Icon(Icons.calendar_month, color: AppColors.primary),
              label: 'Attendance'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
              label: 'Progress'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
              label: 'Assignments'),
        ],
      ),
    );
  }
}

class _StudentHome extends StatefulWidget {
  final UserModel user;
  const _StudentHome({required this.user});

  @override
  State<_StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<_StudentHome> {
  bool _loading = true;
  double _avgGrade = 0.0;
  double _attendanceRate = 0.0;
  int _pendingCount = 0;
  int _submittedCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fs = context.read<FirestoreService>();

    final grades = await fs.getGradesForStudent(widget.user.id);
    final attendance = await fs.getAttendanceForStudent(widget.user.id);
    final submissions =
        await fs.getSubmissionsForStudentData(widget.user.id);

    final double avgGrade = grades.isEmpty
        ? 0.0
        : grades.fold<double>(0, (p, g) => p + g.percentage) /
            grades.length.toDouble();

    final attendanceRecords = attendance.length;
    final attendanceGood = attendance
        .where((a) =>
            a.status == AttendanceStatus.present || a.status == AttendanceStatus.late)
        .length;
    final double attendanceRate = attendanceRecords == 0
        ? 0.0
        : (attendanceGood / attendanceRecords.toDouble()) * 100;

    // Interpret:
    // - Pending = student submitted but not graded yet
    // - Submitted = graded
    final pendingCount =
        submissions.where((s) => s.status == AssignmentStatus.submitted).length;
    final submittedCount =
        submissions.where((s) => s.status == AssignmentStatus.graded).length;

    if (!mounted) return;
    setState(() {
      _loading = false;
      _avgGrade = avgGrade;
      _attendanceRate = attendanceRate;
      _pendingCount = pendingCount;
      _submittedCount = submittedCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [ProfileButton(user: widget.user)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GreetingBanner(user: widget.user),
            const SizedBox(height: 20),
            const SectionHeader(title: 'My Overview'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  label: 'Avg. Grade',
                  value: _loading ? '—' : '${_avgGrade.toStringAsFixed(1)}%',
                  icon: Icons.star_outline,
                  color: AppColors.primary,
                ),
                StatCard(
                  label: 'Attendance',
                  value: _loading ? '—' : '${_attendanceRate.toStringAsFixed(1)}%',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                StatCard(
                  label: 'Pending',
                  value: _loading ? '—' : '$_pendingCount',
                  icon: Icons.assignment_late_outlined,
                  color: AppColors.warning,
                ),
                StatCard(
                  label: 'Submitted',
                  value: _loading ? '—' : '$_submittedCount',
                  icon: Icons.assignment_turned_in_outlined,
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Upcoming Deadlines'),
            const SizedBox(height: 12),
            const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No upcoming deadlines',
              subtitle: 'All caught up! Check the Assignments tab.',
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PARENT DASHBOARD
// ═══════════════════════════════════════════════════════════════

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});
  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user =
        (context.read<AuthBloc>().state as AuthAuthenticated).user;
    final linkedId = user.studentId;

    final pages = [
      _ParentHome(user: user),
      GradesScreen(studentId: linkedId),
      AttendanceScreen(studentId: linkedId),
      PerformanceScreen(studentId: linkedId),
      AssignmentsScreen(studentId: linkedId),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.grade_outlined),
              selectedIcon: Icon(Icons.grade, color: AppColors.primary),
              label: 'Grades'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon:
                  Icon(Icons.calendar_month, color: AppColors.primary),
              label: 'Attendance'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
              label: 'Progress'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
              label: 'Assignments'),
        ],
      ),
    );
  }
}

class _ParentHome extends StatefulWidget {
  final UserModel user;
  const _ParentHome({required this.user});

  @override
  State<_ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<_ParentHome> {
  bool _loading = true;
  int _totalGrades = 0;
  double _avgGrade = 0;
  int _attendanceRecords = 0;
  double _attendanceRate = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final childId = widget.user.studentId;
    if (childId == null || childId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final fs = context.read<FirestoreService>();
    final grades = await fs.getGradesForStudent(childId);
    final attendance = await fs.getAttendanceForStudent(childId);

    final totalGrades = grades.length;
    final double avgGrade = grades.isEmpty
        ? 0.0
        : grades.fold<double>(0, (p, g) => p + g.percentage) /
            grades.length.toDouble();

    final attendanceRecords = attendance.length;
    final attendanceGood = attendance
        .where((a) =>
            a.status == AttendanceStatus.present || a.status == AttendanceStatus.late)
        .length;
    final double attendanceRate = attendanceRecords == 0
        ? 0.0
        : (attendanceGood / attendanceRecords.toDouble()) * 100;

    if (!mounted) return;
    setState(() {
      _loading = false;
      _totalGrades = totalGrades;
      _avgGrade = avgGrade;
      _attendanceRecords = attendanceRecords;
      _attendanceRate = attendanceRate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Child's Progress"),
        actions: [ProfileButton(user: widget.user)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GreetingBanner(user: widget.user),
            const SizedBox(height: 20),
            if (widget.user.studentId == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: AppColors.warning),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No student linked yet. Contact your admin to link your child\'s account.',
                        style:
                            TextStyle(color: AppColors.warning, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              const SectionHeader(title: "Child's Overview"),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    StatCard(
                      label: 'Avg. Grade',
                      value: '${_avgGrade.toStringAsFixed(1)}%',
                      icon: Icons.star_outline,
                      color: AppColors.primary,
                    ),
                    StatCard(
                      label: 'Attendance',
                      value: '${_attendanceRate.toStringAsFixed(1)}%',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                    ),
                    StatCard(
                      label: 'Total Grades',
                      value: '$_totalGrades',
                      icon: Icons.grade_outlined,
                      color: AppColors.warning,
                    ),
                    StatCard(
                      label: 'Attendance Records',
                      value: '$_attendanceRecords',
                      icon: Icons.how_to_reg_outlined,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
