import 'grade_item.dart';

class Lesson {
  final int number;
  final String subject;
  final String startTime;
  final String endTime;
  final String room;
  final String teacher;
  final String topic;
  final String? homework;
  final GradeItem? grade;
  final String? attendance; // 'Н', 'Б', 'УП' or null

  const Lesson({
    required this.number,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.teacher,
    required this.topic,
    this.homework,
    this.grade,
    this.attendance,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'subject': subject,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
        'teacher': teacher,
        'topic': topic,
        'homework': homework,
        'grade': grade?.toJson(),
        'attendance': attendance,
      };

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      number: json['number'] as int? ?? 1,
      subject: json['subject'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '08:30',
      endTime: json['endTime'] as String? ?? '09:15',
      room: json['room'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      homework: json['homework'] as String?,
      grade: json['grade'] != null
          ? GradeItem.fromJson(json['grade'] as Map<String, dynamic>)
          : null,
      attendance: json['attendance'] as String?,
    );
  }

  Lesson copyWith({
    int? number,
    String? subject,
    String? startTime,
    String? endTime,
    String? room,
    String? teacher,
    String? topic,
    String? homework,
    GradeItem? grade,
    String? attendance,
  }) {
    return Lesson(
      number: number ?? this.number,
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      teacher: teacher ?? this.teacher,
      topic: topic ?? this.topic,
      homework: homework ?? this.homework,
      grade: grade ?? this.grade,
      attendance: attendance ?? this.attendance,
    );
  }
}
