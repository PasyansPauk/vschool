import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/lesson.dart';
import '../../widgets/grade_badge.dart';

/// Dedicated Material 3 Lesson Card for Android with native touch ripple,
/// high-density information hierarchy, and M3 Modal Bottom Sheet.
class AndroidLessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isDark;
  final bool isCurrent;

  const AndroidLessonCard({
    super.key,
    required this.lesson,
    required this.isDark,
    this.isCurrent = false,
  });

  static IconData getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('математ') || s.contains('алгебр') || s.contains('геометр')) {
      return Icons.calculate_outlined;
    }
    if (s.contains('русск') || s.contains('литератур') || s.contains('чтени')) {
      return Icons.menu_book_outlined;
    }
    if (s.contains('физик')) return Icons.lightbulb_outlined;
    if (s.contains('информат') ||
        s.contains('программир') ||
        s.contains('ит') ||
        s.contains('it')) {
      return Icons.laptop_chromebook_outlined;
    }
    if (s.contains('истор') || s.contains('обществ') || s.contains('право')) {
      return Icons.account_balance_outlined;
    }
    if (s.contains('англ') ||
        s.contains('иностр') ||
        s.contains('немец') ||
        s.contains('франц')) {
      return Icons.translate_outlined;
    }
    if (s.contains('биолог') || s.contains('естествозн') || s.contains('эколог')) {
      return Icons.eco_outlined;
    }
    if (s.contains('географ')) return Icons.public_outlined;
    if (s.contains('физ-ра') || s.contains('физкультур') || s.contains('спорт')) {
      return Icons.fitness_center_outlined;
    }
    if (s.contains('изо') ||
        s.contains('музык') ||
        s.contains('рисовани') ||
        s.contains('искусств')) {
      return Icons.palette_outlined;
    }
    if (s.contains('технолог') || s.contains('труд')) return Icons.handyman_outlined;
    if (s.contains('хими')) return Icons.science_outlined;
    if (s.contains('обж') || s.contains('бжд') || s.contains('обзр')) {
      return Icons.security_outlined;
    }
    if (s.contains('эконом')) return Icons.trending_up_outlined;
    if (s.contains('астроном')) return Icons.nights_stay_outlined;
    return Icons.school_outlined;
  }

  void _showLessonDetails(BuildContext context) {
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

              // Header: Subject Icon + Title + Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x18FFFFFF)
                          : const Color(0x0C000000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      getSubjectIcon(lesson.subject),
                      size: 24,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lesson.subject,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lesson.number} урок • ${lesson.startTime} – ${lesson.endTime}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                    color: textSecondary,
                  ),
                ],
              ),

              // Room & Teacher Tile
              if (lesson.room.isNotEmpty || lesson.teacher.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0E000000),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lesson.room.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFE5E5EA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Кабинет ${lesson.room}',
                                style: TextStyle(
                                  fontSize: 12,
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
                            Icon(Icons.person_outline, size: 18, color: textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lesson.teacher,
                                style: TextStyle(
                                  fontSize: 13.5,
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
              ],

              // Topic Tile
              if (lesson.topic.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0E000000),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description_outlined,
                              size: 14, color: textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'ТЕМА УРОКА',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lesson.topic,
                        style: TextStyle(fontSize: 13.5, color: textPrimary),
                      ),
                    ],
                  ),
                ),
              ],

              // Homework Tile
              if (lesson.homework != null && lesson.homework!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0E000000),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assignment_outlined,
                              size: 14, color: textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'ДОМАШНЕЕ ЗАДАНИЕ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lesson.homework!,
                        style: TextStyle(fontSize: 13.5, color: textPrimary),
                      ),
                    ],
                  ),
                ),
              ],

              // Hero Grade Card (if grade present) or Attendance Tile
              if (lesson.grade != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0x18FFFFFF)
                        : const Color(0x0C000000),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: GradeBadge.getBorderColor(lesson.grade!.value),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      GradeBadge(
                        value: lesson.grade!.value,
                        weight: lesson.grade!.weight,
                        size: 56,
                        fontSize: 28,
                        borderRadius: 14,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: GradeBadge.getBgColor(lesson.grade!.value),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ОЦЕНКА ЗА УРОК',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: GradeBadge.getTextColor(
                                          lesson.grade!.value),
                                    ),
                                  ),
                                ),
                                if (lesson.grade!.weight > 1) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0x28FFFFFF)
                                          : const Color(0x14000000),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Вес: ${lesson.grade!.weight}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lesson.grade!.topic.isNotEmpty
                                  ? lesson.grade!.topic
                                  : 'Ответ на уроке',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (lesson.grade!.comment != null &&
                                lesson.grade!.comment!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                lesson.grade!.comment!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (lesson.attendance != null &&
                  lesson.attendance!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0x18FFFFFF)
                        : const Color(0x0C000000),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x1AFFFFFF)
                          : const Color(0x0E000000),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Посещаемость:',
                          style: TextStyle(fontSize: 13, color: textSecondary)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (lesson.attendance == 'Н'
                                  ? AppTheme.grade2Color
                                  : AppTheme.grade4Color)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lesson.attendance!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: lesson.attendance == 'Н'
                                ? AppTheme.grade2Color
                                : AppTheme.grade4Color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Share Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _shareLesson(context),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text(
                  'Поделиться уроком',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareLesson(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('📚 ${lesson.number}. ${lesson.subject}');
    buffer.writeln('⏱️ ${lesson.startTime} – ${lesson.endTime}');
    if (lesson.room.isNotEmpty) buffer.writeln('🚪 Кабинет: ${lesson.room}');
    if (lesson.teacher.isNotEmpty) buffer.writeln('👨‍🏫 Учитель: ${lesson.teacher}');
    if (lesson.topic.isNotEmpty) buffer.writeln('📖 Тема: ${lesson.topic}');
    if (lesson.homework != null && lesson.homework!.isNotEmpty) {
      buffer.writeln('📝 Д/з: ${lesson.homework}');
    }
    if (lesson.grade != null) {
      buffer.writeln(
          '⭐️ Оценка: ${lesson.grade!.value}${lesson.grade!.weightSuperscript}');
    }
    Share.share(
      buffer.toString().trim(),
      subject: '${lesson.subject} (${lesson.startTime} – ${lesson.endTime})',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? const Color(0xFF1C1C1E)
        : (isCurrent ? Colors.white : AppTheme.lightSurface);

    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final border = isCurrent
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? const Color(0x12FFFFFF) : const Color(0x0E000000));

    return Card(
      color: bg,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: border,
          width: isCurrent ? 1.4 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          _showLessonDetails(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Subject Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x18FFFFFF)
                      : const Color(0x0C000000),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0x1AFFFFFF)
                        : const Color(0x0E000000),
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  getSubjectIcon(lesson.subject),
                  size: 22,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 12),

              // Center Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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

                    if (lesson.room.isNotEmpty || lesson.teacher.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (lesson.room.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6.5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFE5E5EA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'каб. ${lesson.room}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            if (lesson.teacher.isNotEmpty)
                              const SizedBox(width: 8),
                          ],
                          if (lesson.teacher.isNotEmpty)
                            Expanded(
                              child: Text(
                                lesson.teacher,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],

                    if (isCurrent) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ИДЁТ СЕЙЧАС',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.green,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],

                    if (lesson.topic.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        lesson.topic,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    if (lesson.homework != null &&
                        lesson.homework!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0x18FFFFFF)
                              : const Color(0x0C000000),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 12, color: textSecondary),
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
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Right: Time Badge + GradeBadge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? (isCurrent
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF27272A))
                          : (isCurrent
                              ? Colors.white
                              : const Color(0xFFE4E4E7)),
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrent
                          ? Border.all(
                              color: Colors.green.withValues(alpha: 0.6),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Text(
                      '${lesson.startTime} – ${lesson.endTime}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCurrent ? Colors.green : textSecondary,
                      ),
                    ),
                  ),
                  if (lesson.grade != null) ...[
                    const SizedBox(height: 8),
                    GradeBadge.fromGradeItem(
                      lesson.grade!,
                      size: 32,
                      fontSize: 16,
                      borderRadius: 10,
                      isDark: isDark,
                    ),
                  ] else if (lesson.attendance != null &&
                      lesson.attendance!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: (lesson.attendance == 'Н'
                                ? AppTheme.grade2Color
                                : AppTheme.grade4Color)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lesson.attendance!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: lesson.attendance == 'Н'
                              ? AppTheme.grade2Color
                              : AppTheme.grade4Color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
