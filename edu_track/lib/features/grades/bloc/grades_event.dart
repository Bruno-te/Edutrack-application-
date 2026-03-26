part of 'grades_bloc.dart';

abstract class GradesEvent extends Equatable {
  const GradesEvent();
  @override
  List<Object?> get props => [];
}

class GradesLoadRequested extends GradesEvent {
  final String? studentId;
  final String? teacherId;
  const GradesLoadRequested({this.studentId, this.teacherId});
  @override
  List<Object?> get props => [studentId, teacherId];
}

class GradeAddRequested extends GradesEvent {
  final GradeModel grade;
  const GradeAddRequested(this.grade);
  @override
  List<Object?> get props => [grade];
}

class GradeUpdateRequested extends GradesEvent {
  final String id;
  final Map<String, dynamic> data;
  const GradeUpdateRequested(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class GradeDeleteRequested extends GradesEvent {
  final String id;
  const GradeDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class GradesFiltered extends GradesEvent {
  final String? subject;
  final String? term;
  final String? gradeType;
  const GradesFiltered({this.subject, this.term, this.gradeType});
  @override
  List<Object?> get props => [subject, term, gradeType];
}
