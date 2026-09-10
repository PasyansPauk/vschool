import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/school_day_schedule.dart';
import '../view_models/diary_view_model.dart';
import '../view_models/school_tracker_view_model.dart';
import '../widgets/segmented_day_picker.dart';
import '../widgets/lesson_card.dart';

class ScheduleScreen extends StatefulWidget {
  final DiaryViewModel diaryViewModel;
  final SchoolTrackerViewModel trackerViewModel;
  final bool isDark;

  const ScheduleScreen({
    super.key,
    required this.diaryViewModel,
    required this.trackerViewModel,
    required this.isDark,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late PageController _pageController;
  bool _isPageAnimating = false;
  bool _isWeekTransitioning = false;
  DateTime? _activeWeekDate;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.diaryViewModel.selectedDayIndex.clamp(0, 6),
    );
    _activeWeekDate = widget.diaryViewModel.selectedWeekDate;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final vm = widget.diaryViewModel;

    // Check if week changed
    if (_activeWeekDate == null || !_isSameWeek(_activeWeekDate!, vm.selectedWeekDate)) {
      _activeWeekDate = vm.selectedWeekDate;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(vm.selectedDayIndex.clamp(0, 6));
      }
    } else {
      // Week is identical, check if day was switched externally
      if (_pageController.hasClients &&
          !_isPageAnimating &&
          _pageController.page?.round() != vm.selectedDayIndex) {
        _isPageAnimating = true;
        _pageController
            .animateToPage(
              vm.selectedDayIndex.clamp(0, 6),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            )
            .then((_) => _isPageAnimating = false);
      }
    }
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final monA = DateTime(a.year, a.month, a.day).subtract(Duration(days: a.weekday - 1));
    final monB = DateTime(b.year, b.month, b.day).subtract(Duration(days: b.weekday - 1));
    return monA.year == monB.year && monA.month == monB.month && monA.day == monB.day;
  }

  String _formatWeekRange(DateTime date) {
    const monthsGen = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
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
    const monthsGen = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return 'Сегодня: ${weekdays[now.weekday - 1]}, ${now.day} ${monthsGen[now.month - 1]}';
  }

  String _getLessonWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'урок';
    if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) return 'урока';
    return 'уроков';
  }

  String _getMonthGen(int month) {
    const monthsGen = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return (month >= 1 && month <= 12) ? monthsGen[month - 1] : '';
  }

  bool _isBreakActive(ScheduleBreak b, DateTime dayDate) {
    final now = DateTime.now();
    if (now.year != dayDate.year || now.month != dayDate.month || now.day != dayDate.day) return false;
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
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final lineColor =
        isDark ? const Color(0x18FFFFFF) : const Color(0x12000000);
    final activeColor =
        isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    return Container(
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.8,
              color: isActive ? activeColor.withValues(alpha: 0.35) : lineColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? CupertinoIcons.timer_fill : CupertinoIcons.circle_fill,
                  size: isActive ? 11 : 4.5,
                  color: isActive ? activeColor : textSecondary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Перемена ${b.durationMinutes} мин • ${b.startTime} – ${b.endTime}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? activeColor : textSecondary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (isActive && remainingMins > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$remainingMins м',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: activeColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 0.8,
              color: isActive ? activeColor.withValues(alpha: 0.35) : lineColor,
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

  Widget _buildDayEndCard(SchoolDaySchedule schedule, bool isDark) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final now = DateTime.now();
    final schedDate = schedule.date;
    final bool isToday = schedDate.year == now.year && schedDate.month == now.month && schedDate.day == now.day;
    final bool isPast = schedDate.isBefore(DateTime(now.year, now.month, now.day));

    bool isFinished = isPast;
    if (isToday && schedule.lessons.isNotEmpty) {
      final lastLesson = schedule.lessons.last;
      try {
        final parts = lastLesson.endTime.split(':');
        final endHour = int.tryParse(parts[0]) ?? 15;
        final endMin = int.tryParse(parts[1]) ?? 10;
        final endDt = DateTime(now.year, now.month, now.day, endHour, endMin);
        isFinished = now.isAfter(endDt);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: isFinished
          ? Row(children: [
              const Text('🎉', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ура, уроки закончились!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text('Пора домой отдыхать и делать домашку 😊',
                      style: TextStyle(fontSize: 13, color: textSecondary)),
                ]),
              ),
            ])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Мысль дня',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      _motivationalQuotes[(schedDate.day * 7 + schedDate.month * 13 + now.hour) %
                          _motivationalQuotes.length],
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary, height: 1.35),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }

  
  Widget _buildLoadingSkeleton(bool isDark) {
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final shimmerColor = isDark ? const Color(0xFF202024) : const Color(0xFFE4E4E7);
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 140,
                height: 18,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const Spacer(),
              const CupertinoActivityIndicator(radius: 9),
            ],
          ),
        ),
        ...List.generate(3, (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 130 + (i * 25.0),
                      height: 16,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 190,
                      height: 12,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    final vm = widget.diaryViewModel;
    final schedule = vm.currentDaySchedule;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final displayDate = schedule != null ? schedule.date : vm.selectedWeekDate;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0.0;
        if (velocity < -300) {
          HapticFeedback.lightImpact();
          vm.nextWeek();
        } else if (velocity > 300) {
          HapticFeedback.lightImpact();
          vm.previousWeek();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
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
                          letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        vm.loadData(forceRefresh: true);
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: CupertinoColors.activeBlue),
                          ),
                          const SizedBox(width: 5),
                          Text(_formatTodayLabel(),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.activeBlue)),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(32, 32),
                      color: isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        vm.previousWeek();
                      },
                      child: Icon(CupertinoIcons.chevron_left, size: 16, color: textPrimary),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(32, 32),
                      color: isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        vm.nextWeek();
                      },
                      child: Icon(CupertinoIcons.chevron_right, size: 16, color: textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: SegmentedDayPicker(
              weekDate: vm.selectedWeekDate,
              schedules: vm.schedules,
              selectedIndex: vm.selectedDayIndex,
              onDaySelected: (index) {
                HapticFeedback.selectionClick();
                vm.selectDay(index);
                if (_pageController.hasClients) {
                  _isPageAnimating = true;
                  _pageController
                      .animateToPage(
                        index,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      )
                      .then((_) => _isPageAnimating = false);
                }
              },
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(int dayIndex, bool isDark) {
    final vm = widget.diaryViewModel;
    if (vm.isLoading && !vm.isScheduleMatchingSelectedWeek) {
      return _buildLoadingSkeleton(isDark);
    }

    SchoolDaySchedule? schedule;
    final targetWeekday = dayIndex + 1;
    for (final s in vm.schedules) {
      if (s.date.weekday == targetWeekday) {
        schedule = s;
        break;
      }
    }

    final now = DateTime.now();
    final bool isToday = schedule != null &&
        schedule.date.year == now.year &&
        schedule.date.month == now.month &&
        schedule.date.day == now.day;
    final currentLesson = isToday ? widget.trackerViewModel.getCurrentLesson(schedule) : null;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final bool hasNoSchedulesAtAll = vm.schedules.isEmpty && vm.errorMessage != null;

    return CustomScrollView(
      key: PageStorageKey('schedule_day_${vm.selectedWeekDate.year}_${vm.selectedWeekDate.month}_${vm.selectedWeekDate.day}_$dayIndex'),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await vm.loadData(forceRefresh: true);
          },
        ),

        // Day Header Info Card
        if (schedule != null && schedule.lessons.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${schedule.dayName}, ${schedule.date.day} ${_getMonthGen(schedule.date.month)}',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${schedule.lessons.length} ${_getLessonWord(schedule.lessons.length)} • ${schedule.startTime} – ${schedule.endTime}',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Lessons List
        if (schedule != null && schedule.lessons.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == schedule!.lessons.length) {
                  return _buildDayEndCard(schedule, isDark);
                }
                final lesson = schedule.lessons[index];
                final isCurrent = isToday && currentLesson?.number == lesson.number;
                final breakInfo = schedule.getBreakAfter(index);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LessonCard(lesson: lesson, isDark: isDark, isCurrent: isCurrent),
                    if (breakInfo != null) _buildBreakCard(breakInfo, schedule.date, isDark),
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
                    Icon(CupertinoIcons.exclamationmark_circle, size: 56, color: textSecondary),
                    const SizedBox(height: 16),
                    Text('Данные из МЭШ не загружены',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      vm.errorMessage ??
                          'Расписание не получено. Попробуйте нажать кнопку ниже для повторной попытки.',
                      style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton(
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      onPressed: () => vm.loadData(forceRefresh: true),
                      child: Text(
                        'Повторить загрузку',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? CupertinoColors.black : CupertinoColors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text((schedule != null && schedule.isWeekend) ? '🏖️' : '🎉',
                        style: const TextStyle(fontSize: 54)),
                    const SizedBox(height: 16),
                    Text(
                      (schedule != null && schedule.isWeekend) ? 'Ура, выходной!' : 'На этот день уроков нет!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (schedule != null && schedule.isWeekend)
                          ? 'Уроков нет. Время отдыхать, гулять и восстанавливать силы ✨'
                          : 'Праздник, каникулы или свободный день 🎉',
                      style: TextStyle(fontSize: 14, color: textSecondary, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.diaryViewModel;
    final isDark = widget.isDark;

    return Column(
      children: [
        _buildHeader(isDark),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) {
              final dir = vm.weekSwitchDirection != 0 ? vm.weekSwitchDirection : 1;
              final beginOffset = dir == 1 ? const Offset(0.2, 0) : const Offset(-0.2, 0);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey('${vm.selectedWeekDate.year}_${vm.selectedWeekDate.month}_${vm.selectedWeekDate.day}'),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is OverscrollNotification && !_isWeekTransitioning) {
                    final overscroll = notification.overscroll;
                    if (overscroll > 35 && vm.selectedDayIndex >= 6) {
                      _isWeekTransitioning = true;
                      HapticFeedback.mediumImpact();
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(0);
                      }
                      vm.nextWeek().then((_) {
                        _isWeekTransitioning = false;
                      });
                    } else if (overscroll < -35 && vm.selectedDayIndex <= 0) {
                      _isWeekTransitioning = true;
                      HapticFeedback.mediumImpact();
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(6);
                      }
                      vm.previousWeek().then((_) {
                        _isWeekTransitioning = false;
                      });
                    }
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  itemCount: 7,
                  onPageChanged: (index) {
                    if (!_isPageAnimating) {
                      HapticFeedback.selectionClick();
                      vm.selectDay(index);
                    }
                  },
                  itemBuilder: (context, dayIndex) {
                    return _buildDaySchedule(dayIndex, isDark);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
