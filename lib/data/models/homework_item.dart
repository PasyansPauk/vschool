class HomeworkItem {
  final String id;
  final String subject;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final int attachmentsCount;

  const HomeworkItem({
    required this.id,
    required this.subject,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.attachmentsCount = 0,
  });

  HomeworkItem copyWith({
    String? id,
    String? subject,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    int? attachmentsCount,
  }) {
    return HomeworkItem(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      attachmentsCount: attachmentsCount ?? this.attachmentsCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': isCompleted,
        'attachmentsCount': attachmentsCount,
      };

  factory HomeworkItem.fromJson(Map<String, dynamic> json) {
    return HomeworkItem(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      attachmentsCount: json['attachmentsCount'] as int? ?? 0,
    );
  }
}
