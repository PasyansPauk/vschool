import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/subject_summary.dart';
import '../../view_models/diary_view_model.dart';
import '../../widgets/grade_badge.dart';

class AndroidGradesScreen extends StatelessWidget {
  final DiaryViewModel viewModel;
  final bool isDark;

  const AndroidGradesScreen({
    super.key,
    required this.viewModel,
    required this.isDark,
  });

  void _showSubjectDetails(BuildContext context, SubjectSummary subject) {
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E20) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subject.subject,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subject.teacher.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subject.teacher,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurfaceSecondary
                          : AppTheme.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Ср: ${subject.formattedAverage}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                    color: textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'История оценок за четверть:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              if (subject.grades.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: subject.grades.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final g = subject.grades[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0x18FFFFFF)
                              : const Color(0x0C000000),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0x1AFFFFFF)
                                : const Color(0x0E000000),
                            width: 0.6,
                          ),
                        ),
                        child: Row(
                          children: [
                            GradeBadge.fromGradeItem(
                              g,
                              size: 32,
                              fontSize: 16,
                              borderRadius: 10,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    g.topic.isNotEmpty
                                        ? g.topic
                                        : 'Ответ на уроке',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${g.formattedDate}${g.comment != null && g.comment!.isNotEmpty ? ' • ${g.comment}' : ''}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Нет текущих оценок',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, SubjectSummary subject) {
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Card(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0x12FFFFFF) : const Color(0x0E000000),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          _showSubjectDetails(context, subject);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subject.subject,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    subject.formattedAverage,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getGradeColor(
                          subject.averageScore.round()),
                    ),
                  ),
                ],
              ),
              if (subject.teacher.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subject.teacher,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
              const SizedBox(height: 12),

              if (subject.grades.isNotEmpty)
                GradeBadgeRow(
                  grades: subject.grades,
                  size: 30,
                  fontSize: 15,
                  borderRadius: 9,
                  isDark: isDark,
                )
              else
                Text(
                  'Нет текущих оценок',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overall = viewModel.overallAverageScore;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: RefreshIndicator(
        color: const Color(0xFF38BDF8),
        onRefresh: () async {
          await viewModel.loadData(forceRefresh: true);
        },
        child: CustomScrollView(
          slivers: [
            // Overall Average Hero Card
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0x12FFFFFF)
                        : const Color(0x0E000000),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Общий средний балл',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  overall > 0 ? overall.toStringAsFixed(2) : '—',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '/ 5.00',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: overall >= 4.5
                                ? AppTheme.grade5Color.withValues(alpha: 0.15)
                                : AppTheme.grade4Color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: overall >= 4.5
                                  ? AppTheme.grade5Color
                                  : AppTheme.grade4Color,
                            ),
                          ),
                          child: Text(
                            overall >= 4.7
                                ? 'Отличник'
                                : (overall >= 4.0 ? 'Хорошист' : 'В процессе'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: overall >= 4.5
                                  ? AppTheme.grade5Color
                                  : AppTheme.grade4Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Текущий период обучения: 2 полугодие (4 четверть)',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Text(
                  'Предметы и текущие оценки',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ),

            // Subject List
            if (viewModel.grades.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final subject = viewModel.grades[index];
                    return _buildSubjectCard(context, subject);
                  },
                  childCount: viewModel.grades.length,
                ),
              )
            else
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Оценки не загружены',
                    style: TextStyle(color: textSecondary),
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}
