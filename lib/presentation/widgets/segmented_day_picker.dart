import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/school_day_schedule.dart';

class SegmentedDayPicker extends StatelessWidget {
  final List<SchoolDaySchedule> schedules;
  final int selectedIndex;
  final ValueChanged<int> onDaySelected;
  final bool isDark;

  const SegmentedDayPicker({
    super.key,
    required this.schedules,
    required this.selectedIndex,
    required this.onDaySelected,
    required this.isDark,
  });

  String _shortDay(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'понедельник':
        return 'ПН';
      case 'вторник':
        return 'ВТ';
      case 'среда':
        return 'СР';
      case 'четверг':
        return 'ЧТ';
      case 'пятница':
        return 'ПТ';
      case 'суббота':
        return 'СБ';
      case 'воскресенье':
        return 'ВС';
      default:
        return dayName.length >= 2 ? dayName.substring(0, 2).toUpperCase() : dayName;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) return const SizedBox.shrink();

    final activeBg = isDark ? CupertinoColors.white : CupertinoColors.black;
    final activeText = isDark ? CupertinoColors.black : CupertinoColors.white;
    final inactiveBg =
        isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary;
    final inactiveText =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final subtitleColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(schedules.length, (index) {
          final item = schedules[index];
          final isSelected = index == selectedIndex;
          final isWeekend = item.date.weekday == DateTime.saturday || item.date.weekday == DateTime.sunday;
          final isTodayDate = _isToday(item.date);

          // Color for the date number
          Color dateNumberColor;
          if (isSelected) {
            dateNumberColor = activeText;
          } else if (isWeekend) {
            dateNumberColor = const Color(0xFFFF453A); // Red for weekends
          } else {
            dateNumberColor = inactiveText;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onDaySelected(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  color: isSelected ? activeBg : inactiveBg,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isTodayDate
                              ? CupertinoColors.activeBlue.withValues(alpha: 0.8)
                              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          width: isTodayDate ? 1.5 : 0.5,
                        ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _shortDay(item.dayName),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? activeText.withValues(alpha: 0.8)
                            : (isWeekend ? const Color(0xFFFF6961) : subtitleColor),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.date.day}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: dateNumberColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Small Today indicator dot
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isTodayDate
                            ? (isSelected ? activeText : CupertinoColors.activeBlue)
                            : CupertinoColors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
