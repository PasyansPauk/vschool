import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/school_day_schedule.dart';
import '../view_models/diary_view_model.dart';
import '../view_models/school_tracker_view_model.dart';
import '../widgets/segmented_day_picker.dart';
import '../widgets/lesson_card.dart';

class ScheduleScreen extends StatelessWidget {
  final DiaryViewModel diaryViewModel;
  final SchoolTrackerViewModel trackerViewModel;
  final bool isDark;

  const ScheduleScreen({
    super.key,
    required this.diaryViewModel,
    required this.trackerViewModel,
    required this.isDark,
  });

  String _formatWeekRange(DateTime date) {
    const monthsGen = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];

    // Find Monday of the current selected week
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
    // Find Sunday of the week
    final sunday = monday.add(const Duration(days: 6));

    if (monday.month == sunday.month) {
      return '${monday.day} – ${sunday.day} ${monthsGen[monday.month - 1]} ${monday.year}';
    } else if (monday.year == sunday.year) {
      return '${monday.day} ${monthsGen[monday.month - 1]} – ${sunday.day} ${monthsGen[sunday.month - 1]} ${sunday.year}';
    } else {
      return '${monday.day} ${monthsGen[monday.month - 1]} ${monday.year} – ${sunday.day} ${monthsGen[sunday.month - 1]} ${sunday.year}';
    }
  }

  String _formatTodayLabel() {
    final now = DateTime.now();
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const monthsGen = [
      'янв',
      'фев',
      'мар',
      'апр',
      'мая',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек'
    ];
    return 'Сегодня: ${weekdays[now.weekday - 1]}, ${now.day} ${monthsGen[now.month - 1]}';
  }

  String _getLessonWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'урок';
    if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return 'урока';
    }
    return 'уроков';
  }

  bool _isBreakActive(ScheduleBreak b, DateTime dayDate) {
    final now = DateTime.now();
    if (now.year != dayDate.year || now.month != dayDate.month || now.day != dayDate.day) {
      return false;
    }
    try {
      final p1 = b.startTime.split(':');
      final p2 = b.endTime.split(':');
      final start = DateTime(now.year, now.month, now.day, int.parse(p1[0]), int.parse(p1[1]));
      final end = DateTime(now.year, now.month, now.day, int.parse(p2[0]), int.parse(p2[1]));
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }

  int _getBreakRemainingMinutes(ScheduleBreak b) {
    final now = DateTime.now();
    try {
      final p2 = b.endTime.split(':');
      final end = DateTime(now.year, now.month, now.day, int.parse(p2[0]), int.parse(p2[1]));
      final diff = end.difference(now).inMinutes + 1;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildBreakCard(ScheduleBreak b, DateTime dayDate, bool isDark) {
    final bool isActive = _isBreakActive(b, dayDate);
    final int remainingMins = isActive ? _getBreakRemainingMinutes(b) : 0;

    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final String emoji = b.name.toLowerCase().contains('обед') || b.durationMinutes >= 30
        ? '🥪'
        : (b.durationMinutes >= 20 ? '☕️' : '⏱️');

    final bg = isActive
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
        : (isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FB));
    final border = isActive
        ? CupertinoColors.activeBlue
        : (isDark ? const Color(0xFF222226) : const Color(0xFFECECEF));

    // Visually smaller, sleeker break pill (less prominent than lesson)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: border,
          width: isActive ? 1.2 : 0.6,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Break icon pill (compact)
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF202024) : CupertinoColors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFE4E4E7),
                width: 0.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 10),

          // Break info
          Expanded(
            child: Row(
              children: [
                Text(
                  b.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? (isDark ? CupertinoColors.activeBlue : const Color(0xFF1D4ED8))
                        : textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '• ${b.durationMinutes} мин',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'СЕЙЧАС${remainingMins > 0 ? ' ($remainingMins м)' : ''}',
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: CupertinoColors.activeGreen,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Time Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: isDark
                  ? (isActive ? const Color(0xFF0F172A) : const Color(0xFF202024))
                  : (isActive ? CupertinoColors.white : const Color(0xFFE4E4E7)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${b.startTime} – ${b.endTime}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? (isDark ? CupertinoColors.white : const Color(0xFF1D4ED8))
                    : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _motivationalQuotes = [
    'Знание — сила, а терпение — ключ к любой победе.',
    'Твой 11 класс — это трамплин в большое будущее. Выжми из него максимум!',
    'Успех — это сумма небольших усилий, повторяемых день за днём.',
    'Каждый решённый сегодня пример приближает тебя к бюджету мечты ✨',
    'Дисциплина — это решение делать то, чего не хочется, чтобы достичь того, чего очень хочется.',
    'Трудности закаляют характер. Держи планку высоко!',
    'Ты способен на большее, чем думаешь. Сосредоточься и иди вперед 💪',
    'Маленький шаг сегодня — большой результат на экзаменах завтра.',
    'Не бойся ошибаться — бойся не пробовать. У тебя всё получится!',
    'Инвестируй в свои знания — это лучший актив на всю жизнь.',
    'Сложные уроки готовят великих людей. Выкладывайся на все 100%!',
    'Дорогу осилит идущий. До конца уроков осталось совсем немного! 🚀',
    'Великие победы начинаются с простых тетрадных страниц.',
    'Будущее принадлежит тем, кто верит в красоту своей мечты.',
    'Делай сегодня то, что другие не хотят — завтра будешь жить так, как другие не могут.',
    'Оставайся сфокусированным: перемена уже близко, а цель ещё ближе! 🎯',
    'Лучший способ предсказать свое будущее — создать его своими руками.',
    'Каждый урок приближает тебя к выпускному. Держи темп!',
    'Упорство побеждает талант, когда талант не проявляет упорства.',
    'Через пару месяцев ты скажешь себе спасибо за то, что не сдался сегодня! ⭐️',
    'Учиться тяжело, но результаты останутся с тобой на всю жизнь.',
    'Верь в себя даже тогда, когда звонок кажется слишком далеким.',
    'Никакая цель не является слишком высокой, если двигаться к ней шаг за шагом.',
    'Твой потенциал безграничен — покажи, на что ты способен!',
  ];

  Widget _buildDayEndCard(dynamic schedule, bool isDark) {
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final now = DateTime.now();
    final schedDate = schedule.date as DateTime;
    final bool isToday = schedDate.year == now.year &&
        schedDate.month == now.month &&
        schedDate.day == now.day;
    final bool isPast = schedDate.isBefore(DateTime(now.year, now.month, now.day));

    bool isFinished = isPast;
    if (isToday && schedule.lessons.isNotEmpty) {
      final lastLesson = schedule.lessons.last;
      try {
        final parts = (lastLesson.endTime as String).split(':');
        final endHour = int.tryParse(parts[0]) ?? 15;
        final endMin = int.tryParse(parts[1]) ?? 10;
        final endDt = DateTime(now.year, now.month, now.day, endHour, endMin);
        isFinished = now.isAfter(endDt);
      } catch (_) {}
    }

    if (isFinished) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ура, уроки закончились!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Пора домой отдыхать и делать домашку 😊',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Pick quote deterministically based on day and hour so it's varied and fresh
      final quoteIndex = (schedDate.day * 7 + schedDate.month * 13 + now.hour) %
          _motivationalQuotes.length;
      final quote = _motivationalQuotes[quoteIndex];

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Мысль дня',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quote,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = diaryViewModel.currentDaySchedule;
    final currentLesson = trackerViewModel.getCurrentLesson(schedule);

    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final bool hasNoSchedulesAtAll = diaryViewModel.schedules.isEmpty;

    // Display date context for the active schedule
    final displayDate = schedule != null ? schedule.date : diaryViewModel.selectedWeekDate;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0.0;
        // Swipe Left -> Next Week (positive drag to left)
        if (velocity < -300) {
          HapticFeedback.lightImpact();
          diaryViewModel.nextWeek();
        }
        // Swipe Right -> Previous Week (positive drag to right)
        else if (velocity > 300) {
          HapticFeedback.lightImpact();
          diaryViewModel.previousWeek();
        }
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await diaryViewModel.loadData(forceRefresh: true);
            },
          ),

        // Week Date Range Header & Week Navigation Controls
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatWeekRange(displayDate),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        diaryViewModel.goToToday();
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: CupertinoColors.activeBlue,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatTodayLabel(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.activeBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Navigation buttons (Previous Week, Next Week)
                Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(32, 32),
                      color: isDark
                          ? AppTheme.darkSurfaceSecondary
                          : AppTheme.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        diaryViewModel.previousWeek();
                      },
                      child: Icon(
                        CupertinoIcons.chevron_left,
                        size: 16,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(32, 32),
                      color: isDark
                          ? AppTheme.darkSurfaceSecondary
                          : AppTheme.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        diaryViewModel.nextWeek();
                      },
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Day Selector Bar (7 days)
        if (!hasNoSchedulesAtAll)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: SegmentedDayPicker(
                schedules: diaryViewModel.schedules,
                selectedIndex: diaryViewModel.selectedDayIndex,
                onDaySelected: (index) => diaryViewModel.selectDay(index),
                isDark: isDark,
              ),
            ),
          ),

        // Day Header Info Card (Lessons count & time range)
        if (schedule != null && schedule.lessons.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${schedule.dayName}, ${schedule.date.day} ${_getMonthGen(schedule.date.month)}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${schedule.lessons.length} ${_getLessonWord(schedule.lessons.length)} • ${schedule.startTime} – ${schedule.endTime}',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Lessons List with Breaks between them and celebration at the end
        if (schedule != null && schedule.lessons.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == schedule.lessons.length) {
                  return _buildDayEndCard(schedule, isDark);
                }

                final lesson = schedule.lessons[index];
                final isCurrent = currentLesson?.number == lesson.number;

                // Dedicated break card after this lesson
                final breakInfo = schedule.getBreakAfter(index);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LessonCard(
                      lesson: lesson,
                      isDark: isDark,
                      isCurrent: isCurrent,
                    ),
                    if (breakInfo != null)
                      _buildBreakCard(breakInfo, schedule.date, isDark),
                  ],
                );
              },
              childCount: schedule.lessons.length + 1,
            ),
          )
        else if (hasNoSchedulesAtAll)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_circle,
                      size: 56,
                      color: textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Данные из МЭШ не загружены',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      diaryViewModel.errorMessage ??
                          'Расписание не получено. Попробуйте нажать кнопку ниже для повторной попытки.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton(
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      onPressed: () {
                        diaryViewModel.loadData(forceRefresh: true);
                      },
                      child: Text(
                        'Повторить загрузку',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? CupertinoColors.black
                              : CupertinoColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          // Weekend or Free Day State
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (schedule != null && schedule.isWeekend) ? '🏖️' : '🎉',
                      style: const TextStyle(fontSize: 54),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      (schedule != null && schedule.isWeekend)
                          ? 'Ура, выходной!'
                          : 'На этот день уроков нет!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (schedule != null && schedule.isWeekend)
                          ? 'Уроков нет. Время отдыхать, гулять и восстанавливать силы ✨'
                          : 'Праздник, каникулы или свободный день 🎉',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Bottom space so that "Мысль дня" and the last cards sit comfortably above the tab bar
        const SliverToBoxAdapter(
          child: SizedBox(height: 120),
        ),
      ],
    ),
  );
}

  String _getMonthGen(int month) {
    const monthsGen = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    return (month >= 1 && month <= 12) ? monthsGen[month - 1] : '';
  }
}
