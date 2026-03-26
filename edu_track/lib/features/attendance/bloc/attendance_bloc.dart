import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/attendance_model.dart';
import '../../../core/services/firestore_service.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final FirestoreService firestoreService;

  AttendanceBloc({required this.firestoreService})
      : super(AttendanceInitial()) {
    on<AttendanceLoadRequested>(_onLoad);
    on<AttendanceMarkRequested>(_onMark);
    on<AttendanceUpdateRequested>(_onUpdate);
    on<AttendanceDeleteRequested>(_onDelete);
    on<AttendanceDateFilterChanged>(_onDateFilter);
  }

  Future<void> _onLoad(
      AttendanceLoadRequested event,
      Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());

    Stream<List<AttendanceModel>> stream;
    if (event.studentId != null) {
      stream = firestoreService.attendanceForStudent(event.studentId!);
    } else if (event.teacherId != null) {
      stream = firestoreService.attendanceByTeacher(event.teacherId!);
    } else {
      stream = firestoreService.allAttendance();
    }

    await emit.forEach<List<AttendanceModel>>(
      stream,
      onData: (records) =>
          AttendanceLoaded(records: records, filtered: records),
      onError: (_, __) =>
          const AttendanceError('Failed to load attendance.'),
    );
  }

  Future<void> _onMark(
      AttendanceMarkRequested event,
      Emitter<AttendanceState> emit) async {
    try {
      await firestoreService.markAttendance(event.record);
      emit(const AttendanceOperationSuccess('Attendance marked!'));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _onUpdate(
      AttendanceUpdateRequested event,
      Emitter<AttendanceState> emit) async {
    try {
      await firestoreService.updateAttendance(event.id, event.data);
      emit(const AttendanceOperationSuccess('Attendance updated!'));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _onDelete(
      AttendanceDeleteRequested event,
      Emitter<AttendanceState> emit) async {
    try {
      await firestoreService.deleteAttendance(event.id);
      emit(const AttendanceOperationSuccess('Record deleted!'));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  void _onDateFilter(
      AttendanceDateFilterChanged event,
      Emitter<AttendanceState> emit) {
    final current = state;
    if (current is! AttendanceLoaded) return;

    var list = current.records;
    if (event.date != null) {
      list = list.where((a) {
        final d = a.date;
        final f = event.date!;
        return d.year == f.year && d.month == f.month && d.day == f.day;
      }).toList();
    }

    emit(AttendanceLoaded(
        records: current.records,
        filtered: list,
        selectedDate: event.date));
  }
}
