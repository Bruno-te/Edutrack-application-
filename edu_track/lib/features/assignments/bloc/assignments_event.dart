part of 'assignments_bloc.dart';

abstract class AssignmentsEvent extends Equatable {
  const AssignmentsEvent();
  @override
  List<Object?> get props => [];
}

class AssignmentsLoadRequested extends AssignmentsEvent {
  final String? teacherId;
  final String? studentId;
  const AssignmentsLoadRequested({this.teacherId, this.studentId});
  @override
  List<Object?> get props => [teacherId, studentId];
}

class AssignmentAddRequested extends AssignmentsEvent {
  final AssignmentModel assignment;
  const AssignmentAddRequested(this.assignment);
  @override
  List<Object?> get props => [assignment];
}

class AssignmentUpdateRequested extends AssignmentsEvent {
  final String id;
  final Map<String, dynamic> data;
  const AssignmentUpdateRequested(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class AssignmentDeleteRequested extends AssignmentsEvent {
  final String id;
  const AssignmentDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class AssignmentSubmitRequested extends AssignmentsEvent {
  final SubmissionModel submission;
  const AssignmentSubmitRequested(this.submission);
  @override
  List<Object?> get props => [submission];
}

class SubmissionGradeRequested extends AssignmentsEvent {
  final String submissionId;
  final Map<String, dynamic> data;
  const SubmissionGradeRequested(this.submissionId, this.data);
  @override
  List<Object?> get props => [submissionId, data];
}
