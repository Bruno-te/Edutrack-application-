import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/attendance_model.dart';
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
        child: _MarkAttendanceSheet(teacher: teacher),
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
  final UserModel teacher;
  const _MarkAttendanceSheet({required this.teacher});

  @override
  State<_MarkAttendanceSheet> createState() =>
      _MarkAttendanceSheetState();
}

class _MarkAttendanceSheetState extends State<_MarkAttendanceSheet> {
  final _studentNameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _classIdCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  AttendanceStatus _status = AttendanceStatus.present;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _classIdCtrl.text = widget.teacher.classId?.trim() ?? '';
  }

  @override
  void dispose() {
    _studentNameCtrl.dispose();
    _studentIdCtrl.dispose();
    _subjectCtrl.dispose();
    _classIdCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_studentNameCtrl.text.isEmpty ||
        _subjectCtrl.text.isEmpty ||
        _classIdCtrl.text.trim().isEmpty) {
      return;
    }

    final studentId = _studentIdCtrl.text.trim();
    final classId = _classIdCtrl.text.trim();
    if (studentId.isEmpty || classId.isEmpty) return;

    // Ensure the entered student belongs to the teacher's course.
    final fs = context.read<FirestoreService>();
    final studentUser = await fs.getUser(studentId);
    if (studentUser == null || studentUser.classId != classId) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student is not assigned to your course ($classId).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final record = AttendanceModel(
      id: '',
      studentId: _studentIdCtrl.text.trim(),
      studentName: _studentNameCtrl.text.trim(),
      classId: classId,
      subject: _subjectCtrl.text.trim(),
      status: _status,
      teacherId: widget.teacher.id,
      remarks: _remarksCtrl.text.trim().isEmpty
          ? null
          : _remarksCtrl.text.trim(),
      date: _date,
    );
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
            const SizedBox(height: 16),
            SPMTextField(
              label: 'Student Name',
              hint: 'Full name',
              controller: _studentNameCtrl,
            ),
            const SizedBox(height: 12),
            SPMTextField(
              label: 'Student ID',
              hint: 'STU-001',
              controller: _studentIdCtrl,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SPMTextField(
                    label: 'Subject',
                    hint: 'Mathematics',
                    controller: _subjectCtrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SPMTextField(
                    label: 'Class ID',
                    hint: 'Class-10A',
                    controller: _classIdCtrl,
                    readOnly: true,
                  ),
                ),
              ],
            ),
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
