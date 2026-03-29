import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/assignment_model.dart';
import '../models/course_model.dart';
import '../models/attendance_model.dart';
import '../models/grade_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collections ────────────────────────────────────────────────
  CollectionReference get _users       => _db.collection('users');
  CollectionReference get _courses     => _db.collection('courses');
  CollectionReference get _grades      => _db.collection('grades');
  CollectionReference get _attendance  => _db.collection('attendance');
  CollectionReference get _assignments => _db.collection('assignments');
  CollectionReference get _submissions => _db.collection('submissions');

  // ═══════════════════════════════════════════════════════════════
  // USERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    final snap = await _users.where('role', isEqualTo: role).get();
    final list = snap.docs.map(UserModel.fromFirestore).toList();
    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    return list;
  }

  // ═══════════════════════════════════════════════════════════════
  // COURSES (admin management)
  // ═══════════════════════════════════════════════════════════════

  Future<void> upsertCourse(CourseModel course) async {
    await _courses.doc(course.id).set(course.toMap());
  }

  Future<List<CourseModel>> getCourses() async {
    final snap = await _courses.get();
    final list = snap.docs.map(CourseModel.fromFirestore).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> deleteCourse(String courseId) async {
    await _courses.doc(courseId).delete();
  }

  Future<void> assignTeacherToCourse(String teacherId, String courseId) async {
    await updateUser(teacherId, {'classId': courseId});
  }

  /// Adds [courseId] to each student's `courseIds` without removing prior
  /// enrollments (multi-course support). Legacy `classId` is unchanged.
  Future<void> assignStudentsToCourse(
    List<String> studentIds,
    String courseId,
  ) async {
    if (courseId.trim().isEmpty) return;
    final cid = courseId.trim();
    final batch = _db.batch();
    for (final sid in studentIds) {
      batch.update(_users.doc(sid), {
        'courseIds': FieldValue.arrayUnion([cid]),
      });
    }
    await batch.commit();
  }

  // Convenience: when you have a classId but not its display name.
  Future<CourseModel?> getCourseById(String courseId) async {
    final doc = await _courses.doc(courseId).get();
    if (!doc.exists) return null;
    return CourseModel.fromFirestore(doc);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  /// Sets the parent's `studentId` to the child's Firebase user id (Account ID).
  Future<void> linkParentToChild({
    required String parentUserId,
    required String childStudentUserId,
  }) async {
    await updateUser(parentUserId, {'studentId': childStudentUserId});
  }

  // ═══════════════════════════════════════════════════════════════
  // GRADES
  // ═══════════════════════════════════════════════════════════════

  Future<String> addGrade(GradeModel grade) async {
    final ref = await _grades.add(grade.toMap());
    return ref.id;
  }

  Future<void> updateGrade(String id, Map<String, dynamic> data) async {
    await _grades.doc(id).update(data);
  }

  Future<void> deleteGrade(String id) async {
    await _grades.doc(id).delete();
  }

  Stream<List<GradeModel>> gradesForStudent(String studentId) {
    return _grades
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(GradeModel.fromFirestore).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<GradeModel>> gradesForTeacher(String teacherId) {
    return _grades
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(GradeModel.fromFirestore).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<GradeModel>> allGrades() {
    return _grades
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(GradeModel.fromFirestore).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<List<GradeModel>> getGradesForStudent(String studentId) async {
    // Avoid `where + orderBy` index requirements by sorting locally.
    final snap = await _grades.where('studentId', isEqualTo: studentId).get();
    final list = snap.docs.map(GradeModel.fromFirestore).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<List<GradeModel>> getGradesForTeacherData(String teacherId) async {
    final snap = await _grades.where('teacherId', isEqualTo: teacherId).get();
    final list = snap.docs.map(GradeModel.fromFirestore).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ═══════════════════════════════════════════════════════════════
  // ATTENDANCE
  // ═══════════════════════════════════════════════════════════════

  Future<String> markAttendance(AttendanceModel record) async {
    final ref = await _attendance.add(record.toMap());
    return ref.id;
  }

  Future<void> updateAttendance(String id, Map<String, dynamic> data) async {
    await _attendance.doc(id).update(data);
  }

  Future<void> deleteAttendance(String id) async {
    await _attendance.doc(id).delete();
  }

  Stream<List<AttendanceModel>> attendanceForStudent(String studentId) {
    return _attendance
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AttendanceModel.fromFirestore).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<AttendanceModel>> attendanceByTeacher(String teacherId) {
    return _attendance
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AttendanceModel.fromFirestore).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<AttendanceModel>> allAttendance() {
    return _attendance
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AttendanceModel.fromFirestore).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<List<AttendanceModel>> getAttendanceForStudent(String studentId) async {
    // Avoid `where + orderBy` index requirements by sorting locally.
    final snap =
        await _attendance.where('studentId', isEqualTo: studentId).get();
    final list = snap.docs.map(AttendanceModel.fromFirestore).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // Dashboard/analytics helpers (fetch without composite index requirements)
  Future<List<GradeModel>> getAllGrades() async {
    final snap = await _grades.get();
    final list = snap.docs.map(GradeModel.fromFirestore).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<List<GradeModel>> getGradesForClass(String classId) async {
    final snap =
        await _grades.where('classId', isEqualTo: classId).get();
    final list = snap.docs.map(GradeModel.fromFirestore).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<List<AttendanceModel>> getAllAttendance() async {
    final snap = await _attendance.get();
    final list = snap.docs.map(AttendanceModel.fromFirestore).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ═══════════════════════════════════════════════════════════════
  // ASSIGNMENTS
  // ═══════════════════════════════════════════════════════════════

  Future<String> addAssignment(AssignmentModel assignment) async {
    final ref = await _assignments.add(assignment.toMap());
    return ref.id;
  }

  Future<void> updateAssignment(String id, Map<String, dynamic> data) async {
    await _assignments.doc(id).update(data);
  }

  Future<void> deleteAssignment(String id) async {
    await _assignments.doc(id).delete();
  }

  Stream<List<AssignmentModel>> assignmentsForTeacher(String teacherId) {
    return _assignments
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AssignmentModel.fromFirestore).toList();
      list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
      return list;
    });
  }

  Stream<List<AssignmentModel>> assignmentsForClass(String classId) {
    return _assignments
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AssignmentModel.fromFirestore).toList();
      list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
      return list;
    });
  }

  /// Assignments for any of [courseIds] (student enrolled in multiple courses).
  /// Firestore `whereIn` supports up to 30 values.
  Stream<List<AssignmentModel>> assignmentsForCourses(List<String> courseIds) {
    final ids = courseIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    if (ids.isEmpty) {
      return Stream.value([]);
    }
    if (ids.length > 30) {
      ids.removeRange(30, ids.length);
    }
    return _assignments
        .where('classId', whereIn: ids)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AssignmentModel.fromFirestore).toList();
      list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
      return list;
    });
  }

  Stream<List<AssignmentModel>> allAssignments() {
    return _assignments
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AssignmentModel.fromFirestore).toList();
      list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
      return list;
    });
  }

  Future<List<AssignmentModel>> getAssignmentsForClass(String classId) async {
    final snap =
        await _assignments.where('classId', isEqualTo: classId).get();
    final list = snap.docs.map(AssignmentModel.fromFirestore).toList();
    list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    return list;
  }

  Future<List<AssignmentModel>> getAssignmentsForTeacherData(
    String teacherId,
  ) async {
    final snap = await _assignments.where('teacherId', isEqualTo: teacherId).get();
    final list = snap.docs.map(AssignmentModel.fromFirestore).toList();
    list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    return list;
  }

  // ═══════════════════════════════════════════════════════════════
  // SUBMISSIONS
  // ═══════════════════════════════════════════════════════════════

  Future<String> submitAssignment(SubmissionModel submission) async {
    final ref = await _submissions.add(submission.toMap());
    return ref.id;
  }

  Future<void> gradeSubmission(String id, Map<String, dynamic> data) async {
    await _submissions.doc(id).update({
      ...data,
      'status': AssignmentStatus.graded.name,
    });
  }

  Stream<List<SubmissionModel>> submissionsForAssignment(String assignmentId) {
    return _submissions
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map((snap) => snap.docs.map(SubmissionModel.fromFirestore).toList());
  }

  Stream<List<SubmissionModel>> submissionsForStudent(String studentId) {
    return _submissions
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) => snap.docs.map(SubmissionModel.fromFirestore).toList());
  }

  /// All submissions (for teacher/admin views; filtered in app by assignment).
  Stream<List<SubmissionModel>> allSubmissions() {
    return _submissions.snapshots().map((snap) {
      final list = snap.docs.map(SubmissionModel.fromFirestore).toList();
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }

  Future<List<SubmissionModel>> getSubmissionsForStudentData(
    String studentId,
  ) async {
    final snap = await _submissions.where('studentId', isEqualTo: studentId).get();
    final list = snap.docs.map(SubmissionModel.fromFirestore).toList();
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }

  /// Live updates for student/parent home stats (grades, attendance, submissions).
  Stream<
      ({
        List<GradeModel> grades,
        List<AttendanceModel> attendance,
        List<SubmissionModel> submissions,
      })> watchStudentHomeData(String studentId) {
    StreamSubscription<List<GradeModel>>? subG;
    StreamSubscription<List<AttendanceModel>>? subA;
    StreamSubscription<List<SubmissionModel>>? subS;

    var grades = <GradeModel>[];
    var attendance = <AttendanceModel>[];
    var submissions = <SubmissionModel>[];

    late final StreamController<
        ({
          List<GradeModel> grades,
          List<AttendanceModel> attendance,
          List<SubmissionModel> submissions,
        })> controller;
    controller = StreamController<
        ({
          List<GradeModel> grades,
          List<AttendanceModel> attendance,
          List<SubmissionModel> submissions,
        })>(
      sync: true,
      onListen: () {
        void push() {
          if (controller.isClosed) return;
          final subs = List<SubmissionModel>.from(submissions)
            ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          controller.add((
            grades: List<GradeModel>.from(grades),
            attendance: List<AttendanceModel>.from(attendance),
            submissions: subs,
          ));
        }

        subG = gradesForStudent(studentId).listen(
          (g) {
            grades = g;
            push();
          },
          onError: controller.addError,
        );
        subA = attendanceForStudent(studentId).listen(
          (a) {
            attendance = a;
            push();
          },
          onError: controller.addError,
        );
        subS = submissionsForStudent(studentId).listen(
          (s) {
            submissions = s;
            push();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await subG?.cancel();
        await subA?.cancel();
        await subS?.cancel();
        subG = null;
        subA = null;
        subS = null;
      },
    );

    return controller.stream;
  }

  /// Live grades + attendance for the Performance screen (student/parent scoped).
  Stream<
      ({
        List<GradeModel> grades,
        List<AttendanceModel> attendance,
      })> watchPerformanceForStudent(String studentId) {
    StreamSubscription<List<GradeModel>>? subG;
    StreamSubscription<List<AttendanceModel>>? subA;

    var grades = <GradeModel>[];
    var attendance = <AttendanceModel>[];

    late final StreamController<
        ({
          List<GradeModel> grades,
          List<AttendanceModel> attendance,
        })> controller;
    controller = StreamController<
        ({
          List<GradeModel> grades,
          List<AttendanceModel> attendance,
        })>(
      sync: true,
      onListen: () {
        void push() {
          if (controller.isClosed) return;
          controller.add((
            grades: List<GradeModel>.from(grades),
            attendance: List<AttendanceModel>.from(attendance),
          ));
        }

        subG = gradesForStudent(studentId).listen(
          (g) {
            grades = g;
            push();
          },
          onError: controller.addError,
        );
        subA = attendanceForStudent(studentId).listen(
          (a) {
            attendance = a;
            push();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await subG?.cancel();
        await subA?.cancel();
        subG = null;
        subA = null;
      },
    );

    return controller.stream;
  }

  // ═══════════════════════════════════════════════════════════════
  // DASHBOARD STATS
  // ═══════════════════════════════════════════════════════════════

  Future<Map<String, int>> getDashboardCounts() async {
    final results = await Future.wait([
      _users.where('role', isEqualTo: 'student').count().get(),
      _users.where('role', isEqualTo: 'teacher').count().get(),
      _assignments.count().get(),
      _grades.count().get(),
    ]);
    return {
      'students':    results[0].count ?? 0,
      'teachers':    results[1].count ?? 0,
      'assignments': results[2].count ?? 0,
      'grades':      results[3].count ?? 0,
    };
  }
}
