import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/assignment_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/assignments_bloc.dart';

SubmissionModel? submissionForAssignment(
  List<SubmissionModel> submissions,
  String assignmentId,
  String? viewerStudentId,
) {
  final sid = viewerStudentId?.trim();
  if (sid == null || sid.isEmpty) return null;
  SubmissionModel? best;
  for (final s in submissions) {
    if (s.assignmentId != assignmentId || s.studentId != sid) continue;
    if (best == null || s.submittedAt.isAfter(best.submittedAt)) best = s;
  }
  return best;
}

/// Latest submission per student for an assignment (teacher/admin view).
List<SubmissionModel> latestSubmissionsForAssignment(
  List<SubmissionModel> submissions,
  String assignmentId,
) {
  final map = <String, SubmissionModel>{};
  for (final s in submissions.where((x) => x.assignmentId == assignmentId)) {
    final cur = map[s.studentId];
    if (cur == null || s.submittedAt.isAfter(cur.submittedAt)) {
      map[s.studentId] = s;
    }
  }
  return map.values.toList()
    ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
}

class AssignmentsScreen extends StatelessWidget {
  final String? teacherId;
  final String? studentId;

  const AssignmentsScreen({super.key, this.teacherId, this.studentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => AssignmentsBloc(
        firestoreService: ctx.read<FirestoreService>(),
      )..add(AssignmentsLoadRequested(
          teacherId: teacherId, studentId: studentId)),
      child: _AssignmentsView(
          teacherId: teacherId, studentId: studentId),
    );
  }
}

class _AssignmentsView extends StatefulWidget {
  final String? teacherId;
  final String? studentId;

  const _AssignmentsView({this.teacherId, this.studentId});

  @override
  State<_AssignmentsView> createState() => _AssignmentsViewState();
}

class _AssignmentsViewState extends State<_AssignmentsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  /// Keeps list visible when bloc emits [AssignmentOperationSuccess] between snapshots.
  AssignmentsLoaded? _lastAssignmentsLoaded;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user =
        authState is AuthAuthenticated ? authState.user : null;
    final canCreate =
        user?.role == 'teacher' || user?.role == 'admin';
    final showSubmissionUi = (user?.role == 'student' ||
            user?.role == 'parent') &&
        (widget.studentId != null &&
            widget.studentId!.trim().isNotEmpty);
    final canSubmitAsStudent = user?.role == 'student';
    final showTeacherGrading = canCreate && !showSubmissionUi;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assignments'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Overdue'),
          ],
        ),
        actions: [
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'New Assignment',
              onPressed: () => _showCreateSheet(context, user!),
            ),
        ],
      ),
      body: BlocConsumer<AssignmentsBloc, AssignmentsState>(
        listener: (ctx, state) {
          if (state is AssignmentsLoaded) {
            _lastAssignmentsLoaded = state;
          }
          if (state is AssignmentOperationSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ));
          } else if (state is AssignmentsError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (ctx, state) {
          if (state is AssignmentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final loaded = state is AssignmentsLoaded
              ? state
              : (state is AssignmentOperationSuccess
                  ? _lastAssignmentsLoaded
                  : null);
          if (loaded != null) {
            return TabBarView(
              controller: _tabCtrl,
              children: [
                _AssignmentList(
                  assignments: loaded.upcoming,
                  emptyTitle: 'No upcoming assignments',
                  emptySubtitle: 'All caught up!',
                  canCreate: canCreate,
                  submissions: loaded.submissions,
                  viewerStudentId: widget.studentId,
                  showSubmissionUi: showSubmissionUi,
                  showTeacherGrading: showTeacherGrading,
                  canSubmit: canSubmitAsStudent,
                  onDelete: (id) => ctx
                      .read<AssignmentsBloc>()
                      .add(AssignmentDeleteRequested(id)),
                  onSubmit: (sub) => ctx
                      .read<AssignmentsBloc>()
                      .add(AssignmentSubmitRequested(sub)),
                ),
                _AssignmentList(
                  assignments: loaded.overdue,
                  emptyTitle: 'No overdue assignments',
                  emptySubtitle: 'Great job keeping up!',
                  canCreate: canCreate,
                  submissions: loaded.submissions,
                  viewerStudentId: widget.studentId,
                  showSubmissionUi: showSubmissionUi,
                  showTeacherGrading: showTeacherGrading,
                  canSubmit: canSubmitAsStudent,
                  onDelete: (id) => ctx
                      .read<AssignmentsBloc>()
                      .add(AssignmentDeleteRequested(id)),
                  onSubmit: (sub) => ctx
                      .read<AssignmentsBloc>()
                      .add(AssignmentSubmitRequested(sub)),
                ),
              ],
            );
          }
          return const EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No assignments found',
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AssignmentsBloc>(),
        child: _CreateAssignmentSheet(teacher: user),
      ),
    );
  }
}

class _AssignmentList extends StatelessWidget {
  final List<AssignmentModel> assignments;
  final String emptyTitle;
  final String emptySubtitle;
  final bool canCreate;
  final List<SubmissionModel> submissions;
  final String? viewerStudentId;
  final bool showSubmissionUi;
  final bool showTeacherGrading;
  final bool canSubmit;
  final void Function(String) onDelete;
  final void Function(SubmissionModel) onSubmit;

  const _AssignmentList({
    required this.assignments,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.canCreate,
    required this.submissions,
    required this.viewerStudentId,
    required this.showSubmissionUi,
    required this.showTeacherGrading,
    required this.canSubmit,
    required this.onDelete,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_turned_in_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignments.length,
      itemBuilder: (_, i) => _AssignmentCard(
        assignment: assignments[i],
        canDelete: canCreate,
        submissions: submissions,
        viewerStudentId: viewerStudentId,
        showSubmissionUi: showSubmissionUi,
        showTeacherGrading: showTeacherGrading,
        canSubmit: canSubmit,
        onDelete: onDelete,
        onSubmit: onSubmit,
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final bool canDelete;
  final List<SubmissionModel> submissions;
  final String? viewerStudentId;
  final bool showSubmissionUi;
  final bool showTeacherGrading;
  final bool canSubmit;
  final void Function(String) onDelete;
  final void Function(SubmissionModel) onSubmit;

  const _AssignmentCard({
    required this.assignment,
    required this.canDelete,
    required this.submissions,
    required this.viewerStudentId,
    required this.showSubmissionUi,
    required this.showTeacherGrading,
    required this.canSubmit,
    required this.onDelete,
    required this.onSubmit,
  });

  int get _daysLeft {
    return assignment.dueDate.difference(DateTime.now()).inDays;
  }

  Color get _dueDateColor {
    if (assignment.isOverdue) return AppColors.error;
    if (_daysLeft <= 2) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final sub = showSubmissionUi
        ? submissionForAssignment(
            submissions, assignment.id, viewerStudentId)
        : null;
    final latestForTeacher = showTeacherGrading
        ? latestSubmissionsForAssignment(submissions, assignment.id)
        : const <SubmissionModel>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(assignment.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
                if (showSubmissionUi && sub != null)
                  StatusChip(
                    label: sub.status == AssignmentStatus.graded
                        ? 'Graded'
                        : 'Submitted',
                    color: sub.status == AssignmentStatus.graded
                        ? AppColors.success
                        : AppColors.info,
                  )
                else if (showTeacherGrading)
                  StatusChip(
                    label: latestForTeacher.isEmpty
                        ? 'No submissions'
                        : '${latestForTeacher.length} submitted',
                    color: latestForTeacher.isEmpty
                        ? AppColors.textHint
                        : AppColors.info,
                  )
                else if (assignment.isOverdue)
                  const StatusChip(
                      label: 'Overdue', color: AppColors.error)
                else
                  const StatusChip(
                      label: 'Active', color: AppColors.success),
              ],
            ),
            const SizedBox(height: 6),
            Text(assignment.description,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.book_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(assignment.subject,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(width: 16),
                const Icon(Icons.star_outline,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                    '${assignment.maxMarks.toStringAsFixed(0)} marks',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            if (showTeacherGrading) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final awaiting = latestForTeacher
                      .where((s) => s.status == AssignmentStatus.submitted)
                      .length;
                  final graded = latestForTeacher
                      .where((s) => s.status == AssignmentStatus.graded)
                      .length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestForTeacher.isEmpty
                            ? 'No students have submitted yet.'
                            : '$awaiting awaiting grade · $graded graded · ${latestForTeacher.length} student(s)',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () => _showTeacherSubmissionsSheet(
                            context, assignment, latestForTeacher),
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text('Review & grade'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: _dueDateColor),
                    const SizedBox(width: 4),
                    Text(
                      assignment.isOverdue
                          ? 'Due ${DateFormat('MMM d').format(assignment.dueDate)} (overdue)'
                          : 'Due ${DateFormat('MMM d, y').format(assignment.dueDate)}',
                      style: TextStyle(
                          color: _dueDateColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (showSubmissionUi) ...[
                      if (sub == null && canSubmit)
                        TextButton.icon(
                          onPressed: () => _submitDialog(context),
                          icon: const Icon(Icons.upload_outlined,
                              size: 16),
                          label: const Text('Submit',
                              style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4)),
                        )
                      else if (sub == null && !canSubmit)
                        Text(
                          'Not submitted yet',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withOpacity(0.95),
                          ),
                        )
                      else if (sub != null) ...[
                        if (sub.status == AssignmentStatus.submitted)
                          Text(
                            'Awaiting teacher grade',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.info.withOpacity(0.95),
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else if (sub.status == AssignmentStatus.graded)
                          Text(
                            '${sub.marksObtained != null ? sub.marksObtained!.toStringAsFixed(0) : '—'} / ${assignment.maxMarks.toStringAsFixed(0)} marks',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                      ],
                    ],
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 18),
                        onPressed: () =>
                            _confirmDelete(context),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTeacherSubmissionsSheet(
    BuildContext context,
    AssignmentModel assignment,
    List<SubmissionModel> latest,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: context.read<AssignmentsBloc>(),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: latest.isEmpty
                    ? const Center(child: Text('No submissions yet.'))
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: latest.length,
                        itemBuilder: (_, i) {
                          final s = latest[i];
                          final isGraded = s.status == AssignmentStatus.graded;
                          return ListTile(
                            title: Text(s.studentName),
                            subtitle: Text(
                              isGraded
                                  ? '${s.marksObtained?.toStringAsFixed(0) ?? '—'} / ${assignment.maxMarks.toStringAsFixed(0)} · ${DateFormat('MMM d, y').format(s.submittedAt)}'
                                  : 'Awaiting grade · ${DateFormat('MMM d, y').format(s.submittedAt)}',
                            ),
                            trailing: TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showGradeDialog(context, assignment, s);
                              },
                              child: Text(isGraded ? 'Edit' : 'Grade'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGradeDialog(
    BuildContext context,
    AssignmentModel assignment,
    SubmissionModel submission,
  ) {
    final bloc = context.read<AssignmentsBloc>();
    showDialog<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: _GradeSubmissionDialog(
          assignment: assignment,
          submission: submission,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text(
            'Delete "${assignment.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () {
              onDelete(assignment.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _submitDialog(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Assignment'),
        content: Text('Submit "${assignment.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final submission = SubmissionModel(
                id: '',
                assignmentId: assignment.id,
                studentId: user.id,
                studentName: user.fullName,
                status: AssignmentStatus.submitted,
                submittedAt: DateTime.now(),
              );
              onSubmit(submission);
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _GradeSubmissionDialog extends StatefulWidget {
  final AssignmentModel assignment;
  final SubmissionModel submission;

  const _GradeSubmissionDialog({
    required this.assignment,
    required this.submission,
  });

  @override
  State<_GradeSubmissionDialog> createState() =>
      _GradeSubmissionDialogState();
}

class _GradeSubmissionDialogState extends State<_GradeSubmissionDialog> {
  late final TextEditingController _marksCtrl;
  late final TextEditingController _remarksCtrl;

  @override
  void initState() {
    super.initState();
    final m = widget.submission.marksObtained;
    _marksCtrl = TextEditingController(text: m != null ? m.toString() : '');
    _remarksCtrl =
        TextEditingController(text: widget.submission.remarks ?? '');
  }

  @override
  void dispose() {
    _marksCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxM = widget.assignment.maxMarks;
    return AlertDialog(
      title: Text('Grade — ${widget.submission.studentName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SPMTextField(
            label: 'Marks (max ${maxM.toStringAsFixed(0)})',
            controller: _marksCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          SPMTextField(
            label: 'Remarks (optional)',
            controller: _remarksCtrl,
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final raw = _marksCtrl.text.trim();
            final m = double.tryParse(raw);
            if (m == null || m < 0 || m > maxM) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Enter marks between 0 and ${maxM.toStringAsFixed(0)}.',
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
            final data = <String, dynamic>{'marksObtained': m};
            final r = _remarksCtrl.text.trim();
            if (r.isNotEmpty) data['remarks'] = r;
            context.read<AssignmentsBloc>().add(
                  SubmissionGradeRequested(widget.submission.id, data),
                );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ── Create Assignment Sheet ───────────────────────────────────

class _CreateAssignmentSheet extends StatefulWidget {
  final UserModel teacher;
  const _CreateAssignmentSheet({required this.teacher});

  @override
  State<_CreateAssignmentSheet> createState() =>
      _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState
    extends State<_CreateAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _classIdCtrl = TextEditingController();
  final _maxMarksCtrl = TextEditingController(text: '100');
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _classIdCtrl.text = widget.teacher.classId?.trim() ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subjectCtrl.dispose();
    _classIdCtrl.dispose();
    _maxMarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _loading = true);

    final assignment = AssignmentModel(
      id: '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      classId: _classIdCtrl.text.trim(),
      teacherId: widget.teacher.id,
      maxMarks: double.tryParse(_maxMarksCtrl.text) ?? 100,
      dueDate: _dueDate,
      createdAt: DateTime.now(),
    );

    context
        .read<AssignmentsBloc>()
        .add(AssignmentAddRequested(assignment));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Assignment',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              SPMTextField(
                label: 'Title',
                hint: 'e.g. Chapter 5 Quiz',
                controller: _titleCtrl,
                validator: (v) => Validators.required(v, 'Title'),
              ),
              const SizedBox(height: 12),
              SPMTextField(
                label: 'Description',
                hint: 'Describe the assignment…',
                controller: _descCtrl,
                maxLines: 3,
                validator: (v) =>
                    Validators.required(v, 'Description'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SPMTextField(
                      label: 'Subject',
                      hint: 'Mathematics',
                      controller: _subjectCtrl,
                      validator: (v) =>
                          Validators.required(v, 'Subject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SPMTextField(
                      label: 'Class ID',
                      hint: 'Class-10A',
                      controller: _classIdCtrl,
                      readOnly: true,
                      validator: (v) =>
                          Validators.required(v, 'Class ID'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SPMTextField(
                label: 'Max Marks',
                hint: '100',
                controller: _maxMarksCtrl,
                keyboardType: TextInputType.number,
                validator: Validators.positiveNumber,
              ),
              const SizedBox(height: 12),
              const Text('Due Date',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _dueDate = d);
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
                        DateFormat('MMMM d, y').format(_dueDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                                Colors.white)))
                    : const Text('Create Assignment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
