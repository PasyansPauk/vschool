import 'package:flutter/cupertino.dart';
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
      default:
        return dayName.substring(0, 2).toUpperCase();
    }
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
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(schedules.length, (index) {
          final item = schedules[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onDaySelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? activeBg : inactiveBg,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder,
                          width: 0.5,
                        ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _shortDay(item.dayName),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? activeText.withValues(alpha: 0.8)
                            : subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.date.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? activeText : inactiveText,
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
