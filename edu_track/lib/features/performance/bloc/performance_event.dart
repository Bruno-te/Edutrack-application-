part of 'performance_bloc.dart';

abstract class PerformanceEvent extends Equatable {
  const PerformanceEvent();
  @override
  List<Object?> get props => [];
}

class PerformanceLoadRequested extends PerformanceEvent {
  final String? studentId;
  const PerformanceLoadRequested({this.studentId});
  @override
  List<Object?> get props => [studentId];
}
