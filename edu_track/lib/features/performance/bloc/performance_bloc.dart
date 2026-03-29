import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/attendance_model.dart';
import '../../../core/models/grade_model.dart';
import '../../../core/services/firestore_service.dart';

part 'performance_event.dart';
part 'performance_state.dart';

class PerformanceBloc extends Bloc<PerformanceEvent, PerformanceState> {
  final FirestoreService firestoreService;

  PerformanceBloc({required this.firestoreService})
      : super(PerformanceInitial()) {
    on<PerformanceLoadRequested>(_onLoad, transformer: restartable());
  }

  Future<void> _onLoad(
      PerformanceLoadRequested event,
      Emitter<PerformanceState> emit) async {
    emit(PerformanceLoading());
    try {
      final sid = event.studentId?.trim();
      if (sid != null && sid.isNotEmpty) {
        await emit.forEach(
          firestoreService.watchPerformanceForStudent(sid),
          onData: (data) => PerformanceLoaded(
            grades: data.grades,
            attendance: data.attendance,
          ),
          onError: (e, _) => PerformanceError(e.toString()),
        );
        return;
      }

      if (event.loadGlobalAnalytics) {
        final grades = await firestoreService.getAllGrades();
        final attendance = await firestoreService.getAllAttendance();
        emit(PerformanceLoaded(
          grades: grades,
          attendance: attendance,
        ));
      } else {
        emit(const PerformanceLoaded(grades: [], attendance: []));
      }
    } catch (e) {
      emit(PerformanceError(e.toString()));
    }
  }
}
