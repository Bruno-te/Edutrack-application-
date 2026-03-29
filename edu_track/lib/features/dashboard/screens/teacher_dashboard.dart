import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../core/constants/app_colors.dart';
import '../../../core/models/assignment_model.dart';
import '../../../core/models/grade_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../assignments/screens/assignments_screen.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../grades/screens/grades_screen.dart';
import '../../performance/screens/performance_screen.dart';
import 'admin_dashboard.dart';
import '../../../app_router.dart';


class TeacherDashboard extends StatefulWidget {
 const TeacherDashboard({super.key});
 @override
 State<TeacherDashboard> createState() => _TeacherDashboardState();
}


class _TeacherDashboardState extends State<TeacherDashboard> {
 int _currentIndex = 0;


 @override
 Widget build(BuildContext context) {
   final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;


   final pages = [
     _TeacherHome(user: user),
     GradesScreen(teacherId: user.id),
     AttendanceScreen(teacherId: user.id),
     const PerformanceScreen(loadGlobalAnalytics: true),
     AssignmentsScreen(teacherId: user.id),
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
             icon: Icon(Icons.dashboard_outlined),
             selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
             label: 'Home'),
         NavigationDestination(
             icon: Icon(Icons.grade_outlined),
             selectedIcon: Icon(Icons.grade, color: AppColors.primary),
             label: 'Grades'),
         NavigationDestination(
             icon: Icon(Icons.how_to_reg_outlined),
             selectedIcon: Icon(Icons.how_to_reg, color: AppColors.primary),
             label: 'Attendance'),
         NavigationDestination(
             icon: Icon(Icons.bar_chart_outlined),
             selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
             label: 'Reports'),
         NavigationDestination(
             icon: Icon(Icons.assignment_outlined),
             selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
             label: 'Assignments'),
       ],
     ),
   );
 }
}


class _TeacherHome extends StatefulWidget {
 final UserModel user;
 const _TeacherHome({required this.user});
 @override
 State<_TeacherHome> createState() => _TeacherHomeState();
}


class _TeacherHomeState extends State<_TeacherHome> {
 int _studentCount = 0;
 int _subjectsCount = 0;
 int _assignmentsCount = 0;
 double _avgScore = 0;
 bool _hasGrades = false;


 @override
 void initState() {
   super.initState();
   _load();
 }


 Future<void> _load() async {
   final fs = context.read<FirestoreService>();
   final teacherId = widget.user.id;
   final classId = widget.user.classId;


   List<AssignmentModel> assignments = const [];
   List<GradeModel> grades = const [];
   int studentCount = 0;


   if (classId != null && classId.isNotEmpty) {
     final students = await fs.getUsersByRole('student');
     studentCount =
         students.where((s) => s.isEnrolledInCourse(classId)).length;


     assignments = await fs.getAssignmentsForClass(classId);
     grades = await fs.getGradesForClass(classId);


     // Fallback for legacy data where `classId` might not be stored.
     if (assignments.isEmpty) {
       assignments = await fs.getAssignmentsForTeacherData(teacherId);
     }
     if (grades.isEmpty) {
       grades = await fs.getGradesForTeacherData(teacherId);
     }
   } else {
     // If teacher isn't assigned to a class yet, still show their data.
     assignments = await fs.getAssignmentsForTeacherData(teacherId);
     grades = await fs.getGradesForTeacherData(teacherId);
     studentCount = grades.map((g) => g.studentId).toSet().length;
   }


   final subjects = <String>{};
   subjects.addAll(assignments.map((a) => a.subject).where((s) => s.isNotEmpty));
   subjects.addAll(grades.map((g) => g.subject).where((s) => s.isNotEmpty));


   final avgScore = grades.isEmpty
       ? 0.0
       : grades.fold<double>(0, (p, g) => p + g.percentage) /
           grades.length.toDouble();


   if (!mounted) return;
   setState(() {
     _studentCount = studentCount;
     _assignmentsCount = assignments.length;
     _subjectsCount = subjects.length;
     _avgScore = avgScore;
     _hasGrades = grades.isNotEmpty;
   });
 }


 @override
 Widget build(BuildContext context) {
   return Scaffold(
     backgroundColor: AppColors.background,
     appBar: AppBar(
       title: const Text('Teacher Dashboard'),
       actions: [ProfileButton(user: widget.user)],
     ),
     body: SingleChildScrollView(
       padding: const EdgeInsets.all(16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           GreetingBanner(user: widget.user),
           const SizedBox(height: 20),
           const SectionHeader(title: 'Quick Stats'),
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
                 label: 'My Students',
                 value: '$_studentCount',
                 icon: Icons.people_outline,
                 color: AppColors.primary,
               ),
               StatCard(
                 label: 'Subjects',
                 value: '$_subjectsCount',
                 icon: Icons.book_outlined,
                 color: AppColors.success,
               ),
               StatCard(
                 label: 'Assignments',
                 value: '$_assignmentsCount',
                 icon: Icons.assignment_outlined,
                 color: AppColors.warning,
               ),
               StatCard(
                 label: 'Avg. Score',
                 value: _hasGrades ? '${_avgScore.toStringAsFixed(1)}%' : '—',
                 icon: Icons.star_outline,
                 color: AppColors.secondary,
               ),
             ],
           ),
           const SizedBox(height: 24),
           const SectionHeader(title: 'Quick Actions'),
           const SizedBox(height: 12),
           _QuickActionGrid(user: widget.user),
         ],
       ),
     ),
   );
 }
}


class _QuickActionGrid extends StatelessWidget {
 final UserModel user;


 const _QuickActionGrid({required this.user});


 @override
 Widget build(BuildContext context) {
   final actions = [
     _QuickAction(
       label: 'Enter Grades',
       icon: Icons.grade,
       color: AppColors.primary,
       onTap: () => Navigator.pushNamed(
         context,
         AppRouter.grades,
         arguments: {'teacherId': user.id},
       ),
     ),
     _QuickAction(
       label: 'Mark Attendance',
       icon: Icons.how_to_reg,
       color: AppColors.success,
       onTap: () => Navigator.pushNamed(
         context,
         AppRouter.attendance,
         arguments: {'teacherId': user.id},
       ),
     ),
     _QuickAction(
       label: 'New Assignment',
       icon: Icons.add_task,
       color: AppColors.warning,
       onTap: () => Navigator.pushNamed(
         context,
         AppRouter.assignments,
         arguments: {'teacherId': user.id},
       ),
     ),
     _QuickAction(
       label: 'View Reports',
       icon: Icons.bar_chart,
       color: AppColors.secondary,
       onTap: () => Navigator.pushNamed(context, AppRouter.performance),
     ),
   ];
   return GridView.count(
     crossAxisCount: 2,
     shrinkWrap: true,
     physics: const NeverScrollableScrollPhysics(),
     crossAxisSpacing: 12,
     mainAxisSpacing: 12,
     childAspectRatio: 2.2,
     children: actions.map((a) {
       final color = a.color;
       return GestureDetector(
         onTap: a.onTap,
         child: Container(
           decoration: BoxDecoration(
             color: color.withOpacity(0.1),
             borderRadius: BorderRadius.circular(14),
             border: Border.all(color: color.withOpacity(0.3)),
           ),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(a.icon, color: color, size: 22),
               const SizedBox(width: 8),
               Text(a.label,
                   style: TextStyle(
                       color: color,
                       fontWeight: FontWeight.w600,
                       fontSize: 12)),
             ],
           ),
         ),
       );
     }).toList(),
   );
 }
}


class _QuickAction {
 final String label;
 final IconData icon;
 final Color color;
 final VoidCallback onTap;


 const _QuickAction({
   required this.label,
   required this.icon,
   required this.color,
   required this.onTap,
 });
}