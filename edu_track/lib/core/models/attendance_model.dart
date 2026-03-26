import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusX on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present: return 'Present';
      case AttendanceStatus.absent:  return 'Absent';
      case AttendanceStatus.late:    return 'Late';
      case AttendanceStatus.excused: return 'Excused';
    }
  }

  static AttendanceStatus fromString(String s) {
    switch (s) {
      case 'absent':  return AttendanceStatus.absent;
      case 'late':    return AttendanceStatus.late;
      case 'excused': return AttendanceStatus.excused;
      case 'present':
      default:        return AttendanceStatus.present;
    }
  }
}

class AttendanceModel extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String classId;
  final String subject;
  final AttendanceStatus status;
  final String teacherId;
  final String? remarks;
  final DateTime date;

  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.subject,
    required this.status,
    required this.teacherId,
    this.remarks,
    required this.date,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      studentId: d['studentId'] ?? '',
      studentName: d['studentName'] ?? '',
      classId: d['classId'] ?? '',
      subject: d['subject'] ?? '',
      status: AttendanceStatusX.fromString(d['status'] ?? 'present'),
      teacherId: d['teacherId'] ?? '',
      remarks: d['remarks'],
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'studentName': studentName,
        'classId': classId,
        'subject': subject,
        'status': status.name,
        'teacherId': teacherId,
        'remarks': remarks,
        'date': Timestamp.fromDate(date),
      };

  @override
  List<Object?> get props =>
      [id, studentId, studentName, classId, subject, status, teacherId, remarks, date];
}
