import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/lesson.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isDark;
  final bool isCurrent;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.isDark,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? (isCurrent ? AppTheme.darkSurfaceElevated : AppTheme.darkSurface)
        : (isCurrent ? CupertinoColors.white : AppTheme.lightSurface);

    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? (isDark ? CupertinoColors.white : CupertinoColors.black)
              : border,
          width: isCurrent ? 1.5 : 0.8,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.05)
                      : CupertinoColors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Lesson Number & Time
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurfaceSecondary
                  : AppTheme.lightSurfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${lesson.number} урок',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.startTime,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  lesson.endTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Main Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject & Room Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lesson.subject,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Room Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurfaceSecondary
                            : AppTheme.lightSurfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lesson.room,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Teacher
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.person,
                      size: 13,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lesson.teacher,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Lesson Topic
                if (lesson.topic.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    lesson.topic,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF3F3F46),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Footer: Grade and Homework Badges
                if (lesson.grade != null || lesson.homework != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (lesson.grade != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.getGradeColor(lesson.grade!.value)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.getGradeColor(lesson.grade!.value)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${lesson.grade!.value}${lesson.grade!.weightSuperscript}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getGradeColor(
                                      lesson.grade!.value),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Оценка',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.getGradeColor(
                                      lesson.grade!.value),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (lesson.homework != null) ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1E24)
                                  : const Color(0xFFF0F0F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.book,
                                  size: 12,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    lesson.homework!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
