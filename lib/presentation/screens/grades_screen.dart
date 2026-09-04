import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/subject_summary.dart';
import '../view_models/diary_view_model.dart';

class GradesScreen extends StatelessWidget {
  final DiaryViewModel viewModel;
  final bool isDark;

  const GradesScreen({
    super.key,
    required this.viewModel,
    required this.isDark,
  });

  void _showSubjectDetails(BuildContext context, SubjectSummary subject) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3F3F46)
                        : const Color(0xFFD4D4D8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subject.subject,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurfaceSecondary
                          : AppTheme.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ср: ${subject.formattedAverage}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subject.teacher,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'История оценок за четверть:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: subject.grades.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final g = subject.grades[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurfaceSecondary
                            : AppTheme.lightSurfaceSecondary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.getGradeColor(g.value)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.getGradeColor(g.value),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${g.value}${g.weightSuperscript}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getGradeColor(g.value),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.topic,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Вес работы: ${g.weight}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.lightTextSecondary,
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
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Закрыть',
                    style: TextStyle(
                      color: isDark
                          ? CupertinoColors.black
                          : CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await viewModel.loadData(forceRefresh: true);
          },
        ),

        // Overall Average Grade Hero Card
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
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
                            : (overall >= 4.0 ? 'Хорошист' : 'Успеваемость'),
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
                const SizedBox(height: 16),
                // Visual Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 8,
                    color: isDark
                        ? AppTheme.darkSurfaceSecondary
                        : AppTheme.lightSurfaceSecondary,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (overall / 5.0).clamp(0.0, 1.0),
                      child: Container(
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Формула МЭШ: среднее взвешенное с учетом веса (коэффициента) каждой работы.',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Section Title
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
              final cardContent = Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showSubjectDetails(context, subject);
                  },
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
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Horizontal Grade Badges with Weights
                      if (subject.grades.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: subject.grades.map((g) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.getGradeColor(g.value)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.getGradeColor(g.value)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '${g.value}${g.weightSuperscript}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getGradeColor(g.value),
                                ),
                              ),
                            );
                          }).toList(),
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
              );

              return CupertinoContextMenu(
                actions: [
                  CupertinoContextMenuAction(
                    trailingIcon: CupertinoIcons.chart_bar,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                      _showSubjectDetails(context, subject);
                    },
                    child: const Text('Подробные оценки'),
                  ),
                ],
                child: cardContent,
              );
            },
            childCount: viewModel.grades.length,
          ),
        )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Оценок в электронном дневнике пока нет',
                  style: TextStyle(color: textSecondary, fontSize: 15),
                ),
              ),
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }
}
