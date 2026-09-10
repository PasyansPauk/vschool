import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/lesson.dart';
import '../../data/models/school_day_schedule.dart';

class SchoolTrackerViewModel extends ChangeNotifier {
  Timer? _timer;
  DateTime _now = DateTime.now();
  DateTime get now => _now;

  SchoolTrackerViewModel() {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      notifyListeners();
    });
  }

  DateTime _parseTime(String timeStr, [DateTime? date]) {
    final targetDate = date ?? _now;
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 30;
    return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute, 0);
  }

  bool isToday(SchoolDaySchedule? schedule) {
    if (schedule == null) return false;
    return schedule.date.year == _now.year &&
        schedule.date.month == _now.month &&
        schedule.date.day == _now.day;
  }

  Duration getTimeSpent(SchoolDaySchedule? schedule) {
    if (schedule == null || schedule.lessons.isEmpty) return Duration.zero;
    final scheduleDate = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
    final today = DateTime(_now.year, _now.month, _now.day);

    if (scheduleDate.isBefore(today)) {
      final start = _parseTime(schedule.lessons.first.startTime, schedule.date);
      final end = _parseTime(schedule.lessons.last.endTime, schedule.date);
      return end.difference(start);
    }
    if (scheduleDate.isAfter(today)) {
      return Duration.zero;
    }

    final start = _parseTime(schedule.lessons.first.startTime, schedule.date);
    if (_now.isBefore(start)) return Duration.zero;
    final end = _parseTime(schedule.lessons.last.endTime, schedule.date);
    if (_now.isAfter(end)) return end.difference(start);
    return _now.difference(start);
  }

  Duration getTimeRemaining(SchoolDaySchedule? schedule) {
    if (schedule == null || schedule.lessons.isEmpty) return Duration.zero;
    final scheduleDate = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
    final today = DateTime(_now.year, _now.month, _now.day);

    if (scheduleDate.isBefore(today)) {
      return Duration.zero;
    }
    if (scheduleDate.isAfter(today)) {
      final start = _parseTime(schedule.lessons.first.startTime, schedule.date);
      final end = _parseTime(schedule.lessons.last.endTime, schedule.date);
      return end.difference(start);
    }

    final end = _parseTime(schedule.lessons.last.endTime, schedule.date);
    if (_now.isAfter(end)) return Duration.zero;
    final start = _parseTime(schedule.lessons.first.startTime, schedule.date);
    if (_now.isBefore(start)) return end.difference(start);
    return end.difference(_now);
  }

  double getDayProgress(SchoolDaySchedule? schedule) {
    if (schedule == null || schedule.lessons.isEmpty) return 0.0;
    final scheduleDate = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
    final today = DateTime(_now.year, _now.month, _now.day);

    if (scheduleDate.isBefore(today)) return 1.0;
    if (scheduleDate.isAfter(today)) return 0.0;

    final start = _parseTime(schedule.lessons.first.startTime, schedule.date);
    final end = _parseTime(schedule.lessons.last.endTime, schedule.date);
    final totalSec = end.difference(start).inSeconds;
    if (totalSec <= 0) return 0.0;

    if (_now.isBefore(start)) return 0.0;
    if (_now.isAfter(end)) return 1.0;

    final passedSec = _now.difference(start).inSeconds;
    return (passedSec / totalSec).clamp(0.0, 1.0);
  }

  Lesson? getCurrentLesson(SchoolDaySchedule? schedule) {
    if (schedule == null || !isToday(schedule)) return null;
    for (final lesson in schedule.lessons) {
      final start = _parseTime(lesson.startTime, schedule.date);
      final end = _parseTime(lesson.endTime, schedule.date);
      if (_now.isAfter(start) && _now.isBefore(end)) {
        return lesson;
      }
    }
    return null;
  }

  Lesson? getNextLesson(SchoolDaySchedule? schedule) {
    if (schedule == null || !isToday(schedule)) return null;
    for (final lesson in schedule.lessons) {
      final start = _parseTime(lesson.startTime, schedule.date);
      if (_now.isBefore(start)) {
        return lesson;
      }
    }
    return null;
  }

  bool isDuringBreak(SchoolDaySchedule? schedule) {
    if (schedule == null || !isToday(schedule) || schedule.lessons.length < 2) return false;
    final firstStart = _parseTime(schedule.lessons.first.startTime, schedule.date);
    final lastEnd = _parseTime(schedule.lessons.last.endTime, schedule.date);
    if (_now.isBefore(firstStart) || _now.isAfter(lastEnd)) return false;

    return getCurrentLesson(schedule) == null;
  }

  Duration getNextBellCountdown(SchoolDaySchedule? schedule) {
    if (schedule == null || !isToday(schedule) || schedule.lessons.isEmpty) return Duration.zero;
    final current = getCurrentLesson(schedule);
    if (current != null) {
      final end = _parseTime(current.endTime, schedule.date);
      return end.isAfter(_now) ? end.difference(_now) : Duration.zero;
    }
    final next = getNextLesson(schedule);
    if (next != null) {
      final start = _parseTime(next.startTime, schedule.date);
      return start.isAfter(_now) ? start.difference(_now) : Duration.zero;
    }
    return Duration.zero;
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final hStr = hours > 0 ? '$hours ч ' : '';
    final mStr = '$minutes мин ';
    final sStr = '${seconds.toString().padLeft(2, '0')} сек';
    return '$hStr$mStr$sStr';
  }

  String formatDigital(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
