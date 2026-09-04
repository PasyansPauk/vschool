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
import 'dart:math' as math;

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
        token != 'cookie_auth_only' &&
        !token.contains('authenticated') &&
        !token.contains('session')) {
      headers['Auth-Token'] = token;
      headers['auth-token'] = token;
      headers['Authorization'] = 'Bearer $token';
    }
    
    // Only send Profile-Id if it's a valid numeric ID, NOT a subsystem string like 'familyweb' or 'footerweb'
    final isNumeric = studentId != null && RegExp(r'^\d+$').hasMatch(studentId);
    if (isNumeric) {
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
    final isNumeric = RegExp(r'^\d+$').hasMatch(studentId);

    final candidateUrls = [
      Uri.parse('$_meshBaseUrl/profile'),
      if (isNumeric)
        Uri.parse('https://dnevnik.mos.ru/core/api/student_profiles/$studentId'),
      Uri.parse('https://dnevnik.mos.ru/core/api/student_profiles'),
      Uri.parse('https://school.mos.ru/api/family/mobile/v1/profile'),
      Uri.parse('https://dnevnik.mos.ru/mobile/api/profile'),
    ];

    List<String> errors = [];

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
        } else {
          errors.add('${url.path}: ${response.statusCode}');
        }
      } catch (e) {
        errors.add('${url.path}: $e');
      }
    }

    if (errors.isNotEmpty) {
       throw MesApiException('Profile fail: ${errors.join(", ")} | Token: ${token != null ? token.substring(0, math.min(10, token.length)) : "null"}...');
    }
    return null;
  }

  /// Fetches real schedules from official МЭШ API for the specified week (or current week).
  Future<List<SchoolDaySchedule>> fetchSchedules({DateTime? forDate}) async {
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

    final target = forDate ?? DateTime.now();
    final monday = DateTime(target.year, target.month, target.day)
        .subtract(Duration(days: target.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final dateFormat = DateFormat('yyyy-MM-dd');
    final beginStr = dateFormat.format(monday);
    final endStr = dateFormat.format(sunday);

    final headers = await _getHeaders();
    final queryParam = studentId.isNotEmpty && studentId != 'mesh_user'
        ? 'student_id=$studentId&'
        : '';

    final candidateUrls = [
      Uri.parse(
          'https://school.mos.ru/api/family/web/v1/schedule?${queryParam}begin_date=$beginStr&end_date=$endStr'),
      Uri.parse(
          'https://school.mos.ru/api/family/mobile/v1/schedule?${queryParam}begin_date=$beginStr&end_date=$endStr'),
      Uri.parse(
          '$_meshBaseUrl/schedule?${queryParam}begin_date=$beginStr&end_date=$endStr'),
    ];

    List<String> errors = [];
    List<SchoolDaySchedule> fallbackEmptyWeek = [];

    for (final url in candidateUrls) {
      try {
        final response =
            await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final List<SchoolDaySchedule> parsed = [];

          dynamic activities;
          if (body is Map) {
            activities = body['activities'] ??
                body['payload'] ??
                body['lessons'] ??
                body['data'] ??
                body['response'];
          } else if (body is List) {
            activities = body;
          }

          if (activities is List) {
            // Process each day of the week (Monday to Sunday)
            for (int i = 0; i < 7; i++) {
              final dayDate = monday.add(Duration(days: i));
              final dayStr = dateFormat.format(dayDate);
              final dayLessons = <Lesson>[];
              final dayBreaks = <ScheduleBreak>[];

              final List<dynamic> daySpecificActivities = [];
              for (final item in activities) {
                if (item is Map) {
                  // Check if Day container (contains a list of lessons/activities)
                  final bool isDayContainer =
                      (item.containsKey('lessons') && item['lessons'] is List) ||
                      (item.containsKey('activities') && item['activities'] is List);

                  if (isDayContainer) {
                    final itemDt = _parseAnyDateTime(item['date'] ?? item['lesson_date'] ?? item['begin_date']);
                    if (itemDt != null) {
                      if (itemDt.year == dayDate.year && itemDt.month == dayDate.month && itemDt.day == dayDate.day) {
                        final childList = (item['lessons'] ?? item['activities']) as List;
                        daySpecificActivities.addAll(childList);
                      }
                    } else {
                      final itemDate = (item['date'] ?? item['lesson_date'] ?? item['begin_date'] ?? '').toString();
                      if (itemDate.startsWith(dayStr)) {
                        final childList = (item['lessons'] ?? item['activities']) as List;
                        daySpecificActivities.addAll(childList);
                      }
                    }
                  } else {
                    // Item is a direct lesson or schedule activity
                    DateTime? itemDt = _parseAnyDateTime(item['begin_utc']) ??
                        _parseAnyDateTime(item['start_at']) ??
                        _parseAnyDateTime(item['begin_at']) ??
                        _parseAnyDateTime(item['datetime']) ??
                        _parseAnyDateTime(item['date']) ??
                        _parseAnyDateTime(item['lesson_date']) ??
                        _parseAnyDateTime(item['begin_date']);

                    if (itemDt == null && item['lesson'] is Map) {
                      final l = item['lesson'] as Map;
                      itemDt = _parseAnyDateTime(l['begin_utc']) ??
                          _parseAnyDateTime(l['date']) ??
                          _parseAnyDateTime(l['lesson_date']) ??
                          _parseAnyDateTime(l['start_at']);
                    }

                    if (itemDt != null) {
                      if (itemDt.year == dayDate.year &&
                          itemDt.month == dayDate.month &&
                          itemDt.day == dayDate.day) {
                        daySpecificActivities.add(item);
                      }
                    } else {
                      final s = (item['date'] ??
                              item['lesson_date'] ??
                              item['begin_date'] ??
                              item['begin_time'] ??
                              '')
                          .toString();
                      if (s.isNotEmpty && s.startsWith(dayStr)) {
                        daySpecificActivities.add(item);
                      }
                    }
                  }
                }
              }

              for (final act in daySpecificActivities) {
                if (act is Map) {
                  final Map? nestedLesson =
                      act['lesson'] is Map ? (act['lesson'] as Map) : null;

                  // Extract Subject Name
                  String subject = _extractSubject(act, nestedLesson);

                  // Extract Start & End Times
                  String start = _extractStartTime(act, nestedLesson);
                  String end = _extractEndTime(act, nestedLesson);

                  // Check if this activity is a BREAK (Перемена)
                  if (_isBreakActivity(act, nestedLesson, subject)) {
                    final durationMins = SchoolDaySchedule.calcMins(start, end);
                    String breakName = subject.isNotEmpty && subject.toLowerCase() != 'урок'
                        ? subject
                        : (durationMins >= 20 ? 'Большая перемена' : 'Перемена');
                    dayBreaks.add(ScheduleBreak(
                      name: breakName,
                      startTime: start,
                      endTime: end,
                      durationMinutes: durationMins,
                    ));
                    continue; // Skip adding to lessons!
                  }

                  // Extract Lesson Number
                  final numVal = _extractLessonNumber(act, nestedLesson, dayLessons.length + 1);

                  // Deduplicate identical lessons in same time slot
                  final isDuplicate = dayLessons.any((l) =>
                      (l.startTime == start && l.subject.toLowerCase() == subject.toLowerCase()) ||
                      (numVal > 0 && l.number == numVal && l.startTime == start));
                  if (isDuplicate) continue;

                  // Extract Teacher Name
                  String teacher = _extractTeacher(act, nestedLesson);

                  // Extract Room
                  String room = _extractRoom(act, nestedLesson);

                  // Extract Topic
                  String topic = _extractTopic(act, nestedLesson);

                  // Extract Homework & Grade
                  String? hwDesc = _extractHomework(act, nestedLesson);
                  GradeItem? gradeItem = _extractGrade(act, nestedLesson, dayDate, subject, topic);

                  dayLessons.add(Lesson(
                    number: numVal > 0 ? numVal : (dayLessons.length + 1),
                    subject: subject,
                    room: room,
                    teacher: teacher,
                    startTime: start,
                    endTime: end,
                    topic: topic,
                    homework: hwDesc,
                    grade: gradeItem,
                  ));
                }
              }

              // Sort lessons chronologically
              dayLessons.sort((a, b) {
                final timeCmp = a.startTime.compareTo(b.startTime);
                if (timeCmp != 0) return timeCmp;
                return a.number.compareTo(b.number);
              });

              // Renumber lessons consecutively 1, 2, 3...
              for (int k = 0; k < dayLessons.length; k++) {
                dayLessons[k] = dayLessons[k].copyWith(number: k + 1);
              }

              // Sort breaks chronologically
              dayBreaks.sort((a, b) => a.startTime.compareTo(b.startTime));

              parsed.add(SchoolDaySchedule(
                date: dayDate,
                dayName: _dayName(dayDate.weekday),
                lessons: dayLessons,
                breaks: dayBreaks,
              ));
            }

            if (parsed.any((s) => s.lessons.isNotEmpty)) {
              if (forDate == null || _isSameWeek(target, DateTime.now())) {
                await _cacheService.saveSchedules(parsed);
              }
              return parsed;
            } else {
              // Valid response with 0 lessons (e.g. vacation / free week)
              if (fallbackEmptyWeek.isEmpty) fallbackEmptyWeek = parsed;
            }
          }
        } else {
          errors.add('${url.path}: ${response.statusCode}');
        }
      } catch (e) {
        errors.add('${url.path}: $e');
      }
    }

    // If candidate URLs responded with valid but empty schedules (e.g. holidays / weekends)
    if (fallbackEmptyWeek.isNotEmpty) {
      return fallbackEmptyWeek;
    }

    if (errors.isNotEmpty) {
      throw MesApiException('Schedule fail: ${errors.join(", ")}');
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
            int hwIdx = 0;
            for (final hw in payload) {
              if (hw is Map) {
                hwIdx++;
                final dateStr = (hw['date'] ?? hw['deadline'] ?? '').toString();
                final date = DateTime.tryParse(dateStr) ?? DateTime.now();

                // Build unique reliable ID
                final rawId = (hw['id'] ?? '').toString().trim();
                final subjectName = (hw['subject_name'] ?? hw['subject'] ?? 'Предмет').toString();
                final uniqueId = rawId.isNotEmpty
                    ? '${rawId}_$hwIdx'
                    : 'hw_${subjectName.hashCode}_${date.millisecondsSinceEpoch}_$hwIdx';

                // Extract attachments / materials
                final List<HomeworkAttachment> attachments = [];
                final rawMats = (hw['materials'] ?? hw['attachments'] ?? hw['files'] ?? []) as List<dynamic>? ?? [];
                for (final m in rawMats) {
                  if (m is Map) {
                    final aTitle = (m['title'] ?? m['name'] ?? m['file_name'] ?? 'Прикрепленный файл').toString();
                    final aUrl = (m['url'] ?? m['file_url'] ?? m['link'] ?? m['download_url'] ?? '').toString();
                    final aType = (m['type'] ?? 'file').toString();
                    if (aUrl.isNotEmpty) {
                      attachments.add(HomeworkAttachment(
                        id: (m['id'] ?? '').toString(),
                        title: aTitle,
                        url: aUrl,
                        type: aType,
                      ));
                    }
                  }
                }

                result.add(HomeworkItem(
                  id: uniqueId,
                  subject: subjectName,
                  description: (hw['description'] ?? hw['task'] ?? '').toString(),
                  dueDate: date,
                  isCompleted: hw['is_done'] == true || hw['is_completed'] == true,
                  attachmentsCount: attachments.isNotEmpty ? attachments.length : rawMats.length,
                  attachments: attachments,
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

  DateTime? _parseAnyDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is int) {
      if (raw > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true).toLocal();
      } else if (raw > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true).toLocal();
      }
      return null;
    }
    final str = raw.toString().trim();
    if (str.isEmpty) return null;

    final asInt = int.tryParse(str);
    if (asInt != null && str.length >= 10) {
      return _parseAnyDateTime(asInt);
    }

    final parsed = DateTime.tryParse(str);
    if (parsed != null) return parsed.toLocal();

    // Check DD.MM.YYYY
    if (str.contains('.')) {
      final parts = str.split('.');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2].split(' ')[0]);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d);
        }
      }
    }
    return null;
  }

  String _formatTimeStr(String raw) {
    final s = raw.trim();
    if (s.contains('T')) {
      final parts = s.split('T');
      if (parts.length > 1 && parts[1].length >= 5) {
        return parts[1].substring(0, 5);
      }
    } else if (s.contains(' ')) {
      final parts = s.split(' ');
      if (parts.length > 1 && parts[1].length >= 5) {
        return parts[1].substring(0, 5);
      }
    }
    if (s.length >= 5 && s.contains(':')) {
      return s.substring(0, 5);
    }
    return s;
  }

  String _extractSubject(Map act, Map? nestedLesson) {
    dynamic s = nestedLesson?['subject_name'] ??
        nestedLesson?['subject'] ??
        act['subject_name'] ??
        act['subject'] ??
        nestedLesson?['discipline_name'] ??
        act['discipline_name'] ??
        nestedLesson?['discipline'] ??
        act['discipline'] ??
        nestedLesson?['course_name'] ??
        act['course_name'] ??
        nestedLesson?['title'] ??
        act['title'] ??
        nestedLesson?['name'] ??
        act['name'];

    if (s is Map) {
      s = s['name'] ?? s['title'] ?? s['subject_name'] ?? s['subject'];
    }

    String result = (s ?? '').toString().trim();
    if (result.isEmpty || result == 'null' || result.toLowerCase() == 'урок') {
      final course = (nestedLesson?['course_name'] ?? act['course_name'] ?? '').toString().trim();
      if (course.isNotEmpty && course != 'null') return course;

      final topic = (nestedLesson?['topic'] ?? act['topic'] ?? '').toString().trim();
      if (topic.isNotEmpty && topic != 'null' && !topic.toLowerCase().startsWith('урок')) {
        return topic;
      }
      return 'Урок';
    }
    return result;
  }

  String _extractStartTime(Map act, Map? nestedLesson) {
    final raw = nestedLesson?['begin_time'] ??
        act['begin_time'] ??
        nestedLesson?['start_time'] ??
        act['start_time'];
    if (raw != null) {
      final t = _formatTimeStr(raw.toString());
      if (t.isNotEmpty) return t;
    }

    final dt = _parseAnyDateTime(nestedLesson?['begin_utc'] ??
        act['begin_utc'] ??
        nestedLesson?['start_at'] ??
        act['start_at'] ??
        nestedLesson?['begin_at'] ??
        act['begin_at']);
    if (dt != null) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return '08:30';
  }

  String _extractEndTime(Map act, Map? nestedLesson) {
    final raw = nestedLesson?['end_time'] ??
        act['end_time'] ??
        nestedLesson?['finish_time'] ??
        act['finish_time'];
    if (raw != null) {
      final t = _formatTimeStr(raw.toString());
      if (t.isNotEmpty) return t;
    }

    final dt = _parseAnyDateTime(nestedLesson?['end_utc'] ??
        act['end_utc'] ??
        nestedLesson?['finish_at'] ??
        act['finish_at'] ??
        nestedLesson?['end_at'] ??
        act['end_at']);
    if (dt != null) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return '09:15';
  }

  int _extractLessonNumber(Map act, Map? nestedLesson, int fallback) {
    final dynamic raw = nestedLesson?['lesson_number'] ??
        act['lesson_number'] ??
        nestedLesson?['lesson_num'] ??
        act['lesson_num'] ??
        nestedLesson?['number'] ??
        act['number'] ??
        nestedLesson?['num'] ??
        act['num'] ??
        nestedLesson?['lesson_order'] ??
        act['lesson_order'] ??
        nestedLesson?['order'] ??
        act['order'];
    if (raw != null) {
      final parsed = int.tryParse(raw.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    return fallback;
  }

  String _extractTeacher(Map act, Map? nestedLesson) {
    dynamic t = nestedLesson?['teacher_name'] ??
        act['teacher_name'] ??
        nestedLesson?['teacher'] ??
        act['teacher'] ??
        nestedLesson?['employee_name'] ??
        act['employee_name'] ??
        nestedLesson?['educator'] ??
        act['educator'];

    if (t is Map) {
      if (t['short_name'] != null && t['short_name'].toString().trim().isNotEmpty) {
        return t['short_name'].toString().trim();
      }
      if (t['fio'] != null && t['fio'].toString().trim().isNotEmpty) {
        return t['fio'].toString().trim();
      }
      if (t['name'] != null && t['name'].toString().trim().isNotEmpty) {
        return t['name'].toString().trim();
      }
      final last = (t['last_name'] ?? '').toString().trim();
      final first = (t['first_name'] ?? '').toString().trim();
      final middle = (t['middle_name'] ?? '').toString().trim();
      final parts = [last, first, middle].where((p) => p.isNotEmpty).join(' ');
      if (parts.isNotEmpty) return parts;
    }

    final str = (t ?? '').toString().trim();
    if (str.isEmpty ||
        str == 'null' ||
        str.toLowerCase() == 'учитель не указан' ||
        str.toLowerCase() == 'нет учителя') {
      return '';
    }
    return str;
  }

  String _extractRoom(Map act, Map? nestedLesson) {
    dynamic r = nestedLesson?['room_number'] ??
        act['room_number'] ??
        nestedLesson?['room_name'] ??
        act['room_name'] ??
        nestedLesson?['room'] ??
        act['room'] ??
        nestedLesson?['building_room'] ??
        act['building_room'];

    if (r is Map) {
      r = r['number'] ?? r['name'] ?? r['title'];
    }

    final str = (r ?? '').toString().trim();
    if (str.isEmpty || str == 'null') return '';
    return str;
  }

  String _extractTopic(Map act, Map? nestedLesson) {
    dynamic tp = nestedLesson?['topic'] ??
        act['topic'] ??
        nestedLesson?['lesson_theme'] ??
        act['lesson_theme'] ??
        nestedLesson?['theme'] ??
        act['theme'];

    if (tp is Map) {
      tp = tp['title'] ?? tp['name'] ?? tp['theme'];
    }

    final str = (tp ?? '').toString().trim();
    if (str.isEmpty || str == 'null' || str.toLowerCase() == 'тема не указана') {
      return '';
    }
    return str;
  }

  String? _extractHomework(Map act, Map? nestedLesson) {
    dynamic hw = nestedLesson?['homework'] ??
        act['homework'] ??
        nestedLesson?['homeworks'] ??
        act['homeworks'] ??
        nestedLesson?['home_tasks'] ??
        act['home_tasks'];

    if (hw is List && hw.isNotEmpty) {
      final descs = <String>[];
      for (final item in hw) {
        if (item is Map) {
          final desc = (item['description'] ?? item['task'] ?? item['name'] ?? '').toString().trim();
          if (desc.isNotEmpty) descs.add(desc);
        } else if (item is String && item.trim().isNotEmpty) {
          descs.add(item.trim());
        }
      }
      if (descs.isNotEmpty) return descs.join('\n');
    } else if (hw is Map) {
      final desc = (hw['description'] ?? hw['task'] ?? hw['name'] ?? '').toString().trim();
      if (desc.isNotEmpty) return desc;
    } else if (hw is String && hw.trim().isNotEmpty && hw.trim() != 'null') {
      return hw.trim();
    }
    return null;
  }

  GradeItem? _extractGrade(Map act, Map? nestedLesson, DateTime dayDate, String subject, String topic) {
    dynamic marks = nestedLesson?['marks'] ??
        act['marks'] ??
        nestedLesson?['grade'] ??
        act['grade'] ??
        nestedLesson?['mark'] ??
        act['mark'];

    if (marks is List && marks.isNotEmpty) {
      for (final m in marks) {
        if (m is Map) {
          final val = int.tryParse((m['value'] ?? m['mark'] ?? '').toString()) ?? 0;
          final weight = int.tryParse((m['weight'] ?? '1').toString()) ?? 1;
          if (val > 0) {
            return GradeItem(
              id: (m['id'] ?? '').toString(),
              subject: subject,
              value: val,
              weight: weight,
              date: dayDate,
              topic: topic,
            );
          }
        }
      }
    } else if (marks is Map) {
      final val = int.tryParse((marks['value'] ?? marks['mark'] ?? '').toString()) ?? 0;
      final weight = int.tryParse((marks['weight'] ?? '1').toString()) ?? 1;
      if (val > 0) {
        return GradeItem(
          id: (marks['id'] ?? '').toString(),
          subject: subject,
          value: val,
          weight: weight,
          date: dayDate,
          topic: topic,
        );
      }
    } else if (marks is int && marks > 0) {
      return GradeItem(
        id: '',
        subject: subject,
        value: marks,
        weight: 1,
        date: dayDate,
        topic: topic,
      );
    }
    return null;
  }

  bool _isBreakActivity(Map act, Map? nestedLesson, String subject) {
    final type = (act['type'] ??
            act['activity_type'] ??
            act['type_name'] ??
            nestedLesson?['type'] ??
            '')
        .toString()
        .toUpperCase();
    if (type == 'BREAK' ||
        type == 'INTERVAL' ||
        type == 'PAUSE' ||
        type == 'RECREATION' ||
        type == 'DINNER' ||
        type == 'LUNCH' ||
        type == 'DYNAMIC_PAUSE') {
      return true;
    }

    if (act['is_break'] == true || act['is_interval'] == true) {
      return true;
    }

    if (SchoolDaySchedule.isBreakSubject(subject)) {
      return true;
    }

    final title = (act['title'] ??
            act['name'] ??
            nestedLesson?['title'] ??
            nestedLesson?['name'] ??
            '')
        .toString()
        .toLowerCase();
    if (title.contains('перемен') ||
        title.contains('перерыв') ||
        title == 'обед' ||
        title.contains('динамическая пауза')) {
      return true;
    }

    return false;
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final monA = DateTime(a.year, a.month, a.day).subtract(Duration(days: a.weekday - 1));
    final monB = DateTime(b.year, b.month, b.day).subtract(Duration(days: b.weekday - 1));
    return monA.year == monB.year && monA.month == monB.month && monA.day == monB.day;
  }
}
