import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';
import '../view_models/diary_view_model.dart';
import '../view_models/school_tracker_view_model.dart';

class TrackerScreen extends StatelessWidget {
  final DiaryViewModel diaryViewModel;
  final SchoolTrackerViewModel trackerViewModel;
  final bool isDark;

  const TrackerScreen({
    super.key,
    required this.diaryViewModel,
    required this.trackerViewModel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = diaryViewModel.currentDaySchedule;
    final timeSpent = trackerViewModel.getTimeSpent(schedule);
    final timeRemaining = trackerViewModel.getTimeRemaining(schedule);
    final progress = trackerViewModel.getDayProgress(schedule);
    final currentLesson = trackerViewModel.getCurrentLesson(schedule);
    final nextLesson = trackerViewModel.getNextLesson(schedule);
    final isBreak = trackerViewModel.isDuringBreak(schedule);
    final bellCountdown = trackerViewModel.getNextBellCountdown(schedule);

    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top control for testing simulation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Школьный день',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      color: trackerViewModel.isDemoTimeActive
                          ? (isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black)
                          : (isDark
                              ? AppTheme.darkSurfaceSecondary
                              : AppTheme.lightSurfaceSecondary),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () => trackerViewModel.toggleDemoTime(schedule),
                      child: Text(
                        trackerViewModel.isDemoTimeActive
                            ? 'Режим: День ☀️'
                            : 'Тест: Симуляция',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: trackerViewModel.isDemoTimeActive
                              ? (isDark
                                  ? CupertinoColors.black
                                  : CupertinoColors.white)
                              : textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Aesthetic Circular Progress Ring
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 210,
                        height: 210,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(210, 210),
                              painter: _CircularProgressPainter(
                                progress: progress,
                                isDark: isDark,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'В ШКОЛЕ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  trackerViewModel.formatDigital(timeSpent),
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1.0,
                                    color: textPrimary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.darkSurfaceSecondary
                                        : AppTheme.lightSurfaceSecondary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${(progress * 100).toStringAsFixed(0)}% пройдено',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Two-Column Metrics: Passed & Left
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              title: 'Прошло времени',
                              value: trackerViewModel.formatDuration(timeSpent),
                              icon: CupertinoIcons.arrow_up_circle,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricTile(
                              title: 'Осталось учиться',
                              value:
                                  trackerViewModel.formatDuration(timeRemaining),
                              icon: CupertinoIcons.arrow_down_circle,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Live Focus Card (Current lesson / Break status)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: currentLesson != null
                                      ? AppTheme.grade5Color
                                      : (isBreak
                                          ? AppTheme.grade3Color
                                          : CupertinoColors.systemGrey),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currentLesson != null
                                    ? 'ИДЁТ УРОК'
                                    : (isBreak ? 'ПЕРЕМЕНА' : 'ТЕКУЩИЙ СТАТУС'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (bellCountdown > Duration.zero)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkSurfaceSecondary
                                    : AppTheme.lightSurfaceSecondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'До звонка: ${trackerViewModel.formatDigital(bellCountdown)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (currentLesson != null) ...[
                        Text(
                          '${currentLesson.number}. ${currentLesson.subject}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currentLesson.room} • Преподаватель: ${currentLesson.teacher}',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                        if (currentLesson.topic.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Тема: ${currentLesson.topic}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFFD4D4D8)
                                  : const Color(0xFF3F3F46),
                            ),
                          ),
                        ],
                      ] else if (isBreak) ...[
                        Text(
                          'Перемена между уроками',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (nextLesson != null)
                          Text(
                            'Следующий урок: ${nextLesson.number}. ${nextLesson.subject} (${nextLesson.room})',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                      ] else if (progress >= 1.0) ...[
                        Text(
                          'Учебный день завершён 🎉',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Все уроки пройдены. Отличный день для отдыха и ДЗ!',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Уроки ещё не начались',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Первый урок начнется в ${schedule?.startTime ?? "08:30"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isDark;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurfaceSecondary
            : AppTheme.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _CircularProgressPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 14.0;

    // Background track
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = isDark ? CupertinoColors.white : CupertinoColors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
