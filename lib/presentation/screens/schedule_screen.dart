import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';
import '../view_models/diary_view_model.dart';
import '../view_models/school_tracker_view_model.dart';
import '../widgets/segmented_day_picker.dart';
import '../widgets/lesson_card.dart';
import 'mos_id_webview_screen.dart';

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

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await diaryViewModel.loadData(forceRefresh: true);
          },
        ),

        // Day Selector Bar (only if we have schedules)
        if (!hasNoSchedulesAtAll)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: SegmentedDayPicker(
                schedules: diaryViewModel.schedules,
                selectedIndex: diaryViewModel.selectedDayIndex,
                onDaySelected: (index) => diaryViewModel.selectDay(index),
                isDark: isDark,
              ),
            ),
          ),

        // Day Header Info Card
        if (schedule != null && schedule.lessons.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.all(16),
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
                        schedule.dayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${schedule.lessons.length} уроков • ${schedule.startTime} – ${schedule.endTime}',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurfaceSecondary
                          : AppTheme.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.bell,
                          size: 14,
                          color: textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Звонки по 45 мин',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Lessons List or Empty / Error states
        if (schedule != null && schedule.lessons.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final lesson = schedule.lessons[index];
                final isCurrent = currentLesson?.number == lesson.number;
                return LessonCard(
                  lesson: lesson,
                  isDark: isDark,
                  isCurrent: isCurrent,
                );
              },
              childCount: schedule.lessons.length,
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
                          'Расписание не получено. Попробуйте обновить данные или повторно войти через Mos.ID.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      onPressed: () =>
                          diaryViewModel.loadData(forceRefresh: true),
                      child: const Text('Обновить расписание'),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      onPressed: () async {
                        final res = await MosIdWebViewScreen.show(context,
                            isDark: isDark);
                        if (res == true) {
                          diaryViewModel.loadData(forceRefresh: true);
                        }
                      },
                      child: const Text(
                        'Войти через Mos.ID заново',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    size: 48,
                    color: textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'На этот день нет уроков',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }
}
