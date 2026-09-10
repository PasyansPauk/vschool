import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/homework_item.dart';
import '../../view_models/diary_view_model.dart';
import '../widgets/android_lesson_card.dart';

class AndroidHomeworkScreen extends StatefulWidget {
  final DiaryViewModel viewModel;
  final bool isDark;

  const AndroidHomeworkScreen({
    super.key,
    required this.viewModel,
    required this.isDark,
  });

  @override
  State<AndroidHomeworkScreen> createState() => _AndroidHomeworkScreenState();
}

class _AndroidHomeworkScreenState extends State<AndroidHomeworkScreen> {
  int _filterIndex = 0; // 0: Все, 1: На завтра, 2: Готово

  List<HomeworkItem> _getFilteredList(List<HomeworkItem> items) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    final baseItems = items.where((item) {
      final due = DateTime.utc(item.dueDate.year, item.dueDate.month, item.dueDate.day);
      return due.compareTo(yesterday) >= 0 && due.compareTo(nextWeek) <= 0;
    }).toList();

    if (_filterIndex == 1) {
      final tomorrow = today.add(const Duration(days: 1));
      return baseItems.where((item) {
        final due = DateTime.utc(item.dueDate.year, item.dueDate.month, item.dueDate.day);
        return due.compareTo(tomorrow) == 0 && !item.isCompleted;
      }).toList();
    } else if (_filterIndex == 2) {
      return baseItems.where((item) => item.isCompleted).toList();
    }
    return baseItems;
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final due = DateTime.utc(date.year, date.month, date.day);
    
    final diff = due.difference(today).inDays;
    
    if (diff == -1) {
      return 'вчера';
    } else if (diff == 0) {
      return 'сегодня';
    } else if (diff == 1) {
      return 'завтра';
    } else {
      final months = [
        '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
        'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
      ];
      final weekdays = [
        '', 'понедельник', 'вторник', 'среду', 'четверг', 'пятницу', 'субботу', 'воскресенье'
      ];
      return 'на ${weekdays[date.weekday]} ${date.day} ${months[date.month]}';
    }
  }

  Future<void> _openAttachment(BuildContext context, HomeworkAttachment att) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.tryParse(att.url);
    if (uri != null) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          _showDownloadError(context, 'Не удалось открыть ссылку: ${att.url}');
        }
      } catch (e) {
        if (context.mounted) {
          _showDownloadError(context, 'Ошибка скачивания файла: $e');
        }
      }
    } else {
      _showDownloadError(context, 'Некорректная ссылка на файл');
    }
  }

  void _showDownloadError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Файл'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHomeworkDetails(BuildContext context, HomeworkItem hw) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final tileBg =
        isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x38FFFFFF) : const Color(0x28000000),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Subject Title & Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tileBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      AndroidLessonCard.getSubjectIcon(hw.subject),
                      size: 24,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hw.subject,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Срок сдачи: ${_formatDueDate(hw.dueDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Assignment Description Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0E000000),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ТЕКСТ ЗАДАНИЯ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hw.description.isNotEmpty
                          ? hw.description
                          : 'Описание отсутствует',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Attachments
              if (hw.attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Прикрепленные файлы (${hw.attachments.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...hw.attachments.map((att) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: tileBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.attach_file,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        att.title.isNotEmpty ? att.title : 'Файл',
                        style: TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(
                        Icons.download_outlined,
                        size: 20,
                        color: textSecondary,
                      ),
                      onTap: () => _openAttachment(context, att),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 18),

              // Complete / Uncomplete action button
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.viewModel.toggleHomework(hw.id);
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  hw.isCompleted
                      ? 'Вернуть в невыполненные'
                      : 'Отметить как выполненное ✓',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: hw.isCompleted ? AppTheme.grade2Color : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(BuildContext context, HomeworkItem hw) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardBg =
        isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showHomeworkDetails(context, hw),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Completion Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: hw.isCompleted,
                  onChanged: (_) {
                    HapticFeedback.mediumImpact();
                    widget.viewModel.toggleHomework(hw.id);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Task Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            hw.subject,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              decoration: hw.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurfaceSecondary
                                : AppTheme.lightSurfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDueDate(hw.dueDate),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hw.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: hw.isCompleted
                            ? textSecondary
                            : (isDark
                                ? const Color(0xFFD4D4D8)
                                : const Color(0xFF3F3F46)),
                        height: 1.35,
                        decoration: hw.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (hw.attachmentsCount > 0 || hw.attachments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_file,
                            size: 14,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Файлы к заданию: ${hw.attachments.isNotEmpty ? hw.attachments.length : hw.attachmentsCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));
    
    final baseItemsCount = widget.viewModel.homeworks.where((item) {
      final due = DateTime.utc(item.dueDate.year, item.dueDate.month, item.dueDate.day);
      return due.compareTo(yesterday) >= 0 && due.compareTo(nextWeek) <= 0;
    }).length;

    final filtered = _getFilteredList(widget.viewModel.homeworks);
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await widget.viewModel.loadData(forceRefresh: true);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Filter Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text('Все ($baseItemsCount)'),
                      selected: _filterIndex == 0,
                      onSelected: (selected) {
                        HapticFeedback.selectionClick();
                        setState(() => _filterIndex = 0);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('На завтра'),
                      selected: _filterIndex == 1,
                      onSelected: (selected) {
                        HapticFeedback.selectionClick();
                        setState(() => _filterIndex = 1);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Сделано'),
                      selected: _filterIndex == 2,
                      onSelected: (selected) {
                        HapticFeedback.selectionClick();
                        setState(() => _filterIndex = 2);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // List of Homework Cards
          if (filtered.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final hw = filtered[index];
                  return _buildHomeworkCard(context, hw);
                },
                childCount: filtered.length,
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 56,
                      color: textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Все задания выполнены!',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }
}
