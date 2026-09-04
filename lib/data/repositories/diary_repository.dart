import '../models/lesson.dart';
import '../models/school_day_schedule.dart';
import '../models/subject_summary.dart';
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

  Future<List<SchoolDaySchedule>> getSchedules({
    bool forceRefresh = false,
    DateTime? targetDate,
  }) async {
    final isCurrentWeek = targetDate == null || _isSameWeek(targetDate, DateTime.now());
    var cached = isCurrentWeek ? await _cacheService.getSchedules() : null;

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
    }

    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final fresh = await _apiService.fetchSchedules(forDate: targetDate);
      if (fresh.isNotEmpty) {
        if (isCurrentWeek) {
          await _cacheService.saveSchedules(fresh);
          await _cacheService.saveLastSync(DateTime.now());
        }
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

  bool _isSameWeek(DateTime a, DateTime b) {
    final monA = DateTime(a.year, a.month, a.day).subtract(Duration(days: a.weekday - 1));
    final monB = DateTime(b.year, b.month, b.day).subtract(Duration(days: b.weekday - 1));
    return monA.year == monB.year && monA.month == monB.month && monA.day == monB.day;
  }

  Future<List<SubjectSummary>> getGrades({bool forceRefresh = false}) async {
    final cached = await _cacheService.getGrades();

    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final fresh = await _apiService.fetchGrades();
      if (fresh.isNotEmpty) {
        await _cacheService.saveGrades(fresh);
        return fresh;
      }
      return cached ?? [];
    } catch (_) {
      return cached ?? [];
    }
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
