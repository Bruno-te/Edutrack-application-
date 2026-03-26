import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/assignment_model.dart';
import '../../../core/services/firestore_service.dart';

part 'assignments_event.dart';
part 'assignments_state.dart';

class AssignmentsBloc extends Bloc<AssignmentsEvent, AssignmentsState> {
  final FirestoreService firestoreService;

  AssignmentsBloc({required this.firestoreService})
      : super(AssignmentsInitial()) {
    on<AssignmentsLoadRequested>(_onLoad);
    on<AssignmentAddRequested>(_onAdd);
    on<AssignmentUpdateRequested>(_onUpdate);
    on<AssignmentDeleteRequested>(_onDelete);
    on<AssignmentSubmitRequested>(_onSubmit);
    on<SubmissionGradeRequested>(_onGrade);
  }

  Future<void> _onLoad(
      AssignmentsLoadRequested event,
      Emitter<AssignmentsState> emit) async {
    emit(AssignmentsLoading());

    Stream<List<AssignmentModel>> stream;
    if (event.teacherId != null) {
      stream = firestoreService.assignmentsForTeacher(event.teacherId!);
    } else if (event.studentId != null) {
      final student = await firestoreService.getUser(event.studentId!);
      final classId = student?.classId;
      if (classId != null && classId.isNotEmpty) {
        stream = firestoreService.assignmentsForClass(classId);
      } else {
        // Fallback when student isn't assigned to a class yet.
        stream = firestoreService.allAssignments();
      }
    } else {
      stream = firestoreService.allAssignments();
    }

    await emit.forEach<List<AssignmentModel>>(
      stream,
      onData: (list) => AssignmentsLoaded(
        assignments: list,
        studentId: event.studentId,
      ),
      onError: (_, __) =>
          const AssignmentsError('Failed to load assignments.'),
    );
  }

  Future<void> _onAdd(
      AssignmentAddRequested event,
      Emitter<AssignmentsState> emit) async {
    try {
      await firestoreService.addAssignment(event.assignment);
      emit(const AssignmentOperationSuccess('Assignment created!'));
    } catch (e) {
      emit(AssignmentsError(e.toString()));
    }
  }

  Future<void> _onUpdate(
      AssignmentUpdateRequested event,
      Emitter<AssignmentsState> emit) async {
    try {
      await firestoreService.updateAssignment(event.id, event.data);
      emit(const AssignmentOperationSuccess('Assignment updated!'));
    } catch (e) {
      emit(AssignmentsError(e.toString()));
    }
  }

  Future<void> _onDelete(
      AssignmentDeleteRequested event,
      Emitter<AssignmentsState> emit) async {
    try {
      await firestoreService.deleteAssignment(event.id);
      emit(const AssignmentOperationSuccess('Assignment deleted!'));
    } catch (e) {
      emit(AssignmentsError(e.toString()));
    }
  }

  Future<void> _onSubmit(
      AssignmentSubmitRequested event,
      Emitter<AssignmentsState> emit) async {
    try {
      await firestoreService.submitAssignment(event.submission);
      emit(const AssignmentOperationSuccess('Assignment submitted!'));
    } catch (e) {
      emit(AssignmentsError(e.toString()));
    }
  }

  Future<void> _onGrade(
      SubmissionGradeRequested event,
      Emitter<AssignmentsState> emit) async {
    try {
      await firestoreService.gradeSubmission(
          event.submissionId, event.data);
      emit(const AssignmentOperationSuccess('Submission graded!'));
    } catch (e) {
      emit(AssignmentsError(e.toString()));
    }
  }
}
