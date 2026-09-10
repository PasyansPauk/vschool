import '../models/lesson.dart';
import '../models/school_day_schedule.dart';
import '../models/subject_summary.dart';
import '../models/grade_item.dart';
import '../models/homework_item.dart';
import '../models/user_profile.dart';
import '../services/cache_service.dart';
import '../services/mes_api_service.dart';

class DiaryRepository {
  final CacheService _cacheService;
  final MesApiService _apiService;

  DiaryRepository({
    CacheService? cacheService,
    MesApiService? apiService,
  })  : _cacheService = cacheService ?? CacheService(),
        _apiService = apiService ??
            MesApiService(cacheService: cacheService ?? CacheService());

  MesApiService get apiService => _apiService;
  CacheService get cacheService => _cacheService;

  Future<UserProfile?> getProfile() async {
    final cached = await _cacheService.getProfile();
    if (cached != null) return cached;

    // Fetch from real МЭШ API
    final fresh = await _apiService.fetchUserProfile();
    return fresh;
  }

  final Map<String, List<SchoolDaySchedule>> _weekMemoryCache = {};

  String _getWeekKey(DateTime date) {
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
    return '${monday.year}_${monday.month}_${monday.day}';
  }

  List<SchoolDaySchedule>? getCachedWeek(DateTime date) {
    return _weekMemoryCache[_getWeekKey(date)];
  }

  Future<List<SchoolDaySchedule>> getSchedules({
    bool forceRefresh = false,
    DateTime? targetDate,
  }) async {
    final target = targetDate ?? DateTime.now();
    final weekKey = _getWeekKey(target);

    if (!forceRefresh && _weekMemoryCache.containsKey(weekKey)) {
      return _weekMemoryCache[weekKey]!;
    }

    // Always try to read from cache
    var cached = await _cacheService.getSchedules();

    if (cached != null) {
      final sanitized = <SchoolDaySchedule>[];
      for (final day in cached) {
        final realLessons = <Lesson>[];
        final dayBreaks = <ScheduleBreak>[...day.breaks];
        for (final l in day.lessons) {
          if (SchoolDaySchedule.isBreakSubject(l.subject)) {
            dayBreaks.add(ScheduleBreak(
              name: l.subject.isNotEmpty ? l.subject : 'Перемена',
              startTime: l.startTime,
              endTime: l.endTime,
              durationMinutes: SchoolDaySchedule.calcMins(l.startTime, l.endTime),
            ));
          } else {
            realLessons.add(l);
          }
        }
        for (int k = 0; k < realLessons.length; k++) {
          realLessons[k] = realLessons[k].copyWith(number: k + 1);
        }
        dayBreaks.sort((a, b) => a.startTime.compareTo(b.startTime));
        sanitized.add(SchoolDaySchedule(
          date: day.date,
          dayName: day.dayName,
          lessons: realLessons,
          breaks: dayBreaks,
        ));
      }
      cached = sanitized;
      if (cached.isNotEmpty) {
        _weekMemoryCache[_getWeekKey(cached.first.date)] = cached;
      }
    }

    if (!forceRefresh && _weekMemoryCache.containsKey(weekKey)) {
      return _weekMemoryCache[weekKey]!;
    }

    try {
      final fresh = await _apiService.fetchSchedules(forDate: targetDate);
      if (fresh.isNotEmpty) {
        _weekMemoryCache[weekKey] = fresh;
        await _cacheService.saveSchedules(fresh);
        await _cacheService.saveLastSync(DateTime.now());
        return fresh;
      }
      return cached ?? [];
    } on MesApiException {
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    } catch (_) {
      return cached ?? [];
    }
  }

  Future<List<SubjectSummary>> getGrades({bool forceRefresh = false}) async {
    final cached = await _cacheService.getGrades();
    final hasAnyGrades = cached != null && cached.any((s) => s.grades.isNotEmpty);

    if (!forceRefresh && hasAnyGrades) {
      return await _mergeWithScheduleGrades(cached);
    }

    try {
      final fresh = await _apiService.fetchGrades();
      if (fresh.isNotEmpty) {
        final merged = await _mergeWithScheduleGrades(fresh);
        await _cacheService.saveGrades(merged);
        return merged;
      }
      if (cached != null && cached.isNotEmpty) {
        final merged = await _mergeWithScheduleGrades(cached);
        await _cacheService.saveGrades(merged);
        return merged;
      }
      final scheduleOnly = await _mergeWithScheduleGrades([]);
      if (scheduleOnly.isNotEmpty) {
        await _cacheService.saveGrades(scheduleOnly);
        return scheduleOnly;
      }
      return cached ?? [];
    } catch (_) {
      if (cached != null && cached.isNotEmpty) {
        return await _mergeWithScheduleGrades(cached);
      }
      return await _mergeWithScheduleGrades([]);
    }
  }

  Future<List<SubjectSummary>> _mergeWithScheduleGrades(List<SubjectSummary> base) async {
    final schedules = await _cacheService.getSchedules();
    if (schedules == null || schedules.isEmpty) return base;

    final map = <String, SubjectSummary>{};
    for (final s in base) {
      map[s.subject.trim().toLowerCase()] = s;
    }

    for (final day in schedules) {
      for (final lesson in day.lessons) {
        final g = lesson.grade;
        if (g != null && g.value > 0) {
          final subjKey = lesson.subject.trim().toLowerCase();
          if (subjKey.isEmpty) continue;

          final existing = map[subjKey];
          if (existing != null) {
            final alreadyHas = existing.grades.any((item) =>
                (item.id.isNotEmpty && item.id == g.id) ||
                (item.value == g.value &&
                    item.date.year == g.date.year &&
                    item.date.month == g.date.month &&
                    item.date.day == g.date.day));
            if (!alreadyHas) {
              map[subjKey] = existing.copyWith(
                grades: List<GradeItem>.from(existing.grades)..add(g),
              );
            }
          } else {
            map[subjKey] = SubjectSummary(
              subject: lesson.subject.trim(),
              teacher: lesson.teacher,
              grades: [g],
            );
          }
        }
      }
    }

    final result = map.values.toList();
    result.sort((a, b) {
      if (a.grades.isNotEmpty && b.grades.isEmpty) return -1;
      if (a.grades.isEmpty && b.grades.isNotEmpty) return 1;
      if (a.grades.length != b.grades.length) {
        return b.grades.length.compareTo(a.grades.length);
      }
      return a.subject.compareTo(b.subject);
    });

    return result;
  }

  Future<List<HomeworkItem>> getHomeworks({bool forceRefresh = false}) async {
    final cached = await _cacheService.getHomeworks();

    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final fresh = await _apiService.fetchHomeworks();
      if (fresh.isNotEmpty) {
        await _cacheService.saveHomeworks(fresh);
        return fresh;
      }
      return cached ?? [];
    } catch (_) {
      return cached ?? [];
    }
  }

  Future<List<HomeworkItem>> toggleHomeworkCompletion(String id) async {
    final current = await _cacheService.getHomeworks() ?? [];
    final updated = current.map((hw) {
      if (hw.id == id) {
        return hw.copyWith(isCompleted: !hw.isCompleted);
      }
      return hw;
    }).toList();

    await _cacheService.saveHomeworks(updated);
    return updated;
  }
}
