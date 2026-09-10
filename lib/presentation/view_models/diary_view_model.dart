import 'package:flutter/foundation.dart';
import '../../data/models/school_day_schedule.dart';
import '../../data/models/subject_summary.dart';
import '../../data/models/grade_item.dart';
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

  bool _isFirstLoad = true;

  bool _showVpnOrOfflineBanner = false;
  bool get showVpnOrOfflineBanner => _showVpnOrOfflineBanner;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _selectedDayIndex = 0;
  int get selectedDayIndex => _selectedDayIndex;

  DateTime _selectedWeekDate = DateTime.now();
  DateTime get selectedWeekDate => _selectedWeekDate;

  /// Direction of last week switch: 1 = forward (next), -1 = backward (prev), 0 = none
  int _weekSwitchDirection = 0;
  int get weekSwitchDirection => _weekSwitchDirection;

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

  bool get isScheduleMatchingSelectedWeek {
    if (_schedules.isEmpty) return false;
    final schedMonday = _schedules.first.date.subtract(Duration(days: _schedules.first.date.weekday - 1));
    final selMonday = _selectedWeekDate.subtract(Duration(days: _selectedWeekDate.weekday - 1));
    return schedMonday.year == selMonday.year &&
           schedMonday.month == selMonday.month &&
           schedMonday.day == selMonday.day;
  }

  SchoolDaySchedule? get currentDaySchedule {
    if (_schedules.isEmpty || !isScheduleMatchingSelectedWeek) return null;
    final targetWeekday = _selectedDayIndex + 1;
    for (final s in _schedules) {
      if (s.date.weekday == targetWeekday) {
        return s;
      }
    }
    return null; // Нет занятий в этот день
  }

  /// Live schedule for today (used by SchoolTracker)
  SchoolDaySchedule? get todaySchedule {
    final now = DateTime.now();
    for (final s in _schedules) {
      if (s.date.year == now.year && s.date.month == now.month && s.date.day == now.day) {
        return s;
      }
    }
    return null;
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
    _weekSwitchDirection = 1;
    _selectedWeekDate = _selectedWeekDate.add(const Duration(days: 7));
    _selectedDayIndex = 0; // Default to Monday of next week
    await loadScheduleForWeek();
  }

  Future<void> previousWeek() async {
    _weekSwitchDirection = -1;
    _selectedWeekDate = _selectedWeekDate.subtract(const Duration(days: 7));
    _selectedDayIndex = 0; // Default to Monday of previous week
    await loadScheduleForWeek();
  }

  Future<void> goToToday() async {
    _weekSwitchDirection = 0;
    _selectedWeekDate = DateTime.now();
    final weekday = DateTime.now().weekday;
    _selectedDayIndex = (weekday - 1).clamp(0, 6);
    await loadScheduleForWeek();
  }

  Future<void> loadScheduleForWeek() async {
    _errorMessage = null;

    final cached = _repository.getCachedWeek(_selectedWeekDate);
    if (cached != null && cached.isNotEmpty) {
      _schedules = cached;
      _mergeScheduleGradesIntoGrades();
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Мгновенно уведомляем UI о начале загрузки — нет зависания
    _isLoading = true;
    notifyListeners();

    try {
      _schedules = await _repository.getSchedules(
        targetDate: _selectedWeekDate,
        forceRefresh: false,
      );
      _mergeScheduleGradesIntoGrades();
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
      _mergeScheduleGradesIntoGrades();
      _homeworks = await _repository.getHomeworks(forceRefresh: forceRefresh);
      _lastSyncTime = await _repository.cacheService.getLastSync() ?? DateTime.now();

      // Select today's day of week (0 to 6) only on initial load
      if (isCurrentWeek && _isFirstLoad) {
        final weekday = DateTime.now().weekday;
        _selectedDayIndex = (weekday - 1).clamp(0, 6);
        _isFirstLoad = false;
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
      _mergeScheduleGradesIntoGrades();
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

  void _mergeScheduleGradesIntoGrades() {
    if (_schedules.isEmpty) return;

    bool modified = false;
    final map = <String, SubjectSummary>{};
    for (final s in _grades) {
      map[s.subject.trim().toLowerCase()] = s;
    }

    for (final day in _schedules) {
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
              modified = true;
            }
          } else {
            map[subjKey] = SubjectSummary(
              subject: lesson.subject.trim(),
              teacher: lesson.teacher,
              grades: [g],
            );
            modified = true;
          }
        }
      }
    }

    final list = map.values.toList();
    list.sort((a, b) {
      if (a.grades.isNotEmpty && b.grades.isEmpty) return -1;
      if (a.grades.isEmpty && b.grades.isNotEmpty) return 1;
      if (a.grades.length != b.grades.length) {
        return b.grades.length.compareTo(a.grades.length);
      }
      return a.subject.compareTo(b.subject);
    });

    _grades = list;
    if (modified) {
      _repository.cacheService.saveGrades(_grades);
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
