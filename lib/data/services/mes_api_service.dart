import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/school_day_schedule.dart';
import '../models/lesson.dart';
import '../models/grade_item.dart';
import '../models/subject_summary.dart';
import '../models/homework_item.dart';
import '../models/user_profile.dart';
import 'cache_service.dart';

class MesApiException implements Exception {
  final String message;
  final bool isVpnOrNetworkIssue;

  const MesApiException(this.message, {this.isVpnOrNetworkIssue = false});

  @override
  String toString() => message;
}

class MesApiService {
  final CacheService _cacheService;

  MesApiService({CacheService? cacheService})
      : _cacheService = cacheService ?? CacheService();

  static const String _meshBaseUrl = 'https://school.mos.ru/api/family/web/v1';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _cacheService.getAuthToken();
    final cookies = await _cacheService.getCookies();

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'x-mes-subsystem': 'familyweb',
      'User-Agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
    };

    if (token != null && token.isNotEmpty && !token.startsWith('mos_session_')) {
      headers['auth-token'] = token;
      headers['Authorization'] = 'Bearer $token';
    }
    if (cookies != null && cookies.isNotEmpty) {
      headers['Cookie'] = cookies;
    }

    return headers;
  }

  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('https://school.mos.ru'))
          .timeout(const Duration(seconds: 6));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the real student profile from official МЭШ
  Future<UserProfile?> fetchUserProfile() async {
    final token = await _cacheService.getAuthToken();
    final cookies = await _cacheService.getCookies();
    if ((token == null || token.isEmpty) && (cookies == null || cookies.isEmpty)) {
      return null;
    }

    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$_meshBaseUrl/profile'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final profile = UserProfile.fromMeshJson(data);
        if (profile.fullName.isNotEmpty || profile.className.isNotEmpty) {
          await _cacheService.saveProfile(profile);
          if (profile.id.isNotEmpty && profile.id != 'mesh_user') {
            await _cacheService.saveStudentId(profile.id);
          }
          return profile;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetches real schedules from official МЭШ API.
  Future<List<SchoolDaySchedule>> fetchSchedules() async {
    final token = await _cacheService.getAuthToken();
    final cookies = await _cacheService.getCookies();
    if ((token == null || token.isEmpty) && (cookies == null || cookies.isEmpty)) {
      return [];
    }

    String studentId = await _cacheService.getStudentId() ?? '';
    if (studentId.isEmpty || studentId == 'mesh_user') {
      final profile = await fetchUserProfile();
      if (profile != null && profile.id.isNotEmpty && profile.id != 'mesh_user') {
        studentId = profile.id;
      }
    }

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final friday = monday.add(const Duration(days: 4));
    final dateFormat = DateFormat('yyyy-MM-dd');

    try {
      final headers = await _getHeaders();
      final queryParam = studentId.isNotEmpty ? 'student_id=$studentId&' : '';
      final url = Uri.parse(
        '$_meshBaseUrl/schedule?${queryParam}begin_date=${dateFormat.format(monday)}&end_date=${dateFormat.format(friday)}',
      );

      final response =
          await http.get(url, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<SchoolDaySchedule> parsed = [];

        if (body is Map && body.containsKey('activities')) {
          final activities = body['activities'] as List<dynamic>;
          for (int i = 0; i < 5; i++) {
            final dayDate = monday.add(Duration(days: i));
            final dayStr = dateFormat.format(dayDate);
            final dayLessons = <Lesson>[];

            for (final act in activities) {
              if (act is Map && act['date'] == dayStr) {
                final numVal =
                    (act['lesson_number'] as num?)?.toInt() ?? (dayLessons.length + 1);
                dayLessons.add(Lesson(
                  number: numVal,
                  subject: (act['subject_name'] ?? act['title'] ?? 'Урок').toString(),
                  room: (act['room_number'] ?? act['room'] ?? '').toString(),
                  teacher: (act['teacher_name'] ?? '').toString(),
                  startTime: (act['begin_time'] ?? '08:30').toString(),
                  endTime: (act['end_time'] ?? '09:15').toString(),
                  topic: (act['lesson_topic'] ?? act['topic'] ?? '').toString(),
                  homework: act['homework']?.toString(),
                ));
              }
            }

            dayLessons.sort((a, b) => a.number.compareTo(b.number));

            parsed.add(SchoolDaySchedule(
              date: dayDate,
              dayName: _dayName(dayDate.weekday),
              lessons: dayLessons,
            ));
          }
          return parsed;
        }
      }
    } catch (_) {}

    return [];
  }

  /// Fetches real subject grades from official МЭШ.
  Future<List<SubjectSummary>> fetchGrades() async {
    final token = await _cacheService.getAuthToken();
    final cookies = await _cacheService.getCookies();
    if ((token == null || token.isEmpty) && (cookies == null || cookies.isEmpty)) {
      return [];
    }

    String studentId = await _cacheService.getStudentId() ?? '';
    if (studentId.isEmpty || studentId == 'mesh_user') {
      final profile = await fetchUserProfile();
      if (profile != null && profile.id.isNotEmpty && profile.id != 'mesh_user') {
        studentId = profile.id;
      }
    }

    try {
      final headers = await _getHeaders();
      final queryParam = studentId.isNotEmpty ? '?student_id=$studentId' : '';
      final url = Uri.parse('$_meshBaseUrl/subject_marks$queryParam');
      final response =
          await http.get(url, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<SubjectSummary> result = [];

        if (body is Map && body.containsKey('payload')) {
          final payload = body['payload'] as List<dynamic>;
          for (final item in payload) {
            if (item is Map) {
              final subjectName = (item['subject_name'] ?? '').toString();
              final teacher = (item['teacher_name'] ?? '').toString();
              final marksRaw = (item['marks'] as List<dynamic>?) ?? [];

              final gradeItems = <GradeItem>[];
              for (final m in marksRaw) {
                if (m is Map) {
                  final val = int.tryParse((m['value'] ?? '').toString()) ?? 0;
                  final weight = int.tryParse((m['weight'] ?? '1').toString()) ?? 1;
                  final dateStr = (m['date'] ?? '').toString();
                  final date = DateTime.tryParse(dateStr) ?? DateTime.now();

                  if (val > 0) {
                    gradeItems.add(GradeItem(
                      id: (m['id'] ?? '').toString(),
                      subject: subjectName,
                      value: val,
                      weight: weight,
                      date: date,
                      topic: (m['topic'] ?? '').toString(),
                    ));
                  }
                }
              }

              if (subjectName.isNotEmpty) {
                result.add(SubjectSummary(
                  subject: subjectName,
                  teacher: teacher,
                  grades: gradeItems,
                ));
              }
            }
          }
          return result;
        }
      }
    } catch (_) {}

    return [];
  }

  /// Fetches real homework assignments from official МЭШ.
  Future<List<HomeworkItem>> fetchHomeworks() async {
    final token = await _cacheService.getAuthToken();
    final cookies = await _cacheService.getCookies();
    if ((token == null || token.isEmpty) && (cookies == null || cookies.isEmpty)) {
      return [];
    }

    String studentId = await _cacheService.getStudentId() ?? '';
    if (studentId.isEmpty || studentId == 'mesh_user') {
      final profile = await fetchUserProfile();
      if (profile != null && profile.id.isNotEmpty && profile.id != 'mesh_user') {
        studentId = profile.id;
      }
    }

    try {
      final headers = await _getHeaders();
      final queryParam = studentId.isNotEmpty ? '?student_id=$studentId' : '';
      final url = Uri.parse('$_meshBaseUrl/homeworks$queryParam');
      final response =
          await http.get(url, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<HomeworkItem> result = [];

        if (body is Map && body.containsKey('payload')) {
          final payload = body['payload'] as List<dynamic>;
          for (final hw in payload) {
            if (hw is Map) {
              final dateStr = (hw['date'] ?? '').toString();
              final date = DateTime.tryParse(dateStr) ?? DateTime.now();

              result.add(HomeworkItem(
                id: (hw['id'] ?? '').toString(),
                subject: (hw['subject_name'] ?? 'Предмет').toString(),
                description: (hw['description'] ?? hw['task'] ?? '').toString(),
                dueDate: date,
                isCompleted: hw['is_done'] == true,
                attachmentsCount:
                    (hw['materials'] as List<dynamic>?)?.length ?? 0,
              ));
            }
          }
          return result;
        }
      }
    } catch (_) {}

    return [];
  }

  Future<void> saveImportedBundle(Map<String, dynamic> bundle) async {
    // 1. Profile
    if (bundle.containsKey('profile') && bundle['profile'] != null) {
      try {
        final profileData = bundle['profile'];
        if (profileData is Map<String, dynamic>) {
          final profile = UserProfile.fromMeshJson(profileData);
          if (profile.fullName.isNotEmpty || profile.className.isNotEmpty) {
            await _cacheService.saveProfile(profile);
            if (profile.id.isNotEmpty && profile.id != 'mesh_user') {
              await _cacheService.saveStudentId(profile.id);
            }
          }
        }
      } catch (_) {}
    } else if (bundle.containsKey('studentName') &&
        bundle['studentName'] != null &&
        (bundle['studentName'] as String).isNotEmpty) {
      try {
        final domProfile = UserProfile(
          id: (bundle['studentId'] ?? 'mesh_user').toString(),
          fullName: bundle['studentName'] as String,
          className: (bundle['className'] ?? '').toString(),
          schoolName: (bundle['schoolName'] ?? '').toString(),
          snils: '',
          mosId: 'Mos.ID',
          canteenBalance: 0.0,
          isMosIdLinked: true,
        );
        await _cacheService.saveProfile(domProfile);
        if (domProfile.id.isNotEmpty && domProfile.id != 'mesh_user') {
          await _cacheService.saveStudentId(domProfile.id);
        }
      } catch (_) {}
    }

    // 2. Schedule
    if (bundle.containsKey('schedules') && bundle['schedules'] != null) {
      try {
        final schedData = bundle['schedules'];
        if (schedData is Map && schedData.containsKey('activities')) {
          final activities = schedData['activities'] as List<dynamic>;
          final now = DateTime.now();
          final monday = now.subtract(Duration(days: now.weekday - 1));
          final dateFormat = DateFormat('yyyy-MM-dd');
          final List<SchoolDaySchedule> parsed = [];

          for (int i = 0; i < 5; i++) {
            final dayDate = monday.add(Duration(days: i));
            final dayStr = dateFormat.format(dayDate);
            final dayLessons = <Lesson>[];

            for (final act in activities) {
              if (act is Map && act['date'] == dayStr) {
                final numVal =
                    (act['lesson_number'] as num?)?.toInt() ?? (dayLessons.length + 1);
                dayLessons.add(Lesson(
                  number: numVal,
                  subject: (act['subject_name'] ?? act['title'] ?? 'Урок').toString(),
                  room: (act['room_number'] ?? act['room'] ?? '').toString(),
                  teacher: (act['teacher_name'] ?? '').toString(),
                  startTime: (act['begin_time'] ?? '08:30').toString(),
                  endTime: (act['end_time'] ?? '09:15').toString(),
                  topic: (act['lesson_topic'] ?? act['topic'] ?? '').toString(),
                  homework: act['homework']?.toString(),
                ));
              }
            }
            dayLessons.sort((a, b) => a.number.compareTo(b.number));
            parsed.add(SchoolDaySchedule(
              date: dayDate,
              dayName: _dayName(dayDate.weekday),
              lessons: dayLessons,
            ));
          }
          if (parsed.isNotEmpty) {
            await _cacheService.saveSchedules(parsed);
          }
        }
      } catch (_) {}
    }

    // 2b. Scraped DOM Lessons
    if (bundle.containsKey('domLessons') &&
        bundle['domLessons'] is List &&
        (bundle['domLessons'] as List).isNotEmpty) {
      try {
        final domList = bundle['domLessons'] as List<dynamic>;
        final now = DateTime.now();
        final dayLessons = <Lesson>[];
        for (int i = 0; i < domList.length; i++) {
          final item = domList[i];
          if (item is Map) {
            final subj = (item['subject'] ?? '').toString().trim();
            if (subj.isNotEmpty) {
              dayLessons.add(Lesson(
                number: i + 1,
                subject: subj,
                startTime: (item['startTime'] ?? '08:30').toString(),
                endTime: (item['endTime'] ?? '09:15').toString(),
                room: (item['room'] ?? '').toString(),
                teacher: (item['teacher'] ?? '').toString(),
                topic: (item['topic'] ?? '').toString(),
              ));
            }
          }
        }
        if (dayLessons.isNotEmpty) {
          final existing = await _cacheService.getSchedules() ?? [];
          final todaySchedule = SchoolDaySchedule(
            date: now,
            dayName: _dayName(now.weekday),
            lessons: dayLessons,
          );
          final updated = [todaySchedule];
          for (final s in existing) {
            if (s.dayName != todaySchedule.dayName) updated.add(s);
          }
          await _cacheService.saveSchedules(updated);
        }
      } catch (_) {}
    }

    // 3. Marks / Grades
    if (bundle.containsKey('marks') && bundle['marks'] != null) {
      try {
        final marksData = bundle['marks'];
        if (marksData is Map && marksData.containsKey('payload')) {
          final payload = marksData['payload'] as List<dynamic>;
          final List<SubjectSummary> result = [];
          for (final item in payload) {
            if (item is Map) {
              final subjectName = (item['subject_name'] ?? '').toString();
              final teacher = (item['teacher_name'] ?? '').toString();
              final marksRaw = (item['marks'] as List<dynamic>?) ?? [];
              final gradeItems = <GradeItem>[];
              for (final m in marksRaw) {
                if (m is Map) {
                  final val = int.tryParse((m['value'] ?? '').toString()) ?? 0;
                  final weight = int.tryParse((m['weight'] ?? '1').toString()) ?? 1;
                  final date =
                      DateTime.tryParse((m['date'] ?? '').toString()) ?? DateTime.now();
                  if (val > 0) {
                    gradeItems.add(GradeItem(
                      id: (m['id'] ?? '').toString(),
                      subject: subjectName,
                      value: val,
                      weight: weight,
                      date: date,
                      topic: (m['topic'] ?? '').toString(),
                    ));
                  }
                }
              }
              if (subjectName.isNotEmpty) {
                result.add(SubjectSummary(
                    subject: subjectName, teacher: teacher, grades: gradeItems));
              }
            }
          }
          if (result.isNotEmpty) {
            await _cacheService.saveGrades(result);
          }
        }
      } catch (_) {}
    }

    // 4. Homeworks
    if (bundle.containsKey('homeworks') && bundle['homeworks'] != null) {
      try {
        final hwData = bundle['homeworks'];
        if (hwData is Map && hwData.containsKey('payload')) {
          final payload = hwData['payload'] as List<dynamic>;
          final List<HomeworkItem> result = [];
          for (final hw in payload) {
            if (hw is Map) {
              result.add(HomeworkItem(
                id: (hw['id'] ?? '').toString(),
                subject: (hw['subject_name'] ?? 'Предмет').toString(),
                description: (hw['description'] ?? hw['task'] ?? '').toString(),
                dueDate:
                    DateTime.tryParse((hw['date'] ?? '').toString()) ?? DateTime.now(),
                isCompleted: hw['is_done'] == true,
                attachmentsCount:
                    (hw['materials'] as List<dynamic>?)?.length ?? 0,
              ));
            }
          }
          if (result.isNotEmpty) {
            await _cacheService.saveHomeworks(result);
          }
        }
      } catch (_) {}
    }

    await _cacheService.saveLastSync(DateTime.now());
  }

  String _dayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Понедельник';
      case DateTime.tuesday:
        return 'Вторник';
      case DateTime.wednesday:
        return 'Среда';
      case DateTime.thursday:
        return 'Четверг';
      case DateTime.friday:
        return 'Пятница';
      case DateTime.saturday:
        return 'Суббота';
      case DateTime.sunday:
        return 'Воскресенье';
      default:
        return '';
    }
  }
}
