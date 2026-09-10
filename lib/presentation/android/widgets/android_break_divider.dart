import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/school_day_schedule.dart';

/// Minimalist timeline divider between lesson cards for Android Material 3.
class AndroidBreakDivider extends StatelessWidget {
  final ScheduleBreak breakInfo;
  final DateTime dayDate;
  final bool isDark;

  const AndroidBreakDivider({
    super.key,
    required this.breakInfo,
    required this.dayDate,
    required this.isDark,
  });

  bool _isBreakActive(ScheduleBreak b, DateTime dayDate) {
    final now = DateTime.now();
    final bool isToday = dayDate.year == now.year &&
        dayDate.month == now.month &&
        dayDate.day == now.day;
    if (!isToday) return false;

    try {
      final startParts = b.startTime.split(':');
      final endParts = b.endTime.split(':');
      final startMins = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMins = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final currentMins = now.hour * 60 + now.minute;
      return currentMins >= startMins && currentMins < endMins;
    } catch (_) {
      return false;
    }
  }

  int _getBreakRemainingMinutes(ScheduleBreak b) {
    final now = DateTime.now();
    try {
      final endParts = b.endTime.split(':');
      final endMins = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final currentMins = now.hour * 60 + now.minute;
      final diff = endMins - currentMins;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _isBreakActive(breakInfo, dayDate);
    final int remainingMins = isActive ? _getBreakRemainingMinutes(breakInfo) : 0;
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
                  isActive ? Icons.timer_outlined : Icons.circle,
                  size: isActive ? 12 : 5,
                  color: isActive ? activeColor : textSecondary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Перемена ${breakInfo.durationMinutes} мин • ${breakInfo.startTime} – ${breakInfo.endTime}',
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
}
