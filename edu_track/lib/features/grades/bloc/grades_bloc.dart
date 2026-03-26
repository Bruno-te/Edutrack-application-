import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/grade_model.dart';
import '../../../core/services/firestore_service.dart';

part 'grades_event.dart';
part 'grades_state.dart';

class GradesBloc extends Bloc<GradesEvent, GradesState> {
  final FirestoreService firestoreService;
  StreamSubscription<List<GradeModel>>? _gradesSub;

  GradesBloc({required this.firestoreService}) : super(GradesInitial()) {
    on<GradesLoadRequested>(_onLoad);
    on<GradeAddRequested>(_onAdd);
    on<GradeUpdateRequested>(_onUpdate);
    on<GradeDeleteRequested>(_onDelete);
    on<GradesFiltered>(_onFilter);
  }

  Future<void> _onLoad(
      GradesLoadRequested event, Emitter<GradesState> emit) async {
    emit(GradesLoading());
    await _gradesSub?.cancel();

    Stream<List<GradeModel>> stream;
    if (event.studentId != null) {
      stream = firestoreService.gradesForStudent(event.studentId!);
    } else if (event.teacherId != null) {
      stream = firestoreService.gradesForTeacher(event.teacherId!);
    } else {
      stream = firestoreService.allGrades();
    }

    await emit.forEach<List<GradeModel>>(
      stream,
      onData: (grades) => GradesLoaded(grades: grades, filtered: grades),
      onError: (_, __) =>
          const GradesError('Failed to load grades.'),
    );
  }

  Future<void> _onAdd(
      GradeAddRequested event, Emitter<GradesState> emit) async {
    try {
      await firestoreService.addGrade(event.grade);
      emit(const GradeOperationSuccess('Grade added successfully!'));
    } catch (e) {
      emit(GradesError(e.toString()));
    }
  }

  Future<void> _onUpdate(
      GradeUpdateRequested event, Emitter<GradesState> emit) async {
    try {
      await firestoreService.updateGrade(event.id, event.data);
      emit(const GradeOperationSuccess('Grade updated successfully!'));
    } catch (e) {
      emit(GradesError(e.toString()));
    }
  }

  Future<void> _onDelete(
      GradeDeleteRequested event, Emitter<GradesState> emit) async {
    try {
      await firestoreService.deleteGrade(event.id);
      emit(const GradeOperationSuccess('Grade deleted successfully!'));
    } catch (e) {
      emit(GradesError(e.toString()));
    }
  }

  void _onFilter(GradesFiltered event, Emitter<GradesState> emit) {
    final current = state;
    if (current is! GradesLoaded) return;

    var list = current.grades;
    if (event.subject != null && event.subject!.isNotEmpty) {
      list = list.where((g) => g.subject == event.subject).toList();
    }
    if (event.term != null && event.term!.isNotEmpty) {
      list = list.where((g) => g.term == event.term).toList();
    }
    if (event.gradeType != null && event.gradeType!.isNotEmpty) {
      list = list.where((g) => g.gradeType == event.gradeType).toList();
    }

    emit(GradesLoaded(
      grades: current.grades,
      filtered: list,
      activeSubject: event.subject,
      activeTerm: event.term,
      activeType: event.gradeType,
    ));
  }

  @override
  Future<void> close() {
    _gradesSub?.cancel();
    return super.close();
  }
}
