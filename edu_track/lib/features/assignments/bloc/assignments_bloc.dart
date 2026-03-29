import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/assignment_model.dart';
import '../../../core/services/firestore_service.dart';

part 'assignments_event.dart';
part 'assignments_state.dart';

class AssignmentsBloc extends Bloc<AssignmentsEvent, AssignmentsState> {
  final FirestoreService firestoreService;

  AssignmentsBloc({required this.firestoreService})
      : super(AssignmentsInitial()) {
    on<AssignmentsLoadRequested>(_onLoad, transformer: restartable());
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

    final sid = event.studentId?.trim();

    if (sid != null && sid.isNotEmpty) {
      final student = await firestoreService.getUser(sid);
      final courseIds = student?.enrolledCourseIds ?? [];
      final Stream<List<AssignmentModel>> stream;
      if (courseIds.isEmpty) {
        stream = firestoreService.allAssignments();
      } else if (courseIds.length == 1) {
        stream = firestoreService.assignmentsForClass(courseIds.first);
      } else {
        stream = firestoreService.assignmentsForCourses(courseIds);
      }

      final merged = _mergedStudentAssignmentsStream(
        assignments: stream,
        submissions: firestoreService.submissionsForStudent(sid),
        studentId: sid,
      );

      await emit.forEach<AssignmentsLoaded>(
        merged,
        onData: (loaded) => loaded,
        onError: (_, __) =>
            const AssignmentsError('Failed to load assignments.'),
      );
      return;
    }

    final tid = event.teacherId?.trim();
    if (tid != null && tid.isNotEmpty) {
      final merged = _mergedStaffAssignmentsStream(
        assignments: firestoreService.assignmentsForTeacher(tid),
        submissions: firestoreService.allSubmissions(),
        includeSubmission: (s, la) =>
            la.any((a) => a.id == s.assignmentId && a.teacherId == tid),
      );
      await emit.forEach<AssignmentsLoaded>(
        merged,
        onData: (loaded) => loaded,
        onError: (_, __) =>
            const AssignmentsError('Failed to load assignments.'),
      );
      return;
    }

    final mergedAdmin = _mergedStaffAssignmentsStream(
      assignments: firestoreService.allAssignments(),
      submissions: firestoreService.allSubmissions(),
      includeSubmission: (s, la) => la.any((a) => a.id == s.assignmentId),
    );
    await emit.forEach<AssignmentsLoaded>(
      mergedAdmin,
      onData: (loaded) => loaded,
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

/// Teacher / admin: assignments + all submissions, filtered to this scope.
Stream<AssignmentsLoaded> _mergedStaffAssignmentsStream({
  required Stream<List<AssignmentModel>> assignments,
  required Stream<List<SubmissionModel>> submissions,
  required bool Function(SubmissionModel s, List<AssignmentModel> la)
      includeSubmission,
}) {
  StreamSubscription<List<AssignmentModel>>? subA;
  StreamSubscription<List<SubmissionModel>>? subS;

  var la = <AssignmentModel>[];
  var ls = <SubmissionModel>[];

  late final StreamController<AssignmentsLoaded> controller;
  controller = StreamController<AssignmentsLoaded>(
    sync: true,
    onListen: () {
      void push() {
        if (controller.isClosed) return;
        final filtered = ls.where((s) => includeSubmission(s, la)).toList()
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        controller.add(AssignmentsLoaded(
          assignments: List<AssignmentModel>.from(la),
          submissions: filtered,
          studentId: null,
        ));
      }

      subA = assignments.listen(
        (list) {
          la = list;
          push();
        },
        onError: controller.addError,
      );
      subS = submissions.listen(
        (list) {
          ls = list;
          push();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await subA?.cancel();
      await subS?.cancel();
      subA = null;
      subS = null;
    },
  );

  return controller.stream;
}

/// Merges assignment list updates with the student’s submission snapshots.
Stream<AssignmentsLoaded> _mergedStudentAssignmentsStream({
  required Stream<List<AssignmentModel>> assignments,
  required Stream<List<SubmissionModel>> submissions,
  required String studentId,
}) {
  StreamSubscription<List<AssignmentModel>>? subA;
  StreamSubscription<List<SubmissionModel>>? subS;

  var la = <AssignmentModel>[];
  var ls = <SubmissionModel>[];

  late final StreamController<AssignmentsLoaded> controller;
  controller = StreamController<AssignmentsLoaded>(
    sync: true,
    onListen: () {
      void push() {
        if (controller.isClosed) return;
        final sorted = List<SubmissionModel>.from(ls)
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        controller.add(AssignmentsLoaded(
          assignments: List<AssignmentModel>.from(la),
          submissions: sorted,
          studentId: studentId,
        ));
      }

      subA = assignments.listen(
        (list) {
          la = list;
          push();
        },
        onError: controller.addError,
      );
      subS = submissions.listen(
        (list) {
          ls = list;
          push();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await subA?.cancel();
      await subS?.cancel();
      subA = null;
      subS = null;
    },
  );

  return controller.stream;
}
