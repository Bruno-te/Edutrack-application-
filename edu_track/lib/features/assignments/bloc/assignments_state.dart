part of 'assignments_bloc.dart';

abstract class AssignmentsState extends Equatable {
  const AssignmentsState();
  @override
  List<Object?> get props => [];
}

class AssignmentsInitial extends AssignmentsState {}

class AssignmentsLoading extends AssignmentsState {}

class AssignmentsLoaded extends AssignmentsState {
  final List<AssignmentModel> assignments;
  /// Submissions for the current scope (student’s rows, or staff-filtered list).
  final List<SubmissionModel> submissions;
  final String? studentId;

  const AssignmentsLoaded({
    required this.assignments,
    this.submissions = const [],
    this.studentId,
  });

  List<AssignmentModel> get upcoming => assignments
      .where((a) => !a.isOverdue)
      .toList();

  List<AssignmentModel> get overdue => assignments
      .where((a) => a.isOverdue)
      .toList();

  @override
  List<Object?> get props => [assignments, submissions, studentId];
}

class AssignmentsError extends AssignmentsState {
  final String message;
  const AssignmentsError(this.message);
  @override
  List<Object?> get props => [message];
}

class AssignmentOperationSuccess extends AssignmentsState {
  final String message;
  const AssignmentOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
