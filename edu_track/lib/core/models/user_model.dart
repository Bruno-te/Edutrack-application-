import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String role; // 'admin' | 'teacher' | 'student' | 'parent'
  final String? photoUrl;
  final String? studentId;  // for student & parent linking
  final String? classId;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.photoUrl,
    this.studentId,
    this.classId,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      photoUrl: data['photoUrl'],
      studentId: data['studentId'],
      classId: data['classId'],
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
      [id, fullName, email, role, photoUrl, studentId, classId, createdAt];
}
