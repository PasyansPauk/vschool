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

  factory SubjectSummary.fromJson(Map<String, dynamic> json) {
    return SubjectSummary(
      subject: json['subject'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      grades: (json['grades'] as List<dynamic>?)
              ?.map((e) => GradeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
