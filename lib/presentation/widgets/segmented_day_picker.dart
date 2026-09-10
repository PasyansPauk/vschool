import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/school_day_schedule.dart';

class SegmentedDayPicker extends StatelessWidget {
  final DateTime weekDate;
  final List<SchoolDaySchedule>? schedules;
  final int selectedIndex;
  final ValueChanged<int> onDaySelected;
  final bool isDark;

  const SegmentedDayPicker({
    super.key,
    required this.weekDate,
    this.schedules,
    required this.selectedIndex,
    required this.onDaySelected,
    required this.isDark,
  });

  static const List<String> _shortDays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? CupertinoColors.white : CupertinoColors.black;
    final activeText = isDark ? CupertinoColors.black : CupertinoColors.white;
    final inactiveBg =
        isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary;
    final inactiveText =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final subtitleColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final monday = DateTime(weekDate.year, weekDate.month, weekDate.day)
        .subtract(Duration(days: weekDate.weekday - 1));

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(7, (index) {
          final dayDate = monday.add(Duration(days: index));
          final isSelected = index == selectedIndex;
          final isWeekend = index >= 5; // Saturday (5) and Sunday (6)
          final isTodayDate = _isToday(dayDate);

          // Color for the date number
          final Color dateNumberColor;
          if (isSelected) {
            dateNumberColor = activeText;
          } else if (isWeekend) {
            dateNumberColor = const Color(0xFFFF453A); // Red for weekends
          } else {
            dateNumberColor = inactiveText;
          }

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
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
                      _shortDays[index],
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
                      '${dayDate.day}',
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
