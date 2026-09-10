import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../view_models/diary_view_model.dart';
import '../../view_models/school_tracker_view_model.dart';

class AndroidTrackerScreen extends StatelessWidget {
  final DiaryViewModel diaryViewModel;
  final SchoolTrackerViewModel trackerViewModel;
  final bool isDark;

  const AndroidTrackerScreen({
    super.key,
    required this.diaryViewModel,
    required this.trackerViewModel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = diaryViewModel.todaySchedule;
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

    return RefreshIndicator(
      onRefresh: () async {
        await diaryViewModel.loadData(forceRefresh: true);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Школьный день',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
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
                          schedule?.dayName ?? 'Сегодня',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Circular Progress Card
                  Card(
                    color: cardBg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                                  painter: _AndroidCircularProgressPainter(
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

                          // Metric tiles
                          Row(
                            children: [
                              Expanded(
                                child: _AndroidMetricTile(
                                  title: 'Прошло времени',
                                  value: trackerViewModel.formatDuration(timeSpent),
                                  icon: Icons.arrow_upward_rounded,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _AndroidMetricTile(
                                  title: 'Осталось учиться',
                                  value:
                                      trackerViewModel.formatDuration(timeRemaining),
                                  icon: Icons.arrow_downward_rounded,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Live Focus Card (Current lesson / Break status)
                  Card(
                    color: cardBg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: currentLesson != null
                                          ? AppTheme.grade5Color
                                          : (isBreak
                                              ? AppTheme.grade3Color
                                              : Colors.grey),
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
                              [
                                if (currentLesson.room.isNotEmpty) 'Каб. ${currentLesson.room}',
                                if (currentLesson.teacher.isNotEmpty) 'Учитель: ${currentLesson.teacher}',
                              ].join(' • '),
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
                              'Перемена между уроками ☕️',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (nextLesson != null)
                              Text(
                                'Следующий: ${nextLesson.number}. ${nextLesson.subject}${nextLesson.room.isNotEmpty ? " (${nextLesson.room})" : ""}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                          ] else if (progress >= 1.0 && schedule != null && schedule.lessons.isNotEmpty) ...[
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
                              'Все уроки пройдены. Пора домой отдыхать!',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ] else if (schedule == null || schedule.lessons.isEmpty) ...[
                            Text(
                              (schedule != null && schedule.isWeekend)
                                  ? 'Сегодня выходной 🏖️'
                                  : 'На сегодня уроков нет 🎉',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (schedule != null && schedule.isWeekend)
                                  ? 'Отдыхай и восстанавливай силы ✨'
                                  : 'Свободный день или каникулы!',
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
                              'Первый урок начнется в ${schedule.startTime}',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AndroidMetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isDark;

  const _AndroidMetricTile({
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
                size: 16,
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

class _AndroidCircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _AndroidCircularProgressPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = isDark ? Colors.white : Colors.black
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
  bool shouldRepaint(covariant _AndroidCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
