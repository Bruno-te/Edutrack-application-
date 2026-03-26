import 'package:bloc/bloc.dart';
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
    on<PerformanceLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
      PerformanceLoadRequested event,
      Emitter<PerformanceState> emit) async {
    emit(PerformanceLoading());
    try {
      List<GradeModel> grades;
      List<AttendanceModel> attendance;

      if (event.studentId != null) {
        grades = await firestoreService
            .getGradesForStudent(event.studentId!);
        attendance = await firestoreService
            .getAttendanceForStudent(event.studentId!);
      } else {
        // For teacher/admin: load analytics data without composite indexes.
        grades = await firestoreService.getAllGrades();
        attendance = await firestoreService.getAllAttendance();
      }

      emit(PerformanceLoaded(
        grades: grades,
        attendance: attendance,
      ));
    } catch (e) {
      emit(PerformanceError(e.toString()));
    }
  }
}
