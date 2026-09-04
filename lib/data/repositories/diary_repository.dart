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
        _apiService = apiService ?? MesApiService();

  MesApiService get apiService => _apiService;
  CacheService get cacheService => _cacheService;

  Future<UserProfile?> getProfile() async {
    final cached = await _cacheService.getProfile();
    if (cached != null) return cached;
    final fallback = UserProfile.sample();
    await _cacheService.saveProfile(fallback);
    return fallback;
  }

  Future<List<SchoolDaySchedule>> getSchedules({bool forceRefresh = false}) async {
    final cached = await _cacheService.getSchedules();

    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final fresh = await _apiService.fetchSchedules();
      await _cacheService.saveSchedules(fresh);
      await _cacheService.saveLastSync(DateTime.now());
      return fresh;
    } on MesApiException {
      if (cached != null && cached.isNotEmpty) {
        // Re-throw so caller can display the VPN/offline banner,
        // while caller can still use the cached list.
        rethrow;
      }
      // If nothing in cache, provide initial offline fallback and throw
      final fallback = await _apiService.fetchSchedules();
      await _cacheService.saveSchedules(fallback);
      rethrow;
    } catch (_) {
      if (cached != null && cached.isNotEmpty) {
        throw const MesApiException(
          'Не удалось подключиться. Проверьте интернет или выключите VPN.',
          isVpnOrNetworkIssue: true,
        );
      }
      final fallback = await _apiService.fetchSchedules();
      await _cacheService.saveSchedules(fallback);
      return fallback;
    }
  }

  Future<List<SubjectSummary>> getGrades({bool forceRefresh = false}) async {
    final cached = await _cacheService.getGrades();

    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final fresh = await _apiService.fetchGrades();
      await _cacheService.saveGrades(fresh);
      return fresh;
    } catch (_) {
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      final fallback = await _apiService.fetchGrades();
      await _cacheService.saveGrades(fallback);
      return fallback;
    }
  }

  Future<List<HomeworkItem>> getHomeworks({bool forceRefresh = false}) async {
    final cached = await _cacheService.getHomeworks();

    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final fresh = await _apiService.fetchHomeworks();
      await _cacheService.saveHomeworks(fresh);
      return fresh;
    } catch (_) {
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      final fallback = await _apiService.fetchHomeworks();
      await _cacheService.saveHomeworks(fallback);
      return fallback;
    }
  }

  Future<List<HomeworkItem>> toggleHomeworkCompletion(String id) async {
    final list = await getHomeworks();
    final updated = list.map((item) {
      if (item.id == id) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    await _cacheService.saveHomeworks(updated);
    return updated;
  }
}
