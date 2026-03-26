import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AssignmentStatus { pending, submitted, graded, overdue }

extension AssignmentStatusX on AssignmentStatus {
  String get label {
    switch (this) {
      case AssignmentStatus.pending:   return 'Pending';
      case AssignmentStatus.submitted: return 'Submitted';
      case AssignmentStatus.graded:    return 'Graded';
      case AssignmentStatus.overdue:   return 'Overdue';
    }
  }

  static AssignmentStatus fromString(String s) {
    switch (s) {
      case 'submitted': return AssignmentStatus.submitted;
      case 'graded':    return AssignmentStatus.graded;
      case 'overdue':   return AssignmentStatus.overdue;
      case 'pending':
      default:          return AssignmentStatus.pending;
    }
  }
}

class AssignmentModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String classId;
  final String teacherId;
  final double maxMarks;
  final DateTime dueDate;
  final DateTime createdAt;

  const AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.classId,
    required this.teacherId,
    required this.maxMarks,
    required this.dueDate,
    required this.createdAt,
  });

  bool get isOverdue => DateTime.now().isAfter(dueDate);

  factory AssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AssignmentModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      subject: d['subject'] ?? '',
      classId: d['classId'] ?? '',
      teacherId: d['teacherId'] ?? '',
      maxMarks: (d['maxMarks'] ?? 100).toDouble(),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'subject': subject,
        'classId': classId,
        'teacherId': teacherId,
        'maxMarks': maxMarks,
        'dueDate': Timestamp.fromDate(dueDate),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  AssignmentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    String? classId,
    String? teacherId,
    double? maxMarks,
    DateTime? dueDate,
    DateTime? createdAt,
  }) =>
      AssignmentModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        subject: subject ?? this.subject,
        classId: classId ?? this.classId,
        teacherId: teacherId ?? this.teacherId,
        maxMarks: maxMarks ?? this.maxMarks,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props =>
      [id, title, description, subject, classId, teacherId, maxMarks, dueDate, createdAt];
}

// Submission by a student
class SubmissionModel extends Equatable {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final AssignmentStatus status;
  final double? marksObtained;
  final String? remarks;
  final DateTime submittedAt;

  const SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.status,
    this.marksObtained,
    this.remarks,
    required this.submittedAt,
  });

  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SubmissionModel(
      id: doc.id,
      assignmentId: d['assignmentId'] ?? '',
      studentId: d['studentId'] ?? '',
      studentName: d['studentName'] ?? '',
      status: AssignmentStatusX.fromString(d['status'] ?? 'submitted'),
      marksObtained: d['marksObtained']?.toDouble(),
      remarks: d['remarks'],
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'assignmentId': assignmentId,
        'studentId': studentId,
        'studentName': studentName,
        'status': status.name,
        'marksObtained': marksObtained,
        'remarks': remarks,
        'submittedAt': Timestamp.fromDate(submittedAt),
      };

  @override
  List<Object?> get props =>
      [id, assignmentId, studentId, studentName, status, marksObtained, remarks, submittedAt];
}
