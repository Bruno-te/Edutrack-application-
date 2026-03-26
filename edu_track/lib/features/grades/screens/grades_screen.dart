import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/grade_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/grades_bloc.dart';

class GradesScreen extends StatelessWidget {
  final String? studentId;
  final String? teacherId;

  const GradesScreen({super.key, this.studentId, this.teacherId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => GradesBloc(
        firestoreService: ctx.read<FirestoreService>(),
      )..add(GradesLoadRequested(
          studentId: studentId, teacherId: teacherId)),
      child: _GradesView(
          studentId: studentId, teacherId: teacherId),
    );
  }
}

class _GradesView extends StatelessWidget {
  final String? studentId;
  final String? teacherId;

  const _GradesView({this.studentId, this.teacherId});

  bool get _canEdit => teacherId != null || studentId == null;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final canEdit =
        user?.role == 'teacher' || user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Grades'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add Grade',
              onPressed: () => _showAddGradeDialog(context, user!),
            ),
        ],
      ),
      body: BlocConsumer<GradesBloc, GradesState>(
        listener: (ctx, state) {
          if (state is GradeOperationSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ));
            ctx.read<GradesBloc>().add(GradesLoadRequested(
                studentId: studentId, teacherId: teacherId));
          } else if (state is GradesError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (ctx, state) {
          if (state is GradesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GradesError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load grades',
              subtitle: state.message,
              actionLabel: 'Retry',
              onAction: () => ctx
                  .read<GradesBloc>()
                  .add(GradesLoadRequested(
                      studentId: studentId, teacherId: teacherId)),
            );
          }
          if (state is GradesLoaded) {
            return _GradesList(
              state: state,
              canEdit: canEdit,
              onDelete: (id) =>
                  ctx.read<GradesBloc>().add(GradeDeleteRequested(id)),
              onFilter: (sub, term, type) => ctx
                  .read<GradesBloc>()
                  .add(GradesFiltered(
                      subject: sub, term: term, gradeType: type)),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _showAddGradeDialog(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<GradesBloc>(),
        child: _AddGradeSheet(teacher: user),
      ),
    );
  }
}

class _GradesList extends StatelessWidget {
  final GradesLoaded state;
  final bool canEdit;
  final void Function(String) onDelete;
  final void Function(String?, String?, String?) onFilter;

  const _GradesList({
    required this.state,
    required this.canEdit,
    required this.onDelete,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary bar
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Total Records',
                  value: '${state.filtered.length}',
                  icon: Icons.list_alt,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              Expanded(
                child: _SummaryItem(
                  label: 'Average Score',
                  value:
                      '${state.average.toStringAsFixed(1)}%',
                  icon: Icons.percent,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              Expanded(
                child: _SummaryItem(
                  label: 'Grade',
                  value: _avgLetter(state.average),
                  icon: Icons.star,
                ),
              ),
            ],
          ),
        ),

        // Filters
        _FilterBar(
          grades: state.grades,
          activeSubject: state.activeSubject,
          activeTerm: state.activeTerm,
          activeType: state.activeType,
          onFilter: onFilter,
        ),

        // List
        Expanded(
          child: state.filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.grade_outlined,
                  title: 'No grades found',
                  subtitle: 'Try adjusting your filters',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: state.filtered.length,
                  itemBuilder: (_, i) => _GradeCard(
                    grade: state.filtered[i],
                    canEdit: canEdit,
                    onDelete: onDelete,
                  ),
                ),
        ),
      ],
    );
  }

  String _avgLetter(double avg) {
    if (avg >= 90) return 'A+';
    if (avg >= 80) return 'A';
    if (avg >= 70) return 'B';
    if (avg >= 60) return 'C';
    if (avg >= 50) return 'D';
    return 'F';
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final List<GradeModel> grades;
  final String? activeSubject;
  final String? activeTerm;
  final String? activeType;
  final void Function(String?, String?, String?) onFilter;

  const _FilterBar({
    required this.grades,
    required this.activeSubject,
    required this.activeTerm,
    required this.activeType,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final subjects = grades.map((g) => g.subject).toSet().toList();
    final terms = grades.map((g) => g.term).toSet().toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _FilterChip(
            label: activeSubject ?? 'All Subjects',
            isActive: activeSubject != null,
            onTap: () => _showPicker(
              context,
              'Filter by Subject',
              ['', ...subjects],
              (v) => onFilter(v.isEmpty ? null : v, activeTerm, activeType),
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: activeTerm ?? 'All Terms',
            isActive: activeTerm != null,
            onTap: () => _showPicker(
              context,
              'Filter by Term',
              ['', 'Term 1', 'Term 2', 'Term 3'],
              (v) =>
                  onFilter(activeSubject, v.isEmpty ? null : v, activeType),
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: activeType ?? 'All Types',
            isActive: activeType != null,
            onTap: () => _showPicker(
              context,
              'Filter by Type',
              ['', 'Quiz', 'Exam', 'Assignment', 'Project'],
              (v) => onFilter(
                  activeSubject, activeTerm, v.isEmpty ? null : v),
            ),
          ),
          if (activeSubject != null ||
              activeTerm != null ||
              activeType != null) ...[
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.clear, size: 16),
              label: const Text('Clear'),
              onPressed: () => onFilter(null, null, null),
            ),
          ]
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, String title, List<String> options,
      void Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...options.map((o) => ListTile(
                title: Text(o.isEmpty ? 'All' : o),
                onTap: () {
                  onSelect(o);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                size: 16,
                color:
                    isActive ? Colors.white : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final GradeModel grade;
  final bool canEdit;
  final void Function(String) onDelete;

  const _GradeCard(
      {required this.grade,
      required this.canEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GradeChip(grade: grade.letterGrade),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(grade.subject,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                      '${grade.gradeType} · ${grade.term}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(grade.studentName,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    '${grade.score.toStringAsFixed(0)}/${grade.maxScore.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
                Text(
                    '${grade.percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text(DateFormat('MMM d').format(grade.date),
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 11)),
              ],
            ),
            if (canEdit) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Grade'),
        content: const Text('Are you sure you want to delete this grade record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () {
              onDelete(grade.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Add Grade Sheet ──────────────────────────────────────────

class _AddGradeSheet extends StatefulWidget {
  final UserModel teacher;
  const _AddGradeSheet({required this.teacher});

  @override
  State<_AddGradeSheet> createState() => _AddGradeSheetState();
}

class _AddGradeSheetState extends State<_AddGradeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();
  final _maxScoreCtrl = TextEditingController(text: '100');
  final _remarksCtrl = TextEditingController();

  String _gradeType = 'Exam';
  String _term = 'Term 1';
  bool _loading = false;

  final List<String> _gradeTypes = [
    'Exam', 'Quiz', 'Assignment', 'Project'
  ];
  final List<String> _terms = ['Term 1', 'Term 2', 'Term 3'];

  @override
  void dispose() {
    _studentNameCtrl.dispose();
    _studentIdCtrl.dispose();
    _subjectCtrl.dispose();
    _scoreCtrl.dispose();
    _maxScoreCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _loading = true);

    final maxScore = double.tryParse(_maxScoreCtrl.text) ?? 100;
    final grade = GradeModel(
      id: '',
      studentId: _studentIdCtrl.text.trim(),
      studentName: _studentNameCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      score: double.parse(_scoreCtrl.text),
      maxScore: maxScore,
      gradeType: _gradeType,
      term: _term,
      teacherId: widget.teacher.id,
      classId: widget.teacher.classId,
      remarks: _remarksCtrl.text.trim().isEmpty
          ? null
          : _remarksCtrl.text.trim(),
      date: DateTime.now(),
    );

    context.read<GradesBloc>().add(GradeAddRequested(grade));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Grade',
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
              validator: (v) => Validators.required(v, 'Student name'),
            ),
            const SizedBox(height: 12),
            SPMTextField(
              label: 'Student ID',
              hint: 'STU-001',
              controller: _studentIdCtrl,
              validator: (v) => Validators.required(v, 'Student ID'),
            ),
            const SizedBox(height: 12),
            SPMTextField(
              label: 'Subject',
              hint: 'e.g. Mathematics',
              controller: _subjectCtrl,
              validator: (v) => Validators.required(v, 'Subject'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Grade Type',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _gradeType,
                        decoration: const InputDecoration(),
                        items: _gradeTypes
                            .map((t) => DropdownMenuItem(
                                value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _gradeType = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Term',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _term,
                        decoration: const InputDecoration(),
                        items: _terms
                            .map((t) => DropdownMenuItem(
                                value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _term = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SPMTextField(
                    label: 'Score',
                    hint: '85',
                    controller: _scoreCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.score(
                        v, double.tryParse(_maxScoreCtrl.text) ?? 100),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SPMTextField(
                    label: 'Max Score',
                    hint: '100',
                    controller: _maxScoreCtrl,
                    keyboardType: TextInputType.number,
                    validator: Validators.positiveNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SPMTextField(
              label: 'Remarks (Optional)',
              hint: 'Any comments…',
              controller: _remarksCtrl,
              maxLines: 2,
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
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white)))
                  : const Text('Save Grade'),
            ),
          ],
        ),
      ),
    );
  }
}
