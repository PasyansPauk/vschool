import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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

  static String getSubjectEmoji(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('алгебр') || s.contains('матем') || s.contains('геометр')) return '📐';
    if (s.contains('русск') || s.contains('родной яз')) return '📖';
    if (s.contains('литератур') || s.contains('чтени')) return '📚';
    if (s.contains('физик')) return '⚡️';
    if (s.contains('хими')) return '🧪';
    if (s.contains('биолог') || s.contains('естествозн')) return '🧬';
    if (s.contains('истори')) return '🏛️';
    if (s.contains('общество') || s.contains('право')) return '⚖️';
    if (s.contains('географ')) return '🌍';
    if (s.contains('информат') || s.contains('программир') || s.contains('ит') || s.contains('it')) return '💻';
    if (s.contains('англ') || s.contains('иностр') || s.contains('немец') || s.contains('франц')) return '🇬🇧';
    if (s.contains('физ-ра') || s.contains('физкультур') || s.contains('спорт')) return '🏃‍♂️';
    if (s.contains('обж') || s.contains('бжд') || s.contains('обзр')) return '🛡️';
    if (s.contains('музык')) return '🎵';
    if (s.contains('изо') || s.contains('рисовани') || s.contains('черчени') || s.contains('искусств')) return '🎨';
    if (s.contains('технолог') || s.contains('труд')) return '🛠️';
    if (s.contains('астроном')) return '🔭';
    if (s.contains('эколог')) return '🌱';
    if (s.contains('эконом')) return '📈';
    return '📝';
  }

  void _showLessonDetails(BuildContext context) {
    HapticFeedback.lightImpact();
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final tileBg =
        isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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

                // Header: Subject & Lesson Number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lesson.subject,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: tileBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${lesson.number} урок • ${lesson.startTime} – ${lesson.endTime}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Room & Teacher tile
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lesson.room.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF27272A)
                                    : const Color(0xFFE4E4E7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Кабинет ${lesson.room}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (lesson.teacher.isNotEmpty) const SizedBox(height: 8),
                      ],
                      if (lesson.teacher.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.person_crop_circle,
                              size: 16,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lesson.teacher,
                                style: TextStyle(
                                  fontSize: 14,
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
                const SizedBox(height: 12),

                // Topic
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Тема урока',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lesson.topic.isNotEmpty
                            ? lesson.topic
                            : 'Тема не заполнена в электронном журнале',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Homework
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.book,
                            size: 14,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Домашнее задание',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lesson.homework != null && lesson.homework!.isNotEmpty
                            ? lesson.homework!
                            : 'Домашнее задание не задано',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Grade / Attendance
                if (lesson.grade != null || lesson.attendance != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tileBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (lesson.grade != null)
                          Row(
                            children: [
                              Text(
                                'Оценка за урок: ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                              Text(
                                '${lesson.grade!.value}${lesson.grade!.weightSuperscript}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getGradeColor(
                                      lesson.grade!.value),
                                ),
                              ),
                            ],
                          ),
                        if (lesson.attendance != null && lesson.attendance!.isNotEmpty)
                          Text(
                            'Посещаемость: ${lesson.attendance}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: lesson.attendance == 'Н'
                                  ? AppTheme.grade2Color
                                  : AppTheme.grade4Color,
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Закрыть',
                      style: TextStyle(
                        color: isDark
                            ? CupertinoColors.black
                            : CupertinoColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final bg = isDark
        ? (isCurrent ? AppTheme.darkSurfaceElevated : AppTheme.darkSurface)
        : (isCurrent ? CupertinoColors.white : AppTheme.lightSurface);

    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: const EdgeInsets.all(18), // Distinctly larger padding than break card
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCurrent
              ? (isDark ? CupertinoColors.white : CupertinoColors.black)
              : border,
          width: isCurrent ? 1.6 : 0.8,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.06)
                      : CupertinoColors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Pill: Subject Emoji (Prominent lesson pill)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A) : CupertinoColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent
                    ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                    : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7)),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              getSubjectEmoji(lesson.subject),
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 14),

          // Main Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title on Left, Time Badge on Right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${lesson.number}. ${lesson.subject}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Time Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? (isCurrent
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF27272A))
                            : (isCurrent
                                ? CupertinoColors.white
                                : const Color(0xFFE4E4E7)),
                        borderRadius: BorderRadius.circular(10),
                        border: isCurrent
                            ? Border.all(
                                color: CupertinoColors.activeGreen
                                    .withValues(alpha: 0.6),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Text(
                        '${lesson.startTime} – ${lesson.endTime}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? CupertinoColors.activeGreen
                              : textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Room & Full Teacher FIO (Full FIO is never truncated!)
                if (lesson.room.isNotEmpty || lesson.teacher.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (lesson.room.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFE4E4E7),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            'каб. ${lesson.room}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      if (lesson.teacher.isNotEmpty)
                        Text(
                          lesson.teacher,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],

                if (isCurrent) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeGreen
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'ИДЁТ СЕЙЧАС',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: CupertinoColors.activeGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],

                if (lesson.topic.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    lesson.topic,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (lesson.grade != null || lesson.homework != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (lesson.grade != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppTheme.getGradeColor(
                                    lesson.grade!.value)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${lesson.grade!.value}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getGradeColor(
                                      lesson.grade!.value),
                                ),
                              ),
                              if (lesson.grade!.weightSuperscript.isNotEmpty)
                                Text(
                                  lesson.grade!.weightSuperscript,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.getGradeColor(
                                        lesson.grade!.value),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (lesson.homework != null &&
                          lesson.homework!.isNotEmpty)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF27272A)
                                  : const Color(0xFFE4E4E7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.book_fill,
                                  size: 11,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
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
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showLessonDetails(context),
      child: _buildCardContent(context),
    );

    // Cupertino Context Menu Preview on Long Press (iOS 3D Touch style)
    return CupertinoContextMenu(
      actions: [
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.info_circle,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
            _showLessonDetails(context);
          },
          child: const Text('Подробнее об уроке'),
        ),
      ],
      child: cardWidget,
    );
  }
}
