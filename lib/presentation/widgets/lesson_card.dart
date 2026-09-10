import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/lesson.dart';
import 'grade_badge.dart';
import 'promotion_bouncing_card.dart';
import 'promotion_morph_route.dart';

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

  static IconData getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('математ') || s.contains('алгебр') || s.contains('геометр')) return CupertinoIcons.divide;
    if (s.contains('русск') || s.contains('литератур') || s.contains('чтени')) return CupertinoIcons.book;
    if (s.contains('физик')) return CupertinoIcons.lightbulb;
    if (s.contains('информат') || s.contains('программир') || s.contains('ит') || s.contains('it')) return CupertinoIcons.device_desktop;
    if (s.contains('истор') || s.contains('обществ') || s.contains('право')) return CupertinoIcons.building_2_fill;
    if (s.contains('англ') || s.contains('иностр') || s.contains('немец') || s.contains('франц')) return CupertinoIcons.textformat_abc;
    if (s.contains('биолог') || s.contains('естествозн') || s.contains('эколог')) return CupertinoIcons.leaf_arrow_circlepath;
    if (s.contains('географ')) return CupertinoIcons.compass;
    if (s.contains('физ-ра') || s.contains('физкультур') || s.contains('спорт')) return CupertinoIcons.sportscourt;
    if (s.contains('изо') || s.contains('музык') || s.contains('рисовани') || s.contains('искусств')) return CupertinoIcons.paintbrush;
    if (s.contains('технолог') || s.contains('труд')) return CupertinoIcons.hammer;
    if (s.contains('хими')) return CupertinoIcons.lab_flask;
    if (s.contains('обж') || s.contains('бжд') || s.contains('обзр')) return CupertinoIcons.shield;
    if (s.contains('эконом')) return CupertinoIcons.graph_square;
    if (s.contains('астроном')) return CupertinoIcons.moon;
    return CupertinoIcons.book_fill;
  }

  void _showLessonDetails(BuildContext context, [Rect? sourceRect]) {
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final rect = sourceRect ?? () {
      final rb = context.findRenderObject() as RenderBox?;
      if (rb != null && rb.hasSize) {
        final origin = rb.localToGlobal(Offset.zero);
        return Rect.fromLTWH(
          origin.dx + 16,
          origin.dy + 6,
          rb.size.width - 32,
          rb.size.height - 12,
        );
      }
      final size = MediaQuery.of(context).size;
      return Rect.fromLTWH(16, size.height / 2 - 50, size.width - 32, 100);
    }();

    showProMotionCardModal(
      context: context,
      sourceRect: rect,
      sourceRadius: 16.0,
      targetRadius: 24.0,
      isDark: isDark,
      collapsedChild: _buildCardContent(context, withMargin: false),
      builder: (ctx, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header: Icon + Subject Name + Time badge + Top-Right '✕' Close Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    getSubjectIcon(lesson.subject),
                    size: 22,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
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
                          letterSpacing: -0.3,
                          color: textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lesson.number} урок • ${lesson.startTime} – ${lesson.endTime}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
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

            // 2. Room & Teacher Tile (if present)
            if (lesson.room.isNotEmpty || lesson.teacher.isNotEmpty) ...[
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0E000000),
                    width: 0.6,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (lesson.room.isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
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
                      if (lesson.teacher.isNotEmpty) const SizedBox(height: 6),
                    ],
                    if (lesson.teacher.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.person_crop_circle,
                            size: 15,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 7),
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

            // 3. Topic Tile (ONLY if not empty)
            if (lesson.topic.isNotEmpty) ...[
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0E000000),
                    width: 0.6,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.doc_text_fill,
                          size: 12,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'ТЕМА УРОКА',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lesson.topic,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 4. Homework Tile (ONLY if not empty)
            if (lesson.homework != null && lesson.homework!.isNotEmpty) ...[
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0E000000),
                    width: 0.6,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.book_fill,
                          size: 12,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'ДОМАШНЕЕ ЗАДАНИЕ',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lesson.homework!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 5. Hero Grade Card (if grade present) or Attendance Tile
            if (lesson.grade != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
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
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                                    color: GradeBadge.getTextColor(lesson.grade!.value),
                                  ),
                                ),
                              ),
                              if (lesson.grade!.weight > 1) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0x28FFFFFF) : const Color(0x14000000),
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
                            lesson.grade!.topic.isNotEmpty ? lesson.grade!.topic : 'Ответ на уроке',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (lesson.grade!.comment != null && lesson.grade!.comment!.isNotEmpty) ...[
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
            ] else if (lesson.attendance != null && lesson.attendance!.isNotEmpty) ...[
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0E000000),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Посещаемость:', style: TextStyle(fontSize: 13, color: textSecondary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: (lesson.attendance == 'Н' ? AppTheme.grade2Color : AppTheme.grade4Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lesson.attendance!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: lesson.attendance == 'Н' ? AppTheme.grade2Color : AppTheme.grade4Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // 6. Action Button: Distinct Accent Share Button (#0A84FF)
            Builder(
              builder: (btnCtx) => CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 13),
                color: const Color(0xFF0A84FF),
                borderRadius: BorderRadius.circular(14),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final box = btnCtx.findRenderObject() as RenderBox?;
                  final origin = box != null && box.hasSize
                      ? box.localToGlobal(Offset.zero) & box.size
                      : Rect.fromLTWH(0, 0, MediaQuery.of(btnCtx).size.width, 100);

                  final buffer = StringBuffer();
                  buffer.writeln('Урок: ${lesson.subject}');
                  buffer.writeln('Время: ${lesson.startTime} – ${lesson.endTime}');
                  if (lesson.room.isNotEmpty) buffer.writeln('Кабинет: ${lesson.room}');
                  if (lesson.teacher.isNotEmpty) buffer.writeln('Учитель: ${lesson.teacher}');
                  if (lesson.topic.isNotEmpty) buffer.writeln('Тема: ${lesson.topic}');
                  if (lesson.homework != null && lesson.homework!.isNotEmpty) {
                    buffer.writeln('Д/з: ${lesson.homework}');
                  }
                  if (lesson.grade != null) {
                    buffer.writeln('Оценка: ${lesson.grade!.value}${lesson.grade!.weightSuperscript}');
                  }

                  try {
                    await Share.share(
                      buffer.toString().trim(),
                      subject: lesson.subject,
                      sharePositionOrigin: origin,
                    );
                  } catch (e) {
                    debugPrint('Share error: $e');
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(CupertinoIcons.share, size: 17, color: CupertinoColors.white),
                    SizedBox(width: 8),
                    Text(
                      'Поделиться уроком',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, {bool withMargin = true}) {
    final bg = isDark
        ? const Color(0xFF1C1C1E)
        : (isCurrent ? CupertinoColors.white : AppTheme.lightSurface);

    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final border = isCurrent
        ? (isDark ? CupertinoColors.white : CupertinoColors.black)
        : (isDark ? const Color(0x12FFFFFF) : const Color(0x0E000000));

    return Container(
      margin: withMargin
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6)
          : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: border,
          width: isCurrent ? 1.4 : 1.0,
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
          // Left: Subject Icon in translucent pill
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0E000000),
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

          // Center: Subject Name + Room Chip & Teacher + Extras
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (maxLines: 2, ellipsis)
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

                // Under title: Room Chip + Teacher FIO
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
                        if (lesson.teacher.isNotEmpty) const SizedBox(width: 8),
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
                      color: CupertinoColors.activeGreen
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
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

                if (lesson.homework != null && lesson.homework!.isNotEmpty) ...[
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
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Right: Time Badge & GradeBadge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Time Badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? (isCurrent
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF27272A))
                      : (isCurrent
                          ? CupertinoColors.white
                          : const Color(0xFFE4E4E7)),
                  borderRadius: BorderRadius.circular(8),
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

              if (lesson.grade != null) ...[
                const SizedBox(height: 8),
                GradeBadge.fromGradeItem(
                  lesson.grade!,
                  size: 32,
                  fontSize: 16,
                  borderRadius: 10,
                  isDark: isDark,
                ),
              ] else if (lesson.attendance != null && lesson.attendance!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (lesson.attendance == 'Н' ? AppTheme.grade2Color : AppTheme.grade4Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lesson.attendance!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: lesson.attendance == 'Н' ? AppTheme.grade2Color : AppTheme.grade4Color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
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
      buffer.writeln('⭐️ Оценка: ${lesson.grade!.value}${lesson.grade!.weightSuperscript}');
    }
    Share.share(
      buffer.toString().trim(),
      subject: '${lesson.subject} (${lesson.startTime} – ${lesson.endTime})',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardWidget = ProMotionBouncingCard(
      onTap: (ctx, sourceRect) {
        // Точные визуальные координаты карточки без внешних полей
        final visualRect = Rect.fromLTWH(
          sourceRect.left + 16,
          sourceRect.top + 6,
          sourceRect.width - 32,
          sourceRect.height - 12,
        );
        _showLessonDetails(ctx, visualRect);
      },
      child: _buildCardContent(context),
    );

    return CupertinoContextMenu.builder(
      actions: [
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.share,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
            Future.delayed(const Duration(milliseconds: 140), () {
              if (context.mounted) _shareLesson(context);
            });
          },
          child: const Text('Поделиться уроком'),
        ),
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.doc_on_doc,
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            final buffer = StringBuffer();
            buffer.writeln('${lesson.number}. ${lesson.subject} (${lesson.startTime} – ${lesson.endTime})');
            if (lesson.room.isNotEmpty) buffer.writeln('Кабинет: ${lesson.room}');
            if (lesson.teacher.isNotEmpty) buffer.writeln('Учитель: ${lesson.teacher}');
            if (lesson.homework != null && lesson.homework!.isNotEmpty) {
              buffer.writeln('Домашка: ${lesson.homework}');
            }
            Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
          },
          child: const Text('Скопировать информацию'),
        ),
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.info_circle,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
            Future.delayed(const Duration(milliseconds: 140), () {
              if (context.mounted) _showLessonDetails(context);
            });
          },
          child: const Text('Подробнее об уроке'),
        ),
      ],
      builder: (context, animation) {
        if (animation.value <= 0.001) {
          return cardWidget;
        }
        // Идеальное превью без искажений геометрии
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.25 * animation.value),
                blurRadius: 20 * animation.value,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _buildCardContent(context, withMargin: false),
        );
      },
    );
  }
}
