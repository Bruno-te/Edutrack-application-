import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../bloc/performance_bloc.dart';

class PerformanceScreen extends StatelessWidget {
  final String? studentId;
  /// Admin / teacher tabs: load school-wide analytics when no [studentId].
  final bool loadGlobalAnalytics;

  const PerformanceScreen({
    super.key,
    this.studentId,
    this.loadGlobalAnalytics = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => PerformanceBloc(
        firestoreService: ctx.read<FirestoreService>(),
      )..add(PerformanceLoadRequested(
          studentId: studentId,
          loadGlobalAnalytics: loadGlobalAnalytics,
        )),
      child: const _PerformanceView(),
    );
  }
}

class _PerformanceView extends StatelessWidget {
  const _PerformanceView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Performance')),
      body: BlocBuilder<PerformanceBloc, PerformanceState>(
        builder: (ctx, state) {
          if (state is PerformanceLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PerformanceLoaded) {
            return _PerformanceBody(state: state);
          }
          if (state is PerformanceError) {
            return EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'Could not load performance',
              subtitle: state.message,
            );
          }
          return const EmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'No performance data',
            subtitle: 'Grades will be visualized here.',
          );
        },
      ),
    );
  }
}

class _PerformanceBody extends StatelessWidget {
  final PerformanceLoaded state;
  const _PerformanceBody({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.grades.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No grade data yet',
        subtitle:
            'Quick stats, averages by subject, and breakdown charts appear once grades are added.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              StatCard(
                label: 'Overall Average',
                value: '${state.overallAverage.toStringAsFixed(1)}%',
                icon: Icons.star_outline,
                color: AppColors.primary,
              ),
              StatCard(
                label: 'Attendance Rate',
                value: state.attendance.isEmpty
                    ? 'N/A'
                    : '${state.attendanceRate.toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
              StatCard(
                label: 'Subjects',
                value: '${state.subjectAverages.length}',
                icon: Icons.book_outlined,
                color: AppColors.warning,
              ),
              StatCard(
                label: 'Total Records',
                value: '${state.grades.length}',
                icon: Icons.layers_outlined,
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (state.subjectAverages.isNotEmpty) ...[
            const SectionHeader(title: 'Average by Subject'),
            const SizedBox(height: 12),
            _SubjectBarChart(data: state.subjectAverages),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Subject Breakdown'),
            const SizedBox(height: 12),
            _SubjectBreakdownList(
              entries: state.subjectAverages.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key)),
            ),
            const SizedBox(height: 24),
          ],

          if (state.termAverages.length >= 2) ...[
            const SectionHeader(title: 'Term Progression'),
            const SizedBox(height: 12),
            _TermLineChart(data: state.termAverages),
            const SizedBox(height: 24),
          ],

          const SectionHeader(title: 'Grade Distribution'),
          const SizedBox(height: 12),
          _GradePieChart(
            grades:
                state.grades.map((g) => g.letterGrade).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Subject breakdown (single card, like reference UI) ────────

class _SubjectBreakdownList extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  const _SubjectBreakdownList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: _SubjectRowInline(
                subject: entries[i].key,
                average: entries[i].value,
                barColorIndex: i,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectRowInline extends StatelessWidget {
  final String subject;
  final double average;
  final int barColorIndex;

  const _SubjectRowInline({
    required this.subject,
    required this.average,
    required this.barColorIndex,
  });

  static const _barColors = [
    AppColors.chartBlue,
    AppColors.chartGreen,
    AppColors.chartOrange,
    AppColors.chartPurple,
    AppColors.secondary,
    AppColors.chartRed,
  ];

  Color get _barColor => _barColors[barColorIndex % _barColors.length];

  Color get _badgeColor {
    if (average >= 80) return AppColors.success;
    if (average >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String get _gradeLetter {
    if (average >= 90) return 'A+';
    if (average >= 80) return 'A';
    if (average >= 70) return 'B';
    if (average >= 60) return 'C';
    if (average >= 50) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GradeChip(grade: _gradeLetter),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: average / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(_barColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${average.toStringAsFixed(0)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _badgeColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ── Subject Bar Chart ─────────────────────────────────────────

String _shortSubjectAxisLabel(String subject) {
  const aliases = {
    'Mathematics': 'Math',
    'English': 'Eng',
    'Science': 'Sci',
    'History': 'Hist',
    'Art': 'Art',
  };
  if (aliases.containsKey(subject)) return aliases[subject]!;
  if (subject.length <= 4) return subject;
  return subject.substring(0, 4);
}

class _SubjectBarChart extends StatelessWidget {
  final Map<String, double> data;
  const _SubjectBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final colors = [
      AppColors.chartBlue,
      AppColors.chartGreen,
      AppColors.chartOrange,
      AppColors.chartPurple,
      AppColors.secondary,
      AppColors.chartRed,
    ];

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${entries[group.x].key}\n${rod.toY.toStringAsFixed(1)}%',
                const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= entries.length) return const SizedBox();
                  final label = _shortSubjectAxisLabel(entries[idx].key);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((entry) {
            final color = colors[entry.key % colors.length];
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: color,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: AppColors.border.withOpacity(0.4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Term Line Chart ───────────────────────────────────────────

class _TermLineChart extends StatelessWidget {
  final Map<String, double> data;
  const _TermLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${entries[s.x.toInt()].key}\n${s.y.toStringAsFixed(1)}%',
                        const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ))
                  .toList(),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= entries.length) return const SizedBox();
                  return Text(entries[idx].key,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary));
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: entries
                  .asMap()
                  .entries
                  .map((e) =>
                      FlSpot(e.key.toDouble(), e.value.value))
                  .toList(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(
                getDotPainter: (_, __, ___, ____) =>
                    FlDotCirclePainter(
                  radius: 5,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grade Pie Chart ───────────────────────────────────────────

class _GradePieChart extends StatelessWidget {
  final List<String> grades;
  const _GradePieChart({required this.grades});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> counts = {};
    for (final g in grades) {
      counts[g] = (counts[g] ?? 0) + 1;
    }

    final colorMap = {
      'A+': AppColors.success,
      'A': const Color(0xFF43A047),
      'B': AppColors.info,
      'C': AppColors.warning,
      'D': Colors.orange,
      'F': AppColors.error,
    };

    final sections = counts.entries.map((e) {
      final pct = (e.value / grades.length) * 100;
      return PieChartSectionData(
        value: pct,
        color: colorMap[e.key] ?? Colors.grey,
        title: '${e.key}\n${pct.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11),
        radius: 80,
      );
    }).toList();

    return Container(
      height: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            )),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: counts.entries.map((e) {
              final color = colorMap[e.key] ?? Colors.grey;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${e.key}: ${e.value}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

