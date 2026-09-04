import 'lesson.dart';

class ScheduleBreak {
  final String name;
  final String startTime;
  final String endTime;
  final int durationMinutes;

  const ScheduleBreak({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
        'durationMinutes': durationMinutes,
      };

  factory ScheduleBreak.fromJson(Map<String, dynamic> json) {
    return ScheduleBreak(
      name: json['name'] as String? ?? 'Перемена',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 15,
    );
  }
}

class SchoolDaySchedule {
  final DateTime date;
  final String dayName;
  final List<Lesson> lessons;
  final List<ScheduleBreak> breaks;

  const SchoolDaySchedule({
    required this.date,
    required this.dayName,
    required this.lessons,
    this.breaks = const [],
  });

  String get startTime => lessons.isNotEmpty ? lessons.first.startTime : '08:30';
  String get endTime => lessons.isNotEmpty ? lessons.last.endTime : '15:10';
  bool get isWeekend => date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  static bool isBreakSubject(String subject) {
    final s = subject.toLowerCase().trim();
    return s.contains('перемен') ||
        s.contains('перерыв') ||
        s == 'обед' ||
        s.contains('динамическая пауза') ||
        s == 'ланч' ||
        s == 'отдых';
  }

  static int calcMins(String start, String end) {
    try {
      final p1 = start.split(':');
      final p2 = end.split(':');
      final m1 = (int.tryParse(p1[0]) ?? 0) * 60 + (int.tryParse(p1[1]) ?? 0);
      final m2 = (int.tryParse(p2[0]) ?? 0) * 60 + (int.tryParse(p2[1]) ?? 0);
      final diff = m2 - m1;
      return diff > 0 && diff <= 180 ? diff : 15;
    } catch (_) {
      return 15;
    }
  }

  ScheduleBreak? getBreakAfter(int lessonIndex) {
    if (lessonIndex < 0 || lessonIndex >= lessons.length - 1) return null;
    final current = lessons[lessonIndex];
    final next = lessons[lessonIndex + 1];

    for (final b in breaks) {
      if (b.startTime == current.endTime ||
          (b.startTime.compareTo(current.endTime) >= 0 &&
              b.endTime.compareTo(next.startTime) <= 0)) {
        return b;
      }
    }

    final mins = calcMins(current.endTime, next.startTime);
    if (mins > 0 && mins <= 180) {
      String name = 'Перемена';
      if (mins >= 30) {
        name = 'Большая перемена (Обед)';
      } else if (mins >= 20) {
        name = 'Большая перемена';
      }
      return ScheduleBreak(
        name: name,
        startTime: current.endTime,
        endTime: next.startTime,
        durationMinutes: mins,
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'dayName': dayName,
        'lessons': lessons.map((e) => e.toJson()).toList(),
        'breaks': breaks.map((e) => e.toJson()).toList(),
      };

  factory SchoolDaySchedule.fromJson(Map<String, dynamic> json) {
    final rawLessons = (json['lessons'] as List<dynamic>?)
            ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final List<Lesson> validLessons = [];
    final List<ScheduleBreak> extractedBreaks = [];

    for (final l in rawLessons) {
      if (isBreakSubject(l.subject)) {
        extractedBreaks.add(ScheduleBreak(
          name: l.subject.isNotEmpty ? l.subject : 'Перемена',
          startTime: l.startTime,
          endTime: l.endTime,
          durationMinutes: calcMins(l.startTime, l.endTime),
        ));
      } else {
        validLessons.add(l);
      }
    }

    for (int i = 0; i < validLessons.length; i++) {
      if (validLessons[i].number != i + 1) {
        validLessons[i] = validLessons[i].copyWith(number: i + 1);
      }
    }

    final rawBreaks = (json['breaks'] as List<dynamic>?)
            ?.map((e) => ScheduleBreak.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return SchoolDaySchedule(
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      dayName: json['dayName'] as String? ?? '',
      lessons: validLessons,
      breaks: [...extractedBreaks, ...rawBreaks],
    );
  }
}

