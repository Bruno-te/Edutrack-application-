import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/course_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/attendance_bloc.dart';

class AttendanceScreen extends StatelessWidget {
  final String? studentId;
  final String? teacherId;

  const AttendanceScreen({super.key, this.studentId, this.teacherId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => AttendanceBloc(
        firestoreService: ctx.read<FirestoreService>(),
      )..add(AttendanceLoadRequested(
          studentId: studentId, teacherId: teacherId)),
      child: _AttendanceView(
          studentId: studentId, teacherId: teacherId),
    );
  }
}

class _AttendanceView extends StatelessWidget {
  final String? studentId;
  final String? teacherId;

  const _AttendanceView({this.studentId, this.teacherId});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user =
        authState is AuthAuthenticated ? authState.user : null;
    final canMark =
        user?.role == 'teacher' || user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          if (canMark)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Mark Attendance',
              onPressed: () => _showMarkSheet(context, user!),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Filter by Date',
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (ctx, state) {
          if (state is AttendanceOperationSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ));
            ctx.read<AttendanceBloc>().add(AttendanceLoadRequested(
                studentId: studentId, teacherId: teacherId));
          } else if (state is AttendanceError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (ctx, state) {
          if (state is AttendanceLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AttendanceLoaded) {
            return _AttendanceBody(
              state: state,
              canMark: canMark,
              onDelete: (id) => ctx
                  .read<AttendanceBloc>()
                  .add(AttendanceDeleteRequested(id)),
            );
          }
          if (state is AttendanceError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Error',
              subtitle: state.message,
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && context.mounted) {
      context
          .read<AttendanceBloc>()
          .add(AttendanceDateFilterChanged(picked));
    }
  }

  void _showMarkSheet(BuildContext context, UserModel teacher) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AttendanceBloc>(),
        child: _MarkAttendanceSheet(user: teacher),
      ),
    );
  }
}

class _AttendanceBody extends StatelessWidget {
  final AttendanceLoaded state;
  final bool canMark;
  final void Function(String) onDelete;

  const _AttendanceBody({
    required this.state,
    required this.canMark,
    required this.onDelete,
  });

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return AppColors.success;
      case AttendanceStatus.absent:  return AppColors.error;
      case AttendanceStatus.late:    return AppColors.warning;
      case AttendanceStatus.excused: return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Attendance Rate',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  if (state.selectedDate != null)
                    GestureDetector(
                      onTap: () => context
                          .read<AttendanceBloc>()
                          .add(const AttendanceDateFilterChanged(null)),
                      child: const Row(
                        children: [
                          Icon(Icons.close, color: Colors.white70, size: 14),
                          SizedBox(width: 4),
                          Text('Clear Filter',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${state.attendanceRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttStat(
                      label: 'Present',
                      count: state.presentCount,
                      color: AppColors.success),
                  _AttStat(
                      label: 'Absent',
                      count: state.absentCount,
                      color: AppColors.error),
                  _AttStat(
                      label: 'Late',
                      count: state.lateCount,
                      color: AppColors.warning),
                  _AttStat(
                      label: 'Excused',
                      count: state.excusedCount,
                      color: AppColors.info),
                ],
              ),
            ],
          ),
        ),

        // Date label
        if (state.selectedDate != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Showing: ${DateFormat('MMMM d, y').format(state.selectedDate!)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),

        // List
        Expanded(
          child: state.filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.how_to_reg_outlined,
                  title: 'No attendance records',
                  subtitle: 'Records will appear here once marked.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: state.filtered.length,
                  itemBuilder: (_, i) {
                    final record = state.filtered[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _statusColor(record.status)
                                .withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            record.status == AttendanceStatus.present
                                ? Icons.check_circle
                                : record.status == AttendanceStatus.absent
                                    ? Icons.cancel
                                    : record.status ==
                                            AttendanceStatus.late
                                        ? Icons.schedule
                                        : Icons.info_outline,
                            color: _statusColor(record.status),
                            size: 22,
                          ),
                        ),
                        title: Text(record.studentName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${record.subject} · ${DateFormat('MMM d, y').format(record.date)}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusChip(
                              label: record.status.label,
                              color: _statusColor(record.status),
                            ),
                            if (canMark) ...[
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () =>
                                    _confirmDelete(context, record.id),
                                child: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 16),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Record'),
        content:
            const Text('Remove this attendance record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () {
              onDelete(id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AttStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AttStat(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

// ── Mark Attendance Sheet ─────────────────────────────────────

class _MarkAttendanceSheet extends StatefulWidget {
  /// Teacher or admin — must match a course the student is enrolled in.
  final UserModel user;
  const _MarkAttendanceSheet({required this.user});

  @override
  State<_MarkAttendanceSheet> createState() =>
      _MarkAttendanceSheetState();
}

class _MarkAttendanceSheetState extends State<_MarkAttendanceSheet> {
  final _studentNameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _manualStudentIdCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  AttendanceStatus _status = AttendanceStatus.present;
  DateTime _date = DateTime.now();

  bool _loading = true;
  List<CourseModel> _courses = const [];
  List<UserModel> _allStudents = const [];
  String? _courseId;
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCoursesAndStudents());
  }

  List<CourseModel> _mergedCourses() {
    final out = List<CourseModel>.from(_courses);
    final tid = widget.user.classId?.trim();
    if (tid != null &&
        tid.isNotEmpty &&
        !out.any((c) => c.id == tid)) {
      out.insert(
        0,
        CourseModel(
          id: tid,
          name: 'My class ($tid)',
          createdAt: DateTime.now(),
        ),
      );
    }
    return out;
  }

  Future<void> _loadCoursesAndStudents() async {
    final fs = context.read<FirestoreService>();
    try {
      final courses = await fs.getCourses();
      final students = await fs.getUsersByRole('student');
      if (!mounted) return;

      final merged = List<CourseModel>.from(courses);
      final tid = widget.user.classId?.trim();
      if (tid != null &&
          tid.isNotEmpty &&
          !merged.any((c) => c.id == tid)) {
        merged.insert(
          0,
          CourseModel(
            id: tid,
            name: 'My class ($tid)',
            createdAt: DateTime.now(),
          ),
        );
      }

      String? initialCourse = tid;
      if (initialCourse == null || initialCourse.isEmpty) {
        initialCourse = merged.isNotEmpty ? merged.first.id : null;
      } else if (!merged.any((c) => c.id == initialCourse)) {
        initialCourse = merged.isNotEmpty ? merged.first.id : null;
      }

      setState(() {
        _courses = courses;
        _allStudents = students;
        _loading = false;
        _courseId = initialCourse;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CourseModel> get _courseDropdownItems => _mergedCourses();

  List<UserModel> _rosterForCourseId(String? courseId) {
    final cid = courseId?.trim();
    if (cid == null || cid.isEmpty) return [];
    final list =
        _allStudents.where((s) => s.isEnrolledInCourse(cid)).toList();
    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    return list;
  }

  void _applyStudent(UserModel s) {
    setState(() {
      _selectedStudentId = s.id;
      _studentIdCtrl.text = s.id;
      _studentNameCtrl.text = s.fullName;
      _manualStudentIdCtrl.clear();
    });
  }

  @override
  void dispose() {
    _studentNameCtrl.dispose();
    _studentIdCtrl.dispose();
    _subjectCtrl.dispose();
    _manualStudentIdCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty) return;

    final courseItems = _mergedCourses();
    if (courseItems.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No course available.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final classId = (_courseId != null &&
            courseItems.any((c) => c.id == _courseId))
        ? _courseId!.trim()
        : courseItems.first.id.trim();
    if (classId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a course.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    var studentId = _manualStudentIdCtrl.text.trim();
    if (studentId.isEmpty) {
      studentId = _studentIdCtrl.text.trim();
    }
    if (studentId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a student or paste their Account ID.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final fs = context.read<FirestoreService>();
    final studentUser = await fs.getUser(studentId);
    if (studentUser == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No user found for that Account ID. Copy it from the student\'s Profile.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!studentUser.isEnrolledInCourse(classId)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This student is not enrolled in course "$classId". '
            'In Admin → Courses, assign the student to this course.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final name = _studentNameCtrl.text.trim().isEmpty
        ? studentUser.fullName
        : _studentNameCtrl.text.trim();

    final record = AttendanceModel(
      id: '',
      studentId: studentId,
      studentName: name,
      classId: classId,
      subject: _subjectCtrl.text.trim(),
      status: _status,
      teacherId: widget.user.id,
      remarks: _remarksCtrl.text.trim().isEmpty
          ? null
          : _remarksCtrl.text.trim(),
      date: _date,
    );
    if (!context.mounted) return;
    context.read<AttendanceBloc>().add(AttendanceMarkRequested(record));
    Navigator.pop(context);
  }

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return AppColors.success;
      case AttendanceStatus.absent:  return AppColors.error;
      case AttendanceStatus.late:    return AppColors.warning;
      case AttendanceStatus.excused: return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseItems = _courseDropdownItems;
    final effectiveCourseId = courseItems.isEmpty
        ? null
        : (courseItems.any((c) => c.id == _courseId)
            ? _courseId
            : courseItems.first.id);
    final roster = _rosterForCourseId(effectiveCourseId);
    final studentDropdownValue =
        roster.any((s) => s.id == _selectedStudentId)
            ? _selectedStudentId
            : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mark Attendance',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pick the course and student. IDs must match Admin → Courses enrollments.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withOpacity(0.95),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (courseItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No courses found. Ask an admin to create a course and assign you and your students.',
                  style: TextStyle(
                    color: AppColors.warning.withOpacity(0.95),
                    fontSize: 13,
                  ),
                ),
              )
            else ...[
              DropdownButtonFormField<String>(
                value: effectiveCourseId,
                items: courseItems
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          c.name.isEmpty ? c.id : '${c.name} (${c.id})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _courseId = v;
                    _selectedStudentId = null;
                    _studentIdCtrl.clear();
                    _studentNameCtrl.clear();
                    _manualStudentIdCtrl.clear();
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (roster.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No students enrolled in this course yet. Use Admin → Courses to assign students.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.95),
                    ),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: studentDropdownValue,
                  hint: const Text('Select student'),
                  items: roster
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            s.fullName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    final s = _allStudents.firstWhere((x) => x.id == id);
                    _applyStudent(s);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Student',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 12),
              SPMTextField(
                label: 'Student name',
                hint: 'Filled when you pick a student',
                controller: _studentNameCtrl,
              ),
              const SizedBox(height: 12),
              SPMTextField(
                label: 'Account ID (optional)',
                hint: 'Paste only if the student is not in the list above',
                controller: _manualStudentIdCtrl,
              ),
              const SizedBox(height: 12),
              SPMTextField(
                label: 'Subject',
                hint: 'Mathematics',
                controller: _subjectCtrl,
              ),
            ],
            const SizedBox(height: 16),
            const Text('Status',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: AttendanceStatus.values.map((s) {
                final isSelected = _status == s;
                final color = _statusColor(s);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isSelected ? color : AppColors.border,
                            width: isSelected ? 2 : 1),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            s == AttendanceStatus.present
                                ? Icons.check_circle_outline
                                : s == AttendanceStatus.absent
                                    ? Icons.cancel_outlined
                                    : s == AttendanceStatus.late
                                        ? Icons.schedule_outlined
                                        : Icons.info_outline,
                            color: isSelected ? color : AppColors.textHint,
                            size: 18,
                          ),
                          const SizedBox(height: 2),
                          Text(s.label,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? color
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Date picker
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textHint),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM d, y').format(_date),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SPMTextField(
              label: 'Remarks (Optional)',
              hint: 'Any notes…',
              controller: _remarksCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Mark Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}
