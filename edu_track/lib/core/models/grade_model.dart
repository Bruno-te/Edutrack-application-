import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GradeModel extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String subject;
  final double score;
  final double maxScore;
  final String gradeType; // 'Quiz' | 'Exam' | 'Assignment' | 'Project'
  final String term;      // 'Term 1' | 'Term 2' | 'Term 3'
  final String teacherId;
  final String? classId;
  final String? remarks;
  final DateTime date;

  const GradeModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subject,
    required this.score,
    required this.maxScore,
    required this.gradeType,
    required this.term,
    required this.teacherId,
    this.classId,
    this.remarks,
    required this.date,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  String get letterGrade {
    final p = percentage;
    if (p >= 90) return 'A+';
    if (p >= 80) return 'A';
    if (p >= 70) return 'B';
    if (p >= 60) return 'C';
    if (p >= 50) return 'D';
    return 'F';
  }

  factory GradeModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GradeModel(
      id: doc.id,
      studentId: d['studentId'] ?? '',
      studentName: d['studentName'] ?? '',
      subject: d['subject'] ?? '',
      score: (d['score'] ?? 0).toDouble(),
      maxScore: (d['maxScore'] ?? 100).toDouble(),
      gradeType: d['gradeType'] ?? 'Exam',
      term: d['term'] ?? 'Term 1',
      teacherId: d['teacherId'] ?? '',
      classId: d['classId'],
      remarks: d['remarks'],
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'studentName': studentName,
        'subject': subject,
        'score': score,
        'maxScore': maxScore,
        'gradeType': gradeType,
        'term': term,
        'teacherId': teacherId,
        'classId': classId,
        'remarks': remarks,
        'date': Timestamp.fromDate(date),
      };

  GradeModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? subject,
    double? score,
    double? maxScore,
    String? gradeType,
    String? term,
    String? teacherId,
    String? classId,
    String? remarks,
    DateTime? date,
  }) =>
      GradeModel(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        studentName: studentName ?? this.studentName,
        subject: subject ?? this.subject,
        score: score ?? this.score,
        maxScore: maxScore ?? this.maxScore,
        gradeType: gradeType ?? this.gradeType,
        term: term ?? this.term,
        teacherId: teacherId ?? this.teacherId,
        classId: classId ?? this.classId,
        remarks: remarks ?? this.remarks,
        date: date ?? this.date,
      );

  @override
  List<Object?> get props => [
        id, studentId, studentName, subject, score, maxScore,
        gradeType, term, teacherId, classId, remarks, date
      ];
}
