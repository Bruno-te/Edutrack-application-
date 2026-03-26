part of 'grades_bloc.dart';

abstract class GradesState extends Equatable {
  const GradesState();
  @override
  List<Object?> get props => [];
}

class GradesInitial extends GradesState {}

class GradesLoading extends GradesState {}

class GradesLoaded extends GradesState {
  final List<GradeModel> grades;
  final List<GradeModel> filtered;
  final String? activeSubject;
  final String? activeTerm;
  final String? activeType;

  const GradesLoaded({
    required this.grades,
    required this.filtered,
    this.activeSubject,
    this.activeTerm,
    this.activeType,
  });

  double get average {
    if (filtered.isEmpty) return 0;
    final sum = filtered.fold<double>(
        0, (prev, g) => prev + g.percentage);
    return sum / filtered.length;
  }

  @override
  List<Object?> get props =>
      [grades, filtered, activeSubject, activeTerm, activeType];
}

class GradesError extends GradesState {
  final String message;
  const GradesError(this.message);
  @override
  List<Object?> get props => [message];
}

class GradeOperationSuccess extends GradesState {
  final String message;
  const GradeOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
