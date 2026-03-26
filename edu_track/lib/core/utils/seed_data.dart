import 'package:cloud_firestore/cloud_firestore.dart';

/// Run this once to populate Firestore with realistic test data.
/// Call: await SeedData.seed();
/// Remove or comment out after seeding.
class SeedData {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seed() async {
    await _seedGrades();
    await _seedAttendance();
    await _seedAssignments();
    print('✅ Seed data inserted successfully!');
  }

  // ── Sample student IDs (replace with real UIDs from your auth) ──
  static const String _sampleStudentId   = 'STUDENT_UID_HERE';
  static const String _sampleStudentName = 'Alice Johnson';
  static const String _sampleTeacherId   = 'TEACHER_UID_HERE';
  static const String _sampleClassId     = 'CLASS-10A';

  // ── Grades ──────────────────────────────────────────────────────
  static Future<void> _seedGrades() async {
    final grades = [
      // Term 1
      _grade('Mathematics', 88, 100, 'Exam',       'Term 1'),
      _grade('Mathematics', 72, 100, 'Quiz',        'Term 1'),
      _grade('English',     91, 100, 'Assignment',  'Term 1'),
      _grade('Science',     78, 100, 'Exam',        'Term 1'),
      _grade('History',     65, 100, 'Exam',        'Term 1'),
      _grade('Art',         95, 100, 'Project',     'Term 1'),

      // Term 2
      _grade('Mathematics', 82, 100, 'Exam',        'Term 2'),
      _grade('Mathematics', 76, 100, 'Quiz',        'Term 2'),
      _grade('English',     87, 100, 'Exam',        'Term 2'),
      _grade('Science',     80, 100, 'Project',     'Term 2'),
      _grade('History',     70, 100, 'Assignment',  'Term 2'),

      // Term 3
      _grade('Mathematics', 90, 100, 'Exam',        'Term 3'),
      _grade('English',     93, 100, 'Exam',        'Term 3'),
      _grade('Science',     85, 100, 'Exam',        'Term 3'),
      _grade('History',     74, 100, 'Exam',        'Term 3'),
    ];

    final batch = _db.batch();
    for (final g in grades) {
      batch.set(_db.collection('grades').doc(), g);
    }
    await batch.commit();
  }

  static Map<String, dynamic> _grade(
    String subject,
    double score,
    double maxScore,
    String type,
    String term,
  ) =>
      {
        'studentId':   _sampleStudentId,
        'studentName': _sampleStudentName,
        'subject':     subject,
        'score':       score,
        'maxScore':    maxScore,
        'gradeType':   type,
        'term':        term,
        'teacherId':   _sampleTeacherId,
        'classId':     _sampleClassId,
        'remarks':     null,
        'date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 10))),
      };

  // ── Attendance ───────────────────────────────────────────────────
  static Future<void> _seedAttendance() async {
    final statuses = [
      'present', 'present', 'present', 'absent',
      'present', 'late',    'present', 'present',
      'excused', 'present',
    ];

    final batch = _db.batch();
    for (int i = 0; i < statuses.length; i++) {
      batch.set(_db.collection('attendance').doc(), {
        'studentId':   _sampleStudentId,
        'studentName': _sampleStudentName,
        'classId':     _sampleClassId,
        'subject':     'Mathematics',
        'status':      statuses[i],
        'teacherId':   _sampleTeacherId,
        'remarks':     null,
        'date': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: i))),
      });
    }
    await batch.commit();
  }

  // ── Assignments ──────────────────────────────────────────────────
  static Future<void> _seedAssignments() async {
    final assignments = [
      _assignment(
        title: 'Chapter 5 Quiz',
        description: 'Complete the quiz on algebraic expressions.',
        subject: 'Mathematics',
        maxMarks: 50,
        dueDays: 3,
      ),
      _assignment(
        title: 'Essay: Climate Change',
        description:
            'Write a 500-word essay on the effects of climate change.',
        subject: 'English',
        maxMarks: 100,
        dueDays: 7,
      ),
      _assignment(
        title: 'Lab Report',
        description: 'Submit the lab report for the chemical reactions experiment.',
        subject: 'Science',
        maxMarks: 75,
        dueDays: 5,
      ),
      _assignment(
        title: 'History Timeline',
        description:
            'Create a visual timeline of major events in World War II.',
        subject: 'History',
        maxMarks: 100,
        dueDays: -2, // overdue
      ),
      _assignment(
        title: 'Art Portfolio',
        description: 'Submit 5 original artworks for portfolio assessment.',
        subject: 'Art',
        maxMarks: 100,
        dueDays: 14,
      ),
    ];

    final batch = _db.batch();
    for (final a in assignments) {
      batch.set(_db.collection('assignments').doc(), a);
    }
    await batch.commit();
  }

  static Map<String, dynamic> _assignment({
    required String title,
    required String description,
    required String subject,
    required double maxMarks,
    required int dueDays,
  }) =>
      {
        'title':       title,
        'description': description,
        'subject':     subject,
        'classId':     _sampleClassId,
        'teacherId':   _sampleTeacherId,
        'maxMarks':    maxMarks,
        'dueDate': Timestamp.fromDate(
            DateTime.now().add(Duration(days: dueDays))),
        'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 3))),
      };
}
