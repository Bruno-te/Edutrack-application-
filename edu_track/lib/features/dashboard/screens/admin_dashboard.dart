import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../assignments/screens/assignments_screen.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../grades/screens/grades_screen.dart';
import '../../performance/screens/performance_screen.dart';
import '../../courses/screens/courses_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  Map<String, int> _counts = {};
  bool _loading = true;
  List<UserModel> _recentUsers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final fs = context.read<FirestoreService>();
    final counts = await fs.getDashboardCounts();
    final students = await fs.getUsersByRole('student');
    if (mounted) {
      setState(() {
        _counts = counts;
        _recentUsers = students.take(5).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user =
        (context.read<AuthBloc>().state as AuthAuthenticated).user;

    final pages = [
      _AdminHome(
        user: user,
        counts: _counts,
        loading: _loading,
        recentUsers: _recentUsers,
        onRefresh: _loadData,
      ),
      const GradesScreen(),
      const AttendanceScreen(),
      const PerformanceScreen(),
      const AssignmentsScreen(),
      const CoursesScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withOpacity(0.12),
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard'),
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
            label: 'Performance'),
        NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
            label: 'Assignments'),
        NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school, color: AppColors.primary),
            label: 'Courses'),
      ],
    );
  }
}

class _AdminHome extends StatelessWidget {
  final UserModel user;
  final Map<String, int> counts;
  final bool loading;
  final List<UserModel> recentUsers;
  final VoidCallback onRefresh;

  const _AdminHome({
    required this.user,
    required this.counts,
    required this.loading,
    required this.recentUsers,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
          ProfileButton(user: user),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              GreetingBanner(user: user),
              const SizedBox(height: 20),

              // Stats grid
              const SectionHeader(title: 'Overview'),
              const SizedBox(height: 12),
              loading
                  ? const _StatsShimmer()
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        StatCard(
                          label: 'Total Students',
                          value: '${counts['students'] ?? 0}',
                          icon: Icons.people_outline,
                          color: AppColors.primary,
                        ),
                        StatCard(
                          label: 'Total Teachers',
                          value: '${counts['teachers'] ?? 0}',
                          icon: Icons.school_outlined,
                          color: AppColors.success,
                        ),
                        StatCard(
                          label: 'Assignments',
                          value: '${counts['assignments'] ?? 0}',
                          icon: Icons.assignment_outlined,
                          color: AppColors.warning,
                        ),
                        StatCard(
                          label: 'Grade Records',
                          value: '${counts['grades'] ?? 0}',
                          icon: Icons.grade_outlined,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
              const SizedBox(height: 24),

              // Recent Students
              SectionHeader(
                title: 'Recent Students',
                actionLabel: 'View All',
                onAction: () {},
              ),
              const SizedBox(height: 12),
              if (recentUsers.isEmpty && !loading)
                const EmptyState(
                  icon: Icons.people_outline,
                  title: 'No students yet',
                )
              else
                ...recentUsers.map((u) => _UserTile(user: u)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared across all dashboards ──────────────────────────────

class GreetingBanner extends StatelessWidget {
  final UserModel user;
  const GreetingBanner({required this.user});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          UserAvatar(initials: user.initials, radius: 28, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_greeting,',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                Text(user.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                RoleBadge(role: user.role),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Colors.white70, size: 14),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM d, y').format(DateTime.now()),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: UserAvatar(
          initials: user.initials,
          color: AppColors.roleColor(user.role),
        ),
        title: Text(user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(user.email,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        trailing: RoleBadge(role: user.role),
      ),
    );
  }
}

class ProfileButton extends StatelessWidget {
  final UserModel user;
  const ProfileButton({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProfileSheet(context, user),
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: UserAvatar(
            initials: user.initials, radius: 18, color: Colors.white),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(initials: user.initials, radius: 36),
            const SizedBox(height: 12),
            Text(user.fullName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(user.email,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            RoleBadge(role: user.role),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
