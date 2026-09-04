class HomeworkAttachment {
  final String id;
  final String title;
  final String url;
  final String type;

  const HomeworkAttachment({
    required this.id,
    required this.title,
    required this.url,
    this.type = 'file',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'type': type,
      };

  factory HomeworkAttachment.fromJson(Map<String, dynamic> json) {
    return HomeworkAttachment(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? 'Файл').toString(),
      url: (json['url'] ?? json['file_url'] ?? json['link'] ?? '').toString(),
      type: (json['type'] ?? 'file').toString(),
    );
  }
}

class HomeworkItem {
  final String id;
  final String subject;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final int attachmentsCount;
  final List<HomeworkAttachment> attachments;

  const HomeworkItem({
    required this.id,
    required this.subject,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.attachmentsCount = 0,
    this.attachments = const [],
  });

  HomeworkItem copyWith({
    String? id,
    String? subject,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    int? attachmentsCount,
    List<HomeworkAttachment>? attachments,
  }) {
    return HomeworkItem(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      attachmentsCount: attachmentsCount ?? this.attachmentsCount,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': isCompleted,
        'attachmentsCount': attachmentsCount,
        'attachments': attachments.map((a) => a.toJson()).toList(),
      };

  factory HomeworkItem.fromJson(Map<String, dynamic> json) {
    final rawAtts = json['attachments'] as List<dynamic>? ?? [];
    final attachmentsList = rawAtts
        .map((a) => HomeworkAttachment.fromJson(a as Map<String, dynamic>))
        .toList();

    return HomeworkItem(
      id: (json['id'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      attachmentsCount: json['attachmentsCount'] as int? ?? attachmentsList.length,
      attachments: attachmentsList,
    );
  }
}
