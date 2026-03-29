part of 'performance_bloc.dart';

abstract class PerformanceEvent extends Equatable {
  const PerformanceEvent();
  @override
  List<Object?> get props => [];
}

class PerformanceLoadRequested extends PerformanceEvent {
  final String? studentId;
  /// When true and [studentId] is empty, load all grades/attendance (admin/teacher analytics).
  final bool loadGlobalAnalytics;
  const PerformanceLoadRequested({
    this.studentId,
    this.loadGlobalAnalytics = false,
  });
  @override
  List<Object?> get props => [studentId, loadGlobalAnalytics];
}
