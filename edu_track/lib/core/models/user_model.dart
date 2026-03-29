import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String role; // 'admin' | 'teacher' | 'student' | 'parent'
  final String? photoUrl;
  final String? studentId; // for student & parent linking
  /// Legacy single-course field; still merged into [enrolledCourseIds].
  final String? classId;
  /// Courses this student is enrolled in (supports multiple).
  final List<String> courseIds;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.photoUrl,
    this.studentId,
    this.classId,
    this.courseIds = const [],
    required this.createdAt,
  });

  /// Effective course IDs: explicit enrollments plus legacy [classId].
  List<String> get enrolledCourseIds {
    final ids = <String>{};
    for (final c in courseIds) {
      if (c.trim().isNotEmpty) ids.add(c.trim());
    }
    final legacy = classId?.trim();
    if (legacy != null && legacy.isNotEmpty) ids.add(legacy);
    final list = ids.toList();
    list.sort();
    return list;
  }

  bool isEnrolledInCourse(String courseId) {
    final c = courseId.trim();
    if (c.isEmpty) return false;
    return enrolledCourseIds.contains(c);
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawCourses = data['courseIds'];
    final List<String> parsedCourses = [];
    if (rawCourses is List) {
      for (final e in rawCourses) {
        final s = e.toString().trim();
        if (s.isNotEmpty) parsedCourses.add(s);
      }
    }

    return UserModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      photoUrl: data['photoUrl'],
      studentId: data['studentId'],
      classId: data['classId'],
      courseIds: parsedCourses,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'email': email,
        'role': role,
        'photoUrl': photoUrl,
        'studentId': studentId,
        'classId': classId,
        'courseIds': courseIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props =>
      [id, fullName, email, role, photoUrl, studentId, classId, courseIds, createdAt];
}
