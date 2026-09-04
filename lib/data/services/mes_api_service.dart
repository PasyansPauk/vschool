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
    final studentId = await _cacheService.getStudentId();

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'x-mes-subsystem': 'familyweb',
      'User-Agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
    };

    if (token != null &&
        token.isNotEmpty &&
        !token.contains('authenticated') &&
        !token.contains('session')) {
      headers['Auth-Token'] = token;
      headers['auth-token'] = token;
    }
    if (studentId != null && studentId.isNotEmpty && studentId != 'mesh_user') {
      headers['Profile-Id'] = studentId;
      headers['profile-id'] = studentId;
    }
    if (cookies != null && cookies.isNotEmpty) {
      headers['Cookie'] = cookies;
    }

    return headers;
  }

  /// Fetches the student profile from МЭШ API.
  Future<UserProfile?> fetchUserProfile() async {
    final token = await _cacheService.getAuthToken();
    final cookies = await _cacheService.getCookies();
    if ((token == null || token.isEmpty) && (cookies == null || cookies.isEmpty)) {
      return null;
    }

    final headers = await _getHeaders();
    final studentId = await _cacheService.getStudentId() ?? '';

    final candidateUrls = [
      Uri.parse('$_meshBaseUrl/profile'),
      if (studentId.isNotEmpty && studentId != 'mesh_user')
        Uri.parse('https://dnevnik.mos.ru/core/api/student_profiles/$studentId'),
      Uri.parse('https://dnevnik.mos.ru/core/api/student_profiles'),
      Uri.parse('https://school.mos.ru/api/family/mobile/v1/profile'),
      Uri.parse('https://dnevnik.mos.ru/mobile/api/profile'),
    ];

    for (final url in candidateUrls) {
      try {
        final response =
            await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final profile = UserProfile.fromMeshJson(decoded);
            if (profile.fullName.isNotEmpty || profile.className.isNotEmpty) {
              await _cacheService.saveProfile(profile);
              if (profile.id.isNotEmpty && profile.id != 'mesh_user') {
                await _cacheService.saveStudentId(profile.id);
              }
              return profile;
            }
          } else if (decoded is List && decoded.isNotEmpty) {
            final first = decoded.first;
            if (first is Map<String, dynamic>) {
              final profile = UserProfile.fromMeshJson(first);
              if (profile.fullName.isNotEmpty || profile.className.isNotEmpty) {
                await _cacheService.saveProfile(profile);
                if (profile.id.isNotEmpty && profile.id != 'mesh_user') {
                  await _cacheService.saveStudentId(profile.id);
                }
                return profile;
              }
            }
          }
        }
      } catch (_) {}
    }

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
    final beginStr = dateFormat.format(monday);
    final endStr = dateFormat.format(friday);

    final headers = await _getHeaders();
    final queryParam = studentId.isNotEmpty && studentId != 'mesh_user'
        ? 'student_id=$studentId&'
        : '';

    final candidateUrls = [
      Uri.parse(
          '$_meshBaseUrl/schedule?${queryParam}begin_date=$beginStr&end_date=$endStr'),
      Uri.parse(
          'https://school.mos.ru/api/family/mobile/v1/schedule?${queryParam}begin_date=$beginStr&end_date=$endStr'),
    ];

    for (final url in candidateUrls) {
      try {
        final response =
            await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final List<SchoolDaySchedule> parsed = [];

          dynamic activities;
          if (body is Map) {
            activities = body['activities'] ?? body['payload'] ?? body['lessons'];
          } else if (body is List) {
            activities = body;
          }

          if (activities is List && activities.isNotEmpty) {
            for (int i = 0; i < 5; i++) {
              final dayDate = monday.add(Duration(days: i));
              final dayStr = dateFormat.format(dayDate);
              final dayLessons = <Lesson>[];

              for (final act in activities) {
                if (act is Map && (act['date'] == dayStr || act['lesson_date'] == dayStr)) {
                  final numVal = (act['lesson_number'] as num?)?.toInt() ??
                      (act['number'] as num?)?.toInt() ??
                      (dayLessons.length + 1);

                  String hwDesc = '';
                  final rawHw = act['homework'] ?? act['homeworks'];
                  if (rawHw is String) {
                    hwDesc = rawHw;
                  } else if (rawHw is List && rawHw.isNotEmpty) {
                    final h0 = rawHw.first;
                    if (h0 is Map) {
                      hwDesc = (h0['description'] ?? h0['task'] ?? '').toString();
                    } else {
                      hwDesc = h0.toString();
                    }
                  } else if (rawHw is Map) {
                    hwDesc = (rawHw['description'] ?? rawHw['task'] ?? '').toString();
                  }

                  GradeItem? gradeItem;
                  final rawGrade = act['mark'] ?? act['grade'];
                  if (rawGrade is Map) {
                    final val = int.tryParse((rawGrade['value'] ?? '').toString()) ?? 0;
                    if (val > 0) {
                      gradeItem = GradeItem(
                        id: (rawGrade['id'] ?? '').toString(),
                        subject: (act['subject_name'] ?? act['title'] ?? '').toString(),
                        value: val,
                        weight: int.tryParse((rawGrade['weight'] ?? '1').toString()) ?? 1,
                        date: dayDate,
                        topic: (act['lesson_topic'] ?? act['topic'] ?? '').toString(),
                      );
                    }
                  }

                  dayLessons.add(Lesson(
                    number: numVal,
                    subject: (act['subject_name'] ?? act['title'] ?? 'Урок').toString(),
                    room: (act['room_number'] ?? act['room'] ?? '').toString(),
                    teacher: (act['teacher_name'] ?? act['teacher'] ?? '').toString(),
                    startTime: (act['begin_time'] ?? '08:30').toString(),
                    endTime: (act['end_time'] ?? '09:15').toString(),
                    topic: (act['lesson_topic'] ?? act['topic'] ?? '').toString(),
                    homework: hwDesc.isNotEmpty ? hwDesc : null,
                    grade: gradeItem,
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

            if (parsed.any((s) => s.lessons.isNotEmpty)) {
              await _cacheService.saveSchedules(parsed);
              return parsed;
            }
          }
        }
      } catch (_) {}
    }

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

    final headers = await _getHeaders();
    final queryParam = studentId.isNotEmpty && studentId != 'mesh_user'
        ? '?student_id=$studentId'
        : '';

    final candidateUrls = [
      Uri.parse('$_meshBaseUrl/subject_marks$queryParam'),
      Uri.parse('https://school.mos.ru/api/family/mobile/v1/marks$queryParam'),
    ];

    for (final url in candidateUrls) {
      try {
        final response =
            await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final List<SubjectSummary> result = [];

          dynamic payload;
          if (body is Map) {
            payload = body['payload'] ?? body['data'] ?? body['items'];
          } else if (body is List) {
            payload = body;
          }

          if (payload is List) {
            for (final item in payload) {
              if (item is Map) {
                final subjectName = (item['subject_name'] ?? item['subject'] ?? item['name'] ?? '').toString();
                final teacher = (item['teacher_name'] ?? item['teacher'] ?? '').toString();
                final marksRaw = (item['marks'] ?? item['grades'] ?? item['values']) as List<dynamic>? ?? [];

                final gradeItems = <GradeItem>[];
                for (final m in marksRaw) {
                  if (m is Map) {
                    final val = int.tryParse((m['value'] ?? m['mark'] ?? '').toString()) ?? 0;
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

            if (result.isNotEmpty) {
              await _cacheService.saveGrades(result);
              return result;
            }
          }
        }
      } catch (_) {}
    }

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

    final headers = await _getHeaders();
    final queryParam = studentId.isNotEmpty && studentId != 'mesh_user'
        ? '?student_id=$studentId'
        : '';

    final candidateUrls = [
      Uri.parse('$_meshBaseUrl/homeworks$queryParam'),
      Uri.parse('https://school.mos.ru/api/family/mobile/v1/homeworks$queryParam'),
    ];

    for (final url in candidateUrls) {
      try {
        final response =
            await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final List<HomeworkItem> result = [];

          dynamic payload;
          if (body is Map) {
            payload = body['payload'] ?? body['data'] ?? body['items'];
          } else if (body is List) {
            payload = body;
          }

          if (payload is List) {
            for (final hw in payload) {
              if (hw is Map) {
                final dateStr = (hw['date'] ?? hw['deadline'] ?? '').toString();
                final date = DateTime.tryParse(dateStr) ?? DateTime.now();

                result.add(HomeworkItem(
                  id: (hw['id'] ?? '').toString(),
                  subject: (hw['subject_name'] ?? hw['subject'] ?? 'Предмет').toString(),
                  description: (hw['description'] ?? hw['task'] ?? '').toString(),
                  dueDate: date,
                  isCompleted: hw['is_done'] == true || hw['is_completed'] == true,
                  attachmentsCount:
                      (hw['materials'] as List<dynamic>?)?.length ?? 0,
                ));
              }
            }

            if (result.isNotEmpty) {
              await _cacheService.saveHomeworks(result);
              return result;
            }
          }
        }
      } catch (_) {}
    }

    return [];
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
