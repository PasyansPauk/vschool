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
    int parsedVal = 5;
    final rawVal = json['value'];
    if (rawVal is int) {
      parsedVal = rawVal;
    } else if (rawVal is num) {
      parsedVal = rawVal.round();
    } else if (rawVal != null) {
      final str = rawVal.toString().trim();
      if (str.contains('/')) {
        parsedVal = int.tryParse(str.split('/')[0].trim()) ?? 5;
      } else {
        parsedVal = int.tryParse(str) ?? 5;
      }
    }

    int parsedWeight = 1;
    final rawWeight = json['weight'];
    if (rawWeight is int) {
      parsedWeight = rawWeight;
    } else if (rawWeight is num) {
      parsedWeight = rawWeight.round();
    } else if (rawWeight != null) {
      parsedWeight = int.tryParse(rawWeight.toString().trim()) ?? 1;
    }

    return GradeItem(
      id: (json['id'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      value: parsedVal,
      weight: parsedWeight,
      date: json['date'] != null
          ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now())
          : DateTime.now(),
      topic: (json['topic'] ?? '').toString(),
      comment: json['comment']?.toString(),
    );
  }

  String get formattedDate {
    final months = [
      '', 'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${date.day} ${months[date.month]}';
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
