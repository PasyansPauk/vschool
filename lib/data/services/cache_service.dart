import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/school_day_schedule.dart';
import '../models/subject_summary.dart';
import '../models/homework_item.dart';

class CacheService {
  static const String _keyProfile = 'cache_user_profile';
  static const String _keySchedules = 'cache_schedules';
  static const String _keyGrades = 'cache_grades';
  static const String _keyHomework = 'cache_homework';
  static const String _keyLastSync = 'cache_last_sync';
  static const String _keyAuthToken = 'cache_auth_token';

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyProfile);
    if (data == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSchedules(List<SchoolDaySchedule> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_keySchedules, jsonEncode(jsonList));
  }

  Future<List<SchoolDaySchedule>?> getSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keySchedules);
    if (data == null) return null;
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list
          .map((e) => SchoolDaySchedule.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGrades(List<SubjectSummary> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_keyGrades, jsonEncode(jsonList));
  }

  Future<List<SubjectSummary>?> getGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyGrades);
    if (data == null) return null;
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list
          .map((e) => SubjectSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveHomeworks(List<HomeworkItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_keyHomework, jsonEncode(jsonList));
  }

  Future<List<HomeworkItem>?> getHomeworks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyHomework);
    if (data == null) return null;
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list
          .map((e) => HomeworkItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  Future<void> saveLastSync(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSync, time.toIso8601String());
  }

  Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyLastSync);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfile);
    await prefs.remove(_keySchedules);
    await prefs.remove(_keyGrades);
    await prefs.remove(_keyHomework);
    await prefs.remove(_keyLastSync);
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyCookies);
    await prefs.remove(_keyStudentId);
  }

  static const String _keyCookies = 'cache_cookies';
  static const String _keyStudentId = 'cache_student_id';

  Future<void> saveCookies(String cookies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCookies, cookies);
  }

  Future<String?> getCookies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCookies);
  }

  Future<void> saveStudentId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStudentId, id);
  }

  Future<String?> getStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStudentId);
  }
}
