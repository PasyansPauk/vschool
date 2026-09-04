class GradeItem {
  final String id;
  final String subject;
  final int value; // 2, 3, 4, 5
  final int weight; // 1, 2, 3
  final DateTime date;
  final String topic;
  final String? comment;

  const GradeItem({
    required this.id,
    required this.subject,
    required this.value,
    this.weight = 1,
    required this.date,
    required this.topic,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'value': value,
        'weight': weight,
        'date': date.toIso8601String(),
        'topic': topic,
        'comment': comment,
      };

  factory GradeItem.fromJson(Map<String, dynamic> json) {
    return GradeItem(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      value: json['value'] as int? ?? 5,
      weight: json['weight'] as int? ?? 1,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      topic: json['topic'] as String? ?? '',
      comment: json['comment'] as String?,
    );
  }

  String get weightSuperscript {
    switch (weight) {
      case 2:
        return '²';
      case 3:
        return '³';
      case 4:
        return '⁴';
      case 5:
        return '⁵';
      default:
        return '';
    }
  }
}
