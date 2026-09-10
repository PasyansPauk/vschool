import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/homework_item.dart';
import '../view_models/diary_view_model.dart';
import '../widgets/lesson_card.dart';
import '../widgets/promotion_bouncing_card.dart';
import '../widgets/promotion_morph_route.dart';

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

  void _showHomeworkDetails(BuildContext context, HomeworkItem hw, [Rect? sourceRect]) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final tileBg =
        isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary;

    final rect = sourceRect ?? () {
      final rb = context.findRenderObject() as RenderBox?;
      if (rb != null && rb.hasSize) {
        final origin = rb.localToGlobal(Offset.zero);
        return Rect.fromLTWH(origin.dx, origin.dy, rb.size.width, rb.size.height);
      }
      final size = MediaQuery.of(context).size;
      return Rect.fromLTWH(16, size.height / 2 - 80, size.width - 32, 160);
    }();

    showProMotionCardModal(
      context: context,
      sourceRect: rect,
      sourceRadius: 20.0,
      targetRadius: 26.0,
      isDark: isDark,
      collapsedChild: _buildHomeworkCard(context, hw),
      builder: (ctx, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subject Title, Icon & Top-Right Close Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LessonCard.getSubjectIcon(hw.subject),
                    size: 21,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(width: 12),
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
                          letterSpacing: -0.3,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Срок сдачи: ${_formatDueDate(hw.dueDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Sleek iOS Circular Close Button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x28FFFFFF) : const Color(0x14000000),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 13,
                      color: isDark ? const Color(0xCCFFFFFF) : const Color(0x88000000),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),

            // Assignment Description Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x18FFFFFF) : const Color(0x0C000000),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0E000000),
                  width: 0.6,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.doc_text_fill,
                        size: 12,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'ТЕКСТ ЗАДАНИЯ',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hw.description.isNotEmpty
                        ? hw.description
                        : 'Описание отсутствует',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Attachments / Files from МЭШ
            if (hw.attachments.isNotEmpty) ...[
              const SizedBox(height: 11),
              Text(
                'Прикрепленные файлы (${hw.attachments.length})',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              ...hw.attachments.map((att) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    color: tileBg,
                    borderRadius: BorderRadius.circular(11),
                    onPressed: () => _openAttachment(context, att),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.doc_fill,
                          size: 16,
                          color: CupertinoColors.activeBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            att.title.isNotEmpty ? att.title : 'Файл',
                            style: TextStyle(
                              fontSize: 13,
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          CupertinoIcons.cloud_download,
                          size: 16,
                          color: textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 13),

            // Complete / Uncomplete action button inside details
            CupertinoButton(
              color: hw.isCompleted
                  ? AppTheme.grade2Color.withValues(alpha: 0.15)
                  : CupertinoColors.activeGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.viewModel.toggleHomework(hw.id);
                Navigator.of(ctx).pop();
              },
              child: Text(
                hw.isCompleted
                    ? 'Вернуть в невыполненные'
                    : 'Отметить как выполненное ✓',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: hw.isCompleted
                      ? AppTheme.grade2Color
                      : CupertinoColors.activeGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

          // Task Details Area
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    
    // Calculate base items count (for the 'Все' tab)
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

        // Filter Bar - Liquid Glass Segmented Control
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: GlassSegmentedControl(
              segments: [
                GlassSegment(label: 'Все ($baseItemsCount)'),
                const GlassSegment(label: 'На завтра'),
                const GlassSegment(label: 'Сделано'),
              ],
              selectedIndex: _filterIndex,
              onSegmentSelected: (val) {
                HapticFeedback.selectionClick();
                setState(() => _filterIndex = val);
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

                final cardContent = ProMotionBouncingCard(
                  onTap: (ctx, sourceRect) => _showHomeworkDetails(ctx, hw, sourceRect),
                  child: _buildHomeworkCard(context, hw),
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
          child: SizedBox(height: 120),
        ),
      ],
    );
  }
}
