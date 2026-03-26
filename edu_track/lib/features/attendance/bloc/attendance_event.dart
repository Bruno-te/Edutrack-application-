part of 'attendance_bloc.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();
  @override
  List<Object?> get props => [];
}

class AttendanceLoadRequested extends AttendanceEvent {
  final String? studentId;
  final String? teacherId;
  const AttendanceLoadRequested({this.studentId, this.teacherId});
  @override
  List<Object?> get props => [studentId, teacherId];
}

class AttendanceMarkRequested extends AttendanceEvent {
  final AttendanceModel record;
  const AttendanceMarkRequested(this.record);
  @override
  List<Object?> get props => [record];
}

class AttendanceUpdateRequested extends AttendanceEvent {
  final String id;
  final Map<String, dynamic> data;
  const AttendanceUpdateRequested(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class AttendanceDeleteRequested extends AttendanceEvent {
  final String id;
  const AttendanceDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class AttendanceDateFilterChanged extends AttendanceEvent {
  final DateTime? date;
  const AttendanceDateFilterChanged(this.date);
  @override
  List<Object?> get props => [date];
}
