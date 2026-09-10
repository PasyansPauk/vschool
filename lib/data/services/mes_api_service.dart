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
import 'dev_logger.dart';
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
    final dateFormat = DateFormat('yyyy-MM-dd');

    final headers = await _getHeaders();
    final queryParam = studentId.isNotEmpty && studentId != 'mesh_user'
        ? 'student_id=$studentId&'
        : '';

    // Выполняем 7 запросов параллельно (по одному на каждый день недели)
    // Так как API МЭШ /family/web/v1/schedule возвращает детальное расписание только на 1 день (date=YYYY-MM-DD).
    final futures = List.generate(7, (i) async {
      final dayDate = monday.add(Duration(days: i));
      final dayStr = dateFormat.format(dayDate);

      final candidateUrls = [
        Uri.parse('https://school.mos.ru/api/family/web/v1/schedule?${queryParam}date=$dayStr'),
        Uri.parse('https://school.mos.ru/api/family/mobile/v1/schedule?${queryParam}date=$dayStr'),
      ];

      final dayLessons = <Lesson>[];
      final dayBreaks = <ScheduleBreak>[];

      for (final url in candidateUrls) {
        try {
          final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));
          if (response.statusCode == 200) {
            if (i == 0 || i == 1) { // Логируем пару дней для дебага
              DevLogger.log('schedule_raw_$dayStr', response.body);
            }
            final body = jsonDecode(response.body);

            dynamic activities;
            if (body is Map) {
              activities = body['activities'] ?? body['payload'] ?? body['lessons'] ?? body['data'];
            } else if (body is List) {
              activities = body;
            }

            if (activities is List) {
              for (final act in activities) {
                if (act is Map) {
                  final Map? nestedLesson = act['lesson'] is Map ? (act['lesson'] as Map) : null;
                  String subject = _extractSubject(act, nestedLesson);
                  String start = _extractStartTime(act, nestedLesson);
                  String end = _extractEndTime(act, nestedLesson);

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
                    continue;
                  }

                  final numVal = _extractLessonNumber(act, nestedLesson, dayLessons.length + 1);
                  final isDuplicate = dayLessons.any((l) =>
                      (l.startTime == start && l.subject.toLowerCase() == subject.toLowerCase()) ||
                      (numVal > 0 && l.number == numVal && l.startTime == start));
                  if (isDuplicate) continue;

                  dayLessons.add(Lesson(
                    number: numVal > 0 ? numVal : (dayLessons.length + 1),
                    subject: subject,
                    room: _extractRoom(act, nestedLesson),
                    teacher: _extractTeacher(act, nestedLesson),
                    startTime: start,
                    endTime: end,
                    topic: _extractTopic(act, nestedLesson),
                    homework: _extractHomework(act, nestedLesson),
                    grade: _extractGrade(act, nestedLesson, dayDate, subject, _extractTopic(act, nestedLesson)),
                  ));
                }
              }

              // Сортировка по времени
              dayLessons.sort((a, b) {
                final timeCmp = a.startTime.compareTo(b.startTime);
                if (timeCmp != 0) return timeCmp;
                return a.number.compareTo(b.number);
              });

              for (int k = 0; k < dayLessons.length; k++) {
                dayLessons[k] = dayLessons[k].copyWith(number: k + 1);
              }
              dayBreaks.sort((a, b) => a.startTime.compareTo(b.startTime));
            }
            break; // Успешно загрузили день, выходим из candidateUrls
          }
        } catch (_) {}
      }

      return SchoolDaySchedule(
        date: dayDate,
        dayName: _dayName(dayDate.weekday),
        lessons: dayLessons,
        breaks: dayBreaks,
      );
    });

    final List<SchoolDaySchedule> weekSchedule = await Future.wait(futures);

    // Если хотя бы в один из дней есть уроки, кешируем всю неделю
    if (weekSchedule.any((s) => s.lessons.isNotEmpty)) {
      await _cacheService.saveSchedules(weekSchedule);
      return weekSchedule;
    }

    return weekSchedule; // Возвращаем пустую неделю, если уроков нет
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
    final now = DateTime.now();
    final fromDate = now.month >= 8 ? '${now.year}-09-01' : '${now.year - 1}-09-01';
    final toDate = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 30)));
    final toAcademicYearEnd = now.month >= 8 ? '${now.year + 1}-06-30' : '${now.year}-06-30';

    final idParam = studentId.isNotEmpty && studentId != 'mesh_user'
        ? 'student_id=$studentId&'
        : '';
    final idParamOnly = studentId.isNotEmpty && studentId != 'mesh_user'
        ? '?student_id=$studentId'
        : '';

    final candidateUrls = [
      Uri.parse('$_meshBaseUrl/subject_marks?${idParam}from=$fromDate&to=$toDate'),
      Uri.parse('$_meshBaseUrl/subject_marks?${idParam}from=$fromDate&to=$toAcademicYearEnd'),
      Uri.parse('$_meshBaseUrl/subject_marks$idParamOnly'),
      Uri.parse('$_meshBaseUrl/marks?${idParam}from=$fromDate&to=$toDate'),
      Uri.parse('$_meshBaseUrl/marks?${idParam}from=$fromDate&to=$toAcademicYearEnd'),
      Uri.parse('https://school.mos.ru/api/family/mobile/v1/marks?${idParam}from=$fromDate&to=$toDate'),
      Uri.parse('https://school.mos.ru/api/family/mobile/v1/marks?${idParam}from=$fromDate&to=$toAcademicYearEnd'),
      Uri.parse('https://school.mos.ru/api/family/mobile/v1/marks$idParamOnly'),
      Uri.parse('$_meshBaseUrl/marks$idParamOnly'),
    ];

    List<SubjectSummary> bestResult = [];

    for (final url in candidateUrls) {
      try {
        final response =
            await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final list = _parseMarksResponse(body);

          // If we found subjects with actual grades, save and return immediately!
          if (list.any((s) => s.grades.isNotEmpty)) {
            _sortSubjects(list);
            await _cacheService.saveGrades(list);
            return list;
          }

          if (list.isNotEmpty && bestResult.isEmpty) {
            bestResult = list;
          }
        }
      } catch (_) {}
    }

    // Fallback: merge any grades already loaded in schedule lessons
    final fallbackWithSchedules = await _mergeGradesFromSchedules(bestResult);
    if (fallbackWithSchedules.any((s) => s.grades.isNotEmpty)) {
      _sortSubjects(fallbackWithSchedules);
      await _cacheService.saveGrades(fallbackWithSchedules);
      return fallbackWithSchedules;
    }

    if (bestResult.isNotEmpty) {
      _sortSubjects(bestResult);
      await _cacheService.saveGrades(bestResult);
      return bestResult;
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

    // Поскольку эндпоинт /homeworks для многих пользователей возвращает пустой payload,
    // а расписание стабильно отдает поле homework внутри урока,
    // мы извлекаем домашнее задание прямо из расписания на предыдущую, текущую и следующую неделю.
    final now = DateTime.now();
    final previousWeek = await fetchSchedules(forDate: now.subtract(const Duration(days: 7)));
    final currentWeek = await fetchSchedules(forDate: now);
    final nextWeek = await fetchSchedules(forDate: now.add(const Duration(days: 7)));

    final allDays = [...previousWeek, ...currentWeek, ...nextWeek];
    final List<HomeworkItem> result = [];

    for (final day in allDays) {
      for (final lesson in day.lessons) {
        final hwText = lesson.homework?.trim() ?? '';
        if (hwText.isNotEmpty && hwText != 'Материал выдан в классе. Домашнее задание выдано в классе') {
          // Stable ID based on subject, date, and lesson number to prevent mass-toggling bugs
          final uniqueId = 'hw_${lesson.subject.hashCode}_${day.date.millisecondsSinceEpoch}_${lesson.number}';

          result.add(HomeworkItem(
            id: uniqueId,
            subject: lesson.subject,
            description: hwText,
            dueDate: day.date,
            isCompleted: false, // Will be merged with cache below
            attachmentsCount: 0,
            attachments: [],
          ));
        }
      }
    }

    // Merge with cached homework to preserve isCompleted status
    final cached = await _cacheService.getHomeworks() ?? [];
    for (int i = 0; i < result.length; i++) {
      final existing = cached.where((c) => c.id == result[i].id).firstOrNull;
      if (existing != null) {
        result[i] = result[i].copyWith(isCompleted: existing.isCompleted);
      }
    }

    if (result.isNotEmpty) {
      await _cacheService.saveHomeworks(result);
    }
    return result;
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

  int _parseSingleGrade(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    final str = raw.toString().trim();
    if (str.isEmpty || str == 'null') return 0;

    // e.g. "5/4" or "5/5" -> take the first mark
    if (str.contains('/')) {
      final first = int.tryParse(str.split('/')[0].trim());
      if (first != null && first > 0) return first;
    }

    // e.g. "5.0" or "5,0"
    final cleanStr = str.replaceAll(',', '.');
    final doubleVal = double.tryParse(cleanStr);
    if (doubleVal != null && doubleVal > 0) return doubleVal.round();

    final intVal = int.tryParse(str);
    if (intVal != null && intVal > 0) return intVal;

    // Fallback: extract single digit 1..5
    final match = RegExp(r'[1-5]').firstMatch(str);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 0;
    }

    return 0;
  }

  int _parseWeight(dynamic raw) {
    if (raw == null) return 1;
    if (raw is int && raw > 0) return raw;
    if (raw is num && raw > 0) return raw.round();
    final parsed = int.tryParse(raw.toString().trim());
    if (parsed != null && parsed > 0) return parsed;
    return 1;
  }

  GradeItem? _extractSingleGradeItem(
    dynamic m,
    String subjectName, [
    DateTime? defaultDate,
    String defaultTopic = '',
  ]) {
    if (m == null) return null;
    if (m is Map) {
      dynamic rawVal = m['value'] ??
          m['mark'] ??
          m['grade'] ??
          m['score'] ??
          m['val'] ??
          m['name'];
      if (rawVal == null && m['values'] is List && (m['values'] as List).isNotEmpty) {
        final firstV = (m['values'] as List).first;
        rawVal = firstV is Map ? (firstV['value'] ?? firstV['mark']) : firstV;
      }
      final val = _parseSingleGrade(rawVal);
      if (val <= 0) return null;

      final weight = _parseWeight(
        m['weight'] ?? m['weight_value'] ?? m['criterion_weight'] ?? m['grade_weight'],
      );
      final dateStr = (m['date'] ?? m['date_time'] ?? m['created_at'] ?? '').toString();
      final date = DateTime.tryParse(dateStr) ?? defaultDate ?? DateTime.now();
      final id = (m['id'] ?? '').toString();
      final topic = (m['topic'] ?? m['lesson_theme'] ?? m['comment'] ?? defaultTopic).toString().trim();
      final comment = (m['comment'] ?? m['criterion_name'] ?? '').toString().trim();

      return GradeItem(
        id: id,
        subject: subjectName,
        value: val,
        weight: weight,
        date: date,
        topic: topic,
        comment: comment.isNotEmpty ? comment : null,
      );
    } else {
      final val = _parseSingleGrade(m);
      if (val > 0) {
        return GradeItem(
          id: '',
          subject: subjectName,
          value: val,
          weight: 1,
          date: defaultDate ?? DateTime.now(),
          topic: defaultTopic,
        );
      }
    }
    return null;
  }

  List<GradeItem> _extractGrades(
    Map act,
    Map? nestedLesson,
    DateTime dayDate,
    String subject,
    String topic,
  ) {
    final List<GradeItem> results = [];

    dynamic marksSource = nestedLesson?['marks'] ??
        act['marks'] ??
        nestedLesson?['estimates'] ??
        act['estimates'] ??
        nestedLesson?['estimation'] ??
        act['estimation'] ??
        nestedLesson?['evaluations'] ??
        act['evaluations'] ??
        nestedLesson?['lesson_marks'] ??
        act['lesson_marks'] ??
        nestedLesson?['activity_marks'] ??
        act['activity_marks'] ??
        nestedLesson?['assessments'] ??
        act['assessments'] ??
        nestedLesson?['assessment'] ??
        act['assessment'] ??
        nestedLesson?['grades'] ??
        act['grades'] ??
        nestedLesson?['grade'] ??
        act['grade'] ??
        nestedLesson?['mark'] ??
        act['mark'];

    if (marksSource == null) return results;

    final list = marksSource is List ? marksSource : [marksSource];

    for (final item in list) {
      final g = _extractSingleGradeItem(item, subject, dayDate, topic);
      if (g != null) {
        results.add(g);
      }
    }

    return results;
  }

  GradeItem? _extractGrade(
    Map act,
    Map? nestedLesson,
    DateTime dayDate,
    String subject,
    String topic,
  ) {
    final list = _extractGrades(act, nestedLesson, dayDate, subject, topic);
    return list.isNotEmpty ? list.first : null;
  }

  List<SubjectSummary> _parseMarksResponse(dynamic body) {
    if (body == null) return [];
    dynamic payload;
    if (body is Map) {
      payload = body['payload'] ?? body['data'] ?? body['items'] ?? body['marks'] ?? body['subjects'];
    } else if (body is List) {
      payload = body;
    }

    if (payload is! List || payload.isEmpty) return [];

    final first = payload.first;
    final isFlatMarkList = first is Map &&
        (first['value'] != null || first['mark'] != null || first['score'] != null) &&
        (first['subject_name'] != null || first['subject'] != null);

    if (isFlatMarkList) {
      final Map<String, List<GradeItem>> subjectGradesMap = {};
      final Map<String, String> subjectTeachersMap = {};

      for (final item in payload) {
        if (item is Map) {
          final subjectName = (item['subject_name'] ?? item['subject'] ?? item['name'] ?? '').toString().trim();
          if (subjectName.isEmpty) continue;

          final g = _extractSingleGradeItem(item, subjectName);
          if (g != null) {
            subjectGradesMap.putIfAbsent(subjectName, () => []).add(g);
            if (item['teacher_name'] != null || item['teacher'] != null) {
              subjectTeachersMap[subjectName] = (item['teacher_name'] ?? item['teacher']).toString().trim();
            }
          }
        }
      }

      final List<SubjectSummary> summaries = [];
      for (final entry in subjectGradesMap.entries) {
        summaries.add(SubjectSummary(
          subject: entry.key,
          teacher: subjectTeachersMap[entry.key] ?? '',
          grades: entry.value,
        ));
      }
      return summaries;
    }

    // List of subjects with nested marks
    final List<SubjectSummary> result = [];
    for (final item in payload) {
      if (item is Map) {
        final subjectName = (item['subject_name'] ?? item['subject'] ?? item['name'] ?? '').toString().trim();
        if (subjectName.isEmpty) continue;
        final teacher = (item['teacher_name'] ?? item['teacher'] ?? '').toString().trim();

        final List<GradeItem> gradeItems = [];

        // 1. Direct marks array
        dynamic directMarks = item['marks'] ?? item['grades'] ?? item['values'];
        if (directMarks is List) {
          for (final m in directMarks) {
            final g = _extractSingleGradeItem(m, subjectName);
            if (g != null) gradeItems.add(g);
          }
        }

        // 2. Nested in periods / period_marks / quarters
        dynamic periods = item['periods'] ?? item['period_marks'] ?? item['quarters'] ?? item['terms'];
        if (periods is List) {
          for (final p in periods) {
            if (p is Map) {
              dynamic pMarks = p['marks'] ?? p['grades'] ?? p['values'];
              if (pMarks is List) {
                for (final m in pMarks) {
                  final g = _extractSingleGradeItem(m, subjectName);
                  if (g != null) gradeItems.add(g);
                }
              }
            }
          }
        }

        // 3. Year / final marks
        dynamic yearMarks = item['year_marks'] ?? item['final_marks'];
        if (yearMarks is List) {
          for (final m in yearMarks) {
            final g = _extractSingleGradeItem(m, subjectName);
            if (g != null) gradeItems.add(g);
          }
        }

        result.add(SubjectSummary(
          subject: subjectName,
          teacher: teacher,
          grades: gradeItems,
        ));
      }
    }

    return result;
  }

  Future<List<SubjectSummary>> _mergeGradesFromSchedules(List<SubjectSummary> base) async {
    final schedules = await _cacheService.getSchedules();
    if (schedules == null || schedules.isEmpty) return base;

    final map = <String, SubjectSummary>{};
    for (final s in base) {
      map[s.subject.trim().toLowerCase()] = s;
    }

    for (final day in schedules) {
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
            }
          } else {
            map[subjKey] = SubjectSummary(
              subject: lesson.subject.trim(),
              teacher: lesson.teacher,
              grades: [g],
            );
          }
        }
      }
    }

    return map.values.toList();
  }

  void _sortSubjects(List<SubjectSummary> list) {
    list.sort((a, b) {
      if (a.grades.isNotEmpty && b.grades.isEmpty) return -1;
      if (a.grades.isEmpty && b.grades.isNotEmpty) return 1;
      if (a.grades.length != b.grades.length) {
        return b.grades.length.compareTo(a.grades.length);
      }
      return a.subject.compareTo(b.subject);
    });
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
}
