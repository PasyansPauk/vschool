import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/school_day_schedule.dart';
import '../../view_models/diary_view_model.dart';
import '../../view_models/school_tracker_view_model.dart';
import '../widgets/android_break_divider.dart';
import '../widgets/android_lesson_card.dart';

class AndroidScheduleScreen extends StatefulWidget {
  final DiaryViewModel diaryViewModel;
  final SchoolTrackerViewModel trackerViewModel;
  final bool isDark;

  const AndroidScheduleScreen({
    super.key,
    required this.diaryViewModel,
    required this.trackerViewModel,
    required this.isDark,
  });

  @override
  State<AndroidScheduleScreen> createState() => _AndroidScheduleScreenState();
}

class _AndroidScheduleScreenState extends State<AndroidScheduleScreen> {
  late PageController _pageController;
  bool _isPageAnimating = false;
  DateTime? _activeWeekDate;

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
  ];

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
  void didUpdateWidget(covariant AndroidScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final vm = widget.diaryViewModel;

    if (_activeWeekDate == null || !_isSameWeek(_activeWeekDate!, vm.selectedWeekDate)) {
      _activeWeekDate = vm.selectedWeekDate;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(vm.selectedDayIndex.clamp(0, 6));
      }
    } else {
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

  Widget _buildWeekNavigator(bool isDark) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final vm = widget.diaryViewModel;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: 28, color: textPrimary),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  vm.previousWeek();
                },
              ),
              Column(
                children: [
                  Text(
                    _formatWeekRange(vm.selectedWeekDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      vm.loadData(forceRefresh: true);
                    },
                    child: Text(
                      _formatTodayLabel(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, size: 28, color: textPrimary),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  vm.nextWeek();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 7-day Segmented Selector
          _buildDayPicker(isDark),
        ],
      ),
    );
  }

  Widget _buildDayPicker(bool isDark) {
    final vm = widget.diaryViewModel;
    const dayNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    final monday = vm.selectedWeekDate.subtract(Duration(days: vm.selectedWeekDate.weekday - 1));
    final now = DateTime.now();

    return Row(
      children: List.generate(7, (index) {
        final dayDate = monday.add(Duration(days: index));
        final isSelected = vm.selectedDayIndex == index;
        final isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              vm.selectDay(index);
              if (_pageController.hasClients) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.2) : const Color(0xFF0284C7).withValues(alpha: 0.15))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        width: 1.2,
                      )
                    : (isToday
                        ? Border.all(
                            color: isDark ? Colors.white30 : Colors.black26,
                            width: 0.8,
                          )
                        : null),
              ),
              child: Column(
                children: [
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                          : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dayDate.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDaySchedule(SchoolDaySchedule? schedule, DateTime dayDate, bool isDark) {
    final vm = widget.diaryViewModel;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final now = DateTime.now();
    final bool isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;
    final currentLesson =
        (isToday && schedule != null) ? widget.trackerViewModel.getCurrentLesson(schedule) : null;

    final bool isWeekLoading = vm.isLoading && !vm.isScheduleMatchingSelectedWeek;

    return RefreshIndicator(
      color: const Color(0xFF38BDF8),
      onRefresh: () async {
        await vm.loadData(forceRefresh: true);
      },
      child: isWeekLoading
          ? _buildLoadingSkeleton(isDark)
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Day Header Tile
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          schedule != null && schedule.lessons.isNotEmpty
                              ? '${schedule.lessons.length} ${_getLessonWord(schedule.lessons.length)}'
                              : 'Нет уроков',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        if (schedule != null && schedule.lessons.isNotEmpty)
                          Text(
                            '${schedule.lessons.first.startTime} – ${schedule.lessons.last.endTime}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
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
                        if (index == schedule.lessons.length) {
                          return _buildDayEndCard(schedule, isDark);
                        }
                        final lesson = schedule.lessons[index];
                        final isCurrent = isToday && currentLesson?.number == lesson.number;
                        final breakInfo = schedule.getBreakAfter(index);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AndroidLessonCard(
                              lesson: lesson,
                              isDark: isDark,
                              isCurrent: isCurrent,
                            ),
                            if (breakInfo != null)
                              AndroidBreakDivider(
                                breakInfo: breakInfo,
                                dayDate: schedule.date,
                                isDark: isDark,
                              ),
                          ],
                        );
                      },
                      childCount: schedule.lessons.length + 1,
                    ),
                  )
                else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.weekend_outlined,
                            size: 64,
                            color: textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Уроков не запланировано',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Отличный день для отдыха и повторения материала',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FB),
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF242426) : const Color(0xFFE4E4E7),
          ),
        ),
        child: const SizedBox(
          height: 88,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayEndCard(SchoolDaySchedule schedule, bool isDark) {
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final randomQuote = _motivationalQuotes[schedule.date.day % _motivationalQuotes.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF242426) : const Color(0xFFE4E4E7),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.stars_outlined, size: 28, color: Color(0xFFFBBF24)),
          const SizedBox(height: 8),
          Text(
            randomQuote,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final vm = widget.diaryViewModel;
    final monday = vm.selectedWeekDate.subtract(Duration(days: vm.selectedWeekDate.weekday - 1));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildWeekNavigator(isDark),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 7,
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                  vm.selectDay(index);
                },
                itemBuilder: (context, index) {
                  final dayDate = monday.add(Duration(days: index));
                  SchoolDaySchedule? schedule;
                  final targetWeekday = index + 1;
                  for (final s in vm.schedules) {
                    if (s.date.weekday == targetWeekday) {
                      schedule = s;
                      break;
                    }
                  }
                  return _buildDaySchedule(schedule, dayDate, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
