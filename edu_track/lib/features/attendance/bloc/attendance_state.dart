part of 'attendance_bloc.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();
  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final List<AttendanceModel> records;
  final List<AttendanceModel> filtered;
  final DateTime? selectedDate;

  const AttendanceLoaded({
    required this.records,
    required this.filtered,
    this.selectedDate,
  });

  int get presentCount =>
      filtered.where((a) => a.status == AttendanceStatus.present).length;
  int get absentCount =>
      filtered.where((a) => a.status == AttendanceStatus.absent).length;
  int get lateCount =>
      filtered.where((a) => a.status == AttendanceStatus.late).length;
  int get excusedCount =>
      filtered.where((a) => a.status == AttendanceStatus.excused).length;

  double get attendanceRate {
    if (records.isEmpty) return 0;
    final presentOrLate = records
        .where((a) =>
            a.status == AttendanceStatus.present ||
            a.status == AttendanceStatus.late)
        .length;
    return (presentOrLate / records.length) * 100;
  }

  @override
  List<Object?> get props => [records, filtered, selectedDate];
}

class AttendanceError extends AttendanceState {
  final String message;
  const AttendanceError(this.message);
  @override
  List<Object?> get props => [message];
}

class AttendanceOperationSuccess extends AttendanceState {
  final String message;
  const AttendanceOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
