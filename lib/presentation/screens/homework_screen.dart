import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/homework_item.dart';
import '../view_models/diary_view_model.dart';
import '../widgets/lesson_card.dart';

class HomeworkScreen extends StatefulWidget {
  final DiaryViewModel viewModel;
  final bool isDark;

  const HomeworkScreen({
    super.key,
    required this.viewModel,
    required this.isDark,
  });

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  int _filterIndex = 0; // 0: Все, 1: На завтра, 2: Готово

  List<HomeworkItem> _getFilteredList(List<HomeworkItem> items) {
    if (_filterIndex == 1) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      return items.where((item) {
        return item.dueDate.day == tomorrow.day &&
            item.dueDate.month == tomorrow.month &&
            !item.isCompleted;
      }).toList();
    } else if (_filterIndex == 2) {
      return items.where((item) => item.isCompleted).toList();
    }
    return items;
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
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Файл'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showHomeworkDetails(BuildContext context, HomeworkItem hw) {
    HapticFeedback.lightImpact();
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final tileBg =
        isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // iOS Grab Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3F3F46)
                          : const Color(0xFFD4D4D8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Subject Title & Emoji
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tileBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        LessonCard.getSubjectEmoji(hw.subject),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hw.subject,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Срок сдачи: ${hw.dueDate.day}.${hw.dueDate.month.toString().padLeft(2, '0')}.${hw.dueDate.year}',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Assignment Description Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.doc_text_fill,
                            size: 15,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Текст задания',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hw.description.isNotEmpty
                            ? hw.description
                            : 'Описание отсутствует',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Attachments / Files from МЭШ
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        color: tileBg,
                        borderRadius: BorderRadius.circular(14),
                        onPressed: () => _openAttachment(context, att),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.arrow_down_doc_fill,
                              size: 20,
                              color: CupertinoColors.activeBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                att.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.cloud_download,
                              size: 18,
                              color: CupertinoColors.activeBlue,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ] else if (hw.attachmentsCount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tileBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.paperclip,
                            size: 16, color: textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'В электронном журнале прикреплено файлов: ${hw.attachmentsCount}',
                          style: TextStyle(fontSize: 13, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Toggle Completed Button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: hw.isCompleted
                        ? AppTheme.grade2Color.withValues(alpha: 0.15)
                        : CupertinoColors.activeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                        color: hw.isCompleted
                            ? AppTheme.grade2Color
                            : CupertinoColors.activeGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Закрыть',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final filtered = _getFilteredList(widget.viewModel.homeworks);

    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await widget.viewModel.loadData(forceRefresh: true);
          },
        ),

        // Filter Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _filterIndex,
              children: {
                0: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Все (${widget.viewModel.homeworks.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                1: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'На завтра',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                2: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Сделано',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
              },
              onValueChanged: (val) {
                if (val != null) {
                  HapticFeedback.selectionClick();
                  setState(() => _filterIndex = val);
                }
              },
            ),
          ),
        ),

        // Homework Cards List
        if (filtered.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final hw = filtered[index];

                final cardContent = Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Completion Checkbox (Strictly touches only this item!)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.viewModel.toggleHomework(hw.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14, bottom: 4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: hw.isCompleted
                                  ? (isDark
                                      ? CupertinoColors.white
                                      : CupertinoColors.black)
                                  : CupertinoColors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hw.isCompleted
                                    ? (isDark
                                        ? CupertinoColors.white
                                        : CupertinoColors.black)
                                    : textSecondary,
                                width: 1.5,
                              ),
                            ),
                            child: hw.isCompleted
                                ? Icon(
                                    CupertinoIcons.check_mark,
                                    size: 16,
                                    color: isDark
                                        ? CupertinoColors.black
                                        : CupertinoColors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),

                      // Task Details Tap Area
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showHomeworkDetails(context, hw),
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
                                      'к ${hw.dueDate.day}.${hw.dueDate.month.toString().padLeft(2, '0')}',
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
                                      CupertinoIcons.paperclip,
                                      size: 13,
                                      color: CupertinoColors.activeBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Файлы к заданию: ${hw.attachments.isNotEmpty ? hw.attachments.length : hw.attachmentsCount}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.activeBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                // iOS 3D Touch / Context Menu Preview on Long Press
                return CupertinoContextMenu(
                  actions: [
                    CupertinoContextMenuAction(
                      trailingIcon: hw.isCompleted
                          ? CupertinoIcons.arrow_counterclockwise
                          : CupertinoIcons.checkmark_circle_fill,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                        widget.viewModel.toggleHomework(hw.id);
                      },
                      child: Text(hw.isCompleted
                          ? 'Снять отметку'
                          : 'Отметить выполненным'),
                    ),
                    CupertinoContextMenuAction(
                      trailingIcon: CupertinoIcons.info_circle,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showHomeworkDetails(context, hw);
                      },
                      child: const Text('Подробнее'),
                    ),
                  ],
                  child: cardContent,
                );
              },
              childCount: filtered.length,
            ),
          )
        else
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_seal,
                    size: 48,
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
          child: SizedBox(height: 32),
        ),
      ],
    );
  }
}
