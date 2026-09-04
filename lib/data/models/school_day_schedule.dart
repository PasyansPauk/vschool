import 'lesson.dart';

class SchoolDaySchedule {
  final DateTime date;
  final String dayName;
  final List<Lesson> lessons;

  const SchoolDaySchedule({
    required this.date,
    required this.dayName,
    required this.lessons,
  });

  String get startTime => lessons.isNotEmpty ? lessons.first.startTime : '08:30';
  String get endTime => lessons.isNotEmpty ? lessons.last.endTime : '15:10';

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'dayName': dayName,
        'lessons': lessons.map((e) => e.toJson()).toList(),
      };

  factory SchoolDaySchedule.fromJson(Map<String, dynamic> json) {
    return SchoolDaySchedule(
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      dayName: json['dayName'] as String? ?? '',
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
