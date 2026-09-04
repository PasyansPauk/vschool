import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/homework_item.dart';
import '../view_models/diary_view_model.dart';

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
                return Container(
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
                      // Completion Checkbox
                      GestureDetector(
                        onTap: () => widget.viewModel.toggleHomework(hw.id),
                        child: Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.only(top: 2),
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
                            if (hw.attachmentsCount > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.paperclip,
                                    size: 13,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Вложений в МЭШ: ${hw.attachmentsCount}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
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
