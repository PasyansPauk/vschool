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

  List<SchoolDaySchedule> _schedules = [];
  List<SchoolDaySchedule> get schedules => _schedules;

  SchoolDaySchedule? get currentDaySchedule {
    if (_schedules.isEmpty) return null;
    if (_selectedDayIndex < 0 || _selectedDayIndex >= _schedules.length) {
      return _schedules.first;
    }
    return _schedules[_selectedDayIndex];
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
      _schedules = await _repository.getSchedules(forceRefresh: forceRefresh);
      _grades = await _repository.getGrades(forceRefresh: forceRefresh);
      _homeworks = await _repository.getHomeworks(forceRefresh: forceRefresh);
      _lastSyncTime = await _repository.cacheService.getLastSync() ?? DateTime.now();

      // Select today's day of week if within Monday-Friday (1-5)
      final weekday = DateTime.now().weekday;
      if (weekday >= 1 && weekday <= 5 && _schedules.isNotEmpty) {
        _selectedDayIndex = (weekday - 1).clamp(0, _schedules.length - 1);
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
    _homeworks = await _repository.toggleHomeworkCompletion(id);
    notifyListeners();
  }
}
