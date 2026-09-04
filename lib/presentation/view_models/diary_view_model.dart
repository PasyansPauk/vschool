import 'package:flutter/foundation.dart';
import '../../data/models/school_day_schedule.dart';
import '../../data/models/subject_summary.dart';
import '../../data/models/homework_item.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/diary_repository.dart';
import '../../data/services/mes_api_service.dart';

class DiaryViewModel extends ChangeNotifier {
  final DiaryRepository _repository;

  DiaryViewModel({DiaryRepository? repository})
      : _repository = repository ?? DiaryRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _showVpnOrOfflineBanner = false;
  bool get showVpnOrOfflineBanner => _showVpnOrOfflineBanner;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _selectedDayIndex = 0;
  int get selectedDayIndex => _selectedDayIndex;

  DateTime _selectedWeekDate = DateTime.now();
  DateTime get selectedWeekDate => _selectedWeekDate;

  bool get isCurrentWeek {
    final now = DateTime.now();
    final monA = DateTime(_selectedWeekDate.year, _selectedWeekDate.month, _selectedWeekDate.day)
        .subtract(Duration(days: _selectedWeekDate.weekday - 1));
    final monB = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return monA.year == monB.year && monA.month == monB.month && monA.day == monB.day;
  }

  List<SchoolDaySchedule> _schedules = [];
  List<SchoolDaySchedule> get schedules => _schedules;

  SchoolDaySchedule? get currentDaySchedule {
    if (_schedules.isEmpty) return null;
    if (_selectedDayIndex < 0 || _selectedDayIndex >= _schedules.length) {
      return _schedules.first;
    }
    return _schedules[_selectedDayIndex];
  }

  /// Live schedule for today (used by SchoolTracker)
  SchoolDaySchedule? get todaySchedule {
    final now = DateTime.now();
    for (final s in _schedules) {
      if (s.date.year == now.year && s.date.month == now.month && s.date.day == now.day) {
        return s;
      }
    }
    return currentDaySchedule;
  }

  List<SubjectSummary> _grades = [];
  List<SubjectSummary> get grades => _grades;

  List<HomeworkItem> _homeworks = [];
  List<HomeworkItem> get homeworks => _homeworks;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  bool _isDarkTheme = true; // Default dark monochrome (Apple / One UI look)
  bool get isDarkTheme => _isDarkTheme;

  double get overallAverageScore {
    if (_grades.isEmpty) return 0.0;
    double sum = 0.0;
    int count = 0;
    for (final s in _grades) {
      final avg = s.averageScore;
      if (avg > 0) {
        sum += avg;
        count++;
      }
    }
    if (count == 0) return 0.0;
    return sum / count;
  }

  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
  }

  void selectDay(int index) {
    if (_selectedDayIndex != index) {
      _selectedDayIndex = index;
      notifyListeners();
    }
  }

  Future<void> nextWeek() async {
    _selectedWeekDate = _selectedWeekDate.add(const Duration(days: 7));
    _selectedDayIndex = 0; // Default to Monday of next week
    await loadScheduleForWeek();
  }

  Future<void> previousWeek() async {
    _selectedWeekDate = _selectedWeekDate.subtract(const Duration(days: 7));
    _selectedDayIndex = 0; // Default to Monday of previous week
    await loadScheduleForWeek();
  }

  Future<void> goToToday() async {
    _selectedWeekDate = DateTime.now();
    final weekday = DateTime.now().weekday;
    _selectedDayIndex = (weekday - 1).clamp(0, 6);
    await loadScheduleForWeek();
  }

  Future<void> loadScheduleForWeek() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _schedules = await _repository.getSchedules(
        targetDate: _selectedWeekDate,
        forceRefresh: true,
      );
    } catch (e) {
      // Keep existing schedules if fail
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void dismissErrorBanner() {
    _showVpnOrOfflineBanner = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    _isLoading = true;
    _showVpnOrOfflineBanner = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.getProfile();
      _schedules = await _repository.getSchedules(
        forceRefresh: forceRefresh,
        targetDate: _selectedWeekDate,
      );
      _grades = await _repository.getGrades(forceRefresh: forceRefresh);
      _homeworks = await _repository.getHomeworks(forceRefresh: forceRefresh);
      _lastSyncTime = await _repository.cacheService.getLastSync() ?? DateTime.now();

      // Select today's day of week (0 to 6)
      if (isCurrentWeek) {
        final weekday = DateTime.now().weekday;
        _selectedDayIndex = (weekday - 1).clamp(0, _schedules.isNotEmpty ? _schedules.length - 1 : 6);
      }

      if (_schedules.isEmpty && _grades.isEmpty && _profile == null) {
        _errorMessage =
            'Данные из МЭШ пока не загрузились. Проверьте интернет или обновите сессию Mos.ID.';
      }
    } on MesApiException catch (e) {
      _errorMessage = e.message;
      _showVpnOrOfflineBanner = true;
      // Load whatever is in cache
      final cachedSchedules = await _repository.cacheService.getSchedules();
      if (cachedSchedules != null && cachedSchedules.isNotEmpty) {
        _schedules = cachedSchedules;
      }
      final cachedGrades = await _repository.cacheService.getGrades();
      if (cachedGrades != null && cachedGrades.isNotEmpty) {
        _grades = cachedGrades;
      }
      final cachedHw = await _repository.cacheService.getHomeworks();
      if (cachedHw != null && cachedHw.isNotEmpty) {
        _homeworks = cachedHw;
      }
    } catch (e) {
      _errorMessage = 'Ошибка подключения к сети. Проверьте интернет или выключите VPN.';
      _showVpnOrOfflineBanner = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleHomework(String id) async {
    // Instant local memory update for snappy UI feel
    _homeworks = _homeworks.map((hw) {
      if (hw.id == id) {
        return hw.copyWith(isCompleted: !hw.isCompleted);
      }
      return hw;
    }).toList();
    notifyListeners();

    // Persist changes
    _homeworks = await _repository.toggleHomeworkCompletion(id);
    notifyListeners();
  }
}
