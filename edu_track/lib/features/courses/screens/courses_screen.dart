import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/course_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/shared_widgets.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _loading = true;
  List<CourseModel> _courses = const [];
  List<UserModel> _teachers = const [];
  List<UserModel> _students = const [];

  final _courseIdCtrl = TextEditingController();
  final _courseNameCtrl = TextEditingController();

  String? _teacherCourseId;
  String? _teacherId;

  String? _studentCourseId;
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _courseIdCtrl.dispose();
    _courseNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final fs = context.read<FirestoreService>();

    final courses = await fs.getCourses();
    final teachers = await fs.getUsersByRole('teacher');
    final students = await fs.getUsersByRole('student');

    setState(() {
      _courses = courses;
      _teachers = teachers;
      _students = students;

      _teacherCourseId ??= courses.isNotEmpty ? courses.first.id : null;
      _studentCourseId ??= courses.isNotEmpty ? courses.first.id : null;
      _teacherId ??= teachers.isNotEmpty ? teachers.first.id : null;
      _studentId ??= students.isNotEmpty ? students.first.id : null;
    });

    setState(() => _loading = false);
  }

  UserModel? _teacherForCourse(String courseId) {
    for (final t in _teachers) {
      if (t.classId == courseId) return t;
    }
    return null;
  }

  Future<void> _createCourse() async {
    final id = _courseIdCtrl.text.trim();
    final name = _courseNameCtrl.text.trim();
    if (id.isEmpty) return;

    final fs = context.read<FirestoreService>();
    await fs.upsertCourse(
      CourseModel(id: id, name: name, createdAt: DateTime.now()),
    );

    _courseIdCtrl.clear();
    _courseNameCtrl.clear();
    await _reload();
  }

  Future<void> _assignTeacher() async {
    if (_teacherId == null || _teacherCourseId == null) return;
    final fs = context.read<FirestoreService>();
    await fs.assignTeacherToCourse(_teacherId!, _teacherCourseId!);
    await _reload();
  }

  Future<void> _assignStudent() async {
    if (_studentId == null || _studentCourseId == null) return;
    final fs = context.read<FirestoreService>();
    await fs.assignStudentsToCourse([_studentId!], _studentCourseId!);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Courses'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Create Course'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SPMTextField(
                            label: 'Course ID (classId)',
                            hint: 'e.g. Course-10A',
                            controller: _courseIdCtrl,
                          ),
                          const SizedBox(height: 12),
                          SPMTextField(
                            label: 'Course Name',
                            hint: 'e.g. Mathematics 10A',
                            controller: _courseNameCtrl,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton(
                              onPressed: () async => _createCourse(),
                              child: const Text('Add Course'),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Assign Teacher to Course'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _teacherCourseId,
                            items: _courses
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name.isEmpty ? c.id : c.name),
                                    ))
                                .toList(),
                            onChanged: _courses.isEmpty ? null : (v) => setState(() => _teacherCourseId = v),
                            decoration: const InputDecoration(
                              labelText: 'Course',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _teacherId,
                            items: _teachers
                                .map((t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Text(t.fullName),
                                    ))
                                .toList(),
                            onChanged: _teachers.isEmpty ? null : (v) => setState(() => _teacherId = v),
                            decoration: const InputDecoration(
                              labelText: 'Teacher',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton(
                              onPressed: (_courses.isEmpty ||
                                      _teachers.isEmpty ||
                                      _teacherId == null ||
                                      _teacherCourseId == null)
                                  ? null
                                  : () async => _assignTeacher(),
                              child: const Text('Assign'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Assign Student to Course'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _studentCourseId,
                            items: _courses
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name.isEmpty ? c.id : c.name),
                                    ))
                                .toList(),
                            onChanged: _courses.isEmpty ? null : (v) => setState(() => _studentCourseId = v),
                            decoration: const InputDecoration(
                              labelText: 'Course',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _studentId,
                            items: _students
                                .map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(s.fullName),
                                    ))
                                .toList(),
                            onChanged: _students.isEmpty ? null : (v) => setState(() => _studentId = v),
                            decoration: const InputDecoration(
                              labelText: 'Student',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton(
                              onPressed: (_courses.isEmpty ||
                                      _students.isEmpty ||
                                      _studentId == null ||
                                      _studentCourseId == null)
                                  ? null
                                  : () async => _assignStudent(),
                              child: const Text('Assign'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Students can be in multiple courses. Assigning adds this course without removing others.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Course Summary'),
                  const SizedBox(height: 12),
                  if (_courses.isEmpty)
                    const EmptyState(
                      icon: Icons.school_outlined,
                      title: 'No courses yet',
                      subtitle: 'Create a course above to start assigning teachers and students.',
                    )
                  else
                    ..._courses.map((c) {
                      final teacher = _teacherForCourse(c.id);
                      final enrolled = _students
                          .where((s) => s.isEnrolledInCourse(c.id))
                          .toList()
                        ..sort((a, b) => a.fullName.compareTo(b.fullName));
                      final studentCount = enrolled.length;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Text(
                            c.name.isEmpty ? c.id : c.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${c.id} · $studentCount student${studentCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Teacher: ${teacher?.fullName ?? 'Unassigned'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Enrolled students',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (enrolled.isEmpty)
                                    Text(
                                      'No students yet. Use Assign Student above.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.warning.withOpacity(0.95),
                                      ),
                                    )
                                  else
                                    ...enrolled.map(
                                      (s) => ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.12),
                                          child: Text(
                                            s.initials,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        title: Text(s.fullName),
                                        subtitle: Text(
                                          'Account ID: ${s.id}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

