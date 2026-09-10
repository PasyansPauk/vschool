import 'grade_item.dart';

class SubjectSummary {
  final String subject;
  final String teacher;
  final List<GradeItem> grades;

  const SubjectSummary({
    required this.subject,
    required this.teacher,
    required this.grades,
  });

  double get averageScore {
    if (grades.isEmpty) return 0.0;
    int weightedSum = 0;
    int totalWeights = 0;

    for (final g in grades) {
      weightedSum += g.value * g.weight;
      totalWeights += g.weight;
    }

    if (totalWeights == 0) return 0.0;
    return weightedSum / totalWeights;
  }

  String get formattedAverage {
    final avg = averageScore;
    if (avg == 0.0) return '—';
    return avg.toStringAsFixed(2);
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'teacher': teacher,
        'grades': grades.map((g) => g.toJson()).toList(),
      };

  SubjectSummary copyWith({
    String? subject,
    String? teacher,
    List<GradeItem>? grades,
  }) {
    return SubjectSummary(
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      grades: grades ?? this.grades,
    );
  }

  factory SubjectSummary.fromJson(Map<String, dynamic> json) {
    final rawGrades = json['grades'];
    final List<GradeItem> parsedGrades = [];
    if (rawGrades is List) {
      for (final item in rawGrades) {
        if (item is Map) {
          parsedGrades.add(GradeItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return SubjectSummary(
      subject: (json['subject'] ?? '').toString(),
      teacher: (json['teacher'] ?? '').toString(),
      grades: parsedGrades,
    );
  }
}
