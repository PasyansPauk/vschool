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

  Future<List<SchoolDaySchedule>> getSchedules({bool forceRefresh = false}) async {
    final cached = await _cacheService.getSchedules();

    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final fresh = await _apiService.fetchSchedules();
      if (fresh.isNotEmpty) {
        await _cacheService.saveSchedules(fresh);
        await _cacheService.saveLastSync(DateTime.now());
        return fresh;
      }
      return cached ?? [];
    } on MesApiException {
      if (cached != null && cached.isNotEmpty) {
        rethrow;
      }
      return [];
    } catch (_) {
      return cached ?? [];
    }
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
