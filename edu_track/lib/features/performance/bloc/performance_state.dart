part of 'performance_bloc.dart';

abstract class PerformanceState extends Equatable {
  const PerformanceState();
  @override
  List<Object?> get props => [];
}

class PerformanceInitial extends PerformanceState {}

class PerformanceLoading extends PerformanceState {}

class PerformanceLoaded extends PerformanceState {
  final List<GradeModel> grades;
  final List<AttendanceModel> attendance;

  const PerformanceLoaded({
    required this.grades,
    required this.attendance,
  });

  // Subject → average percentage
  Map<String, double> get subjectAverages {
    final Map<String, List<double>> map = {};
    for (final g in grades) {
      map.putIfAbsent(g.subject, () => []).add(g.percentage);
    }
    return map.map((k, v) =>
        MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  // Term → average percentage
  Map<String, double> get termAverages {
    final Map<String, List<double>> map = {};
    for (final g in grades) {
      map.putIfAbsent(g.term, () => []).add(g.percentage);
    }
    final result = map.map((k, v) =>
        MapEntry(k, v.reduce((a, b) => a + b) / v.length));
    final sorted = Map.fromEntries(
        result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return sorted;
  }

  double get overallAverage {
    if (grades.isEmpty) return 0;
    return grades.fold<double>(0, (p, g) => p + g.percentage) /
        grades.length;
  }

  double get attendanceRate {
    if (attendance.isEmpty) return 0;
    final good = attendance
        .where((a) =>
            a.status == AttendanceStatus.present ||
            a.status == AttendanceStatus.late)
        .length;
    return (good / attendance.length) * 100;
  }

  @override
  List<Object?> get props => [grades, attendance];
}

class PerformanceError extends PerformanceState {
  final String message;
  const PerformanceError(this.message);
  @override
  List<Object?> get props => [message];
}
