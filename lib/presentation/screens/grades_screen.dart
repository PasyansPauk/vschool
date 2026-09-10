import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/subject_summary.dart';
import '../view_models/diary_view_model.dart';
import '../widgets/grade_badge.dart';
import '../widgets/promotion_bouncing_card.dart';
import '../widgets/promotion_morph_route.dart';

class GradesScreen extends StatelessWidget {
  final DiaryViewModel viewModel;
  final bool isDark;

  const GradesScreen({
    super.key,
    required this.viewModel,
    required this.isDark,
  });

  void _showSubjectDetails(BuildContext context, SubjectSummary subject, [Rect? sourceRect]) {
    final rect = sourceRect ?? () {
      final rb = context.findRenderObject() as RenderBox?;
      if (rb != null && rb.hasSize) {
        final origin = rb.localToGlobal(Offset.zero);
        return Rect.fromLTWH(origin.dx, origin.dy, rb.size.width, rb.size.height);
      }
      final size = MediaQuery.of(context).size;
      return Rect.fromLTWH(16, size.height / 2 - 80, size.width - 32, 160);
    }();

    showProMotionCardModal(
      context: context,
      sourceRect: rect,
      sourceRadius: 20.0,
      targetRadius: 26.0,
      isDark: isDark,
      collapsedChild: _buildSubjectCard(context, subject),
      builder: (ctx, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subject Title & Average & Circular Close Button
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
                          letterSpacing: -0.3,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subject.teacher.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subject.teacher,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
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
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sleek iOS Circular Close Button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x28FFFFFF) : const Color(0x14000000),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 13,
                      color: isDark ? const Color(0xCCFFFFFF) : const Color(0x88000000),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const Text(
              'История оценок за четверть:',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 6),

            if (subject.grades.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: subject.grades.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final g = subject.grades[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  g.topic,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${g.formattedDate}${g.comment != null && g.comment!.isNotEmpty ? ' • ${g.comment}' : ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: CupertinoColors.systemGrey,
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Нет оценок',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, SubjectSummary subject) {
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
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
              final cardContent = ProMotionBouncingCard(
                onTap: (ctx, sourceRect) => _showSubjectDetails(ctx, subject, sourceRect),
                child: _buildSubjectCard(context, subject),
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
          child: SizedBox(height: 120),
        ),
      ],
    );
  }
}
