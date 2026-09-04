import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';
import '../view_models/diary_view_model.dart';
import '../view_models/school_tracker_view_model.dart';
import '../widgets/offline_network_modal.dart';
import 'schedule_screen.dart';
import 'grades_screen.dart';
import 'homework_screen.dart';
import 'tracker_screen.dart';
import 'profile_modal.dart';

class MainNavigationScreen extends StatefulWidget {
  final DiaryViewModel diaryViewModel;
  final SchoolTrackerViewModel trackerViewModel;
  final VoidCallback onLogout;

  const MainNavigationScreen({
    super.key,
    required this.diaryViewModel,
    required this.trackerViewModel,
    required this.onLogout,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;
  bool _modalShown = false;

  @override
  void initState() {
    super.initState();
    widget.diaryViewModel.addListener(_handleViewModelUpdates);
  }

  @override
  void dispose() {
    widget.diaryViewModel.removeListener(_handleViewModelUpdates);
    super.dispose();
  }

  void _handleViewModelUpdates() {
    if (!mounted) return;
    // If error banner is flagged and modal not currently shown
    if (widget.diaryViewModel.showVpnOrOfflineBanner && !_modalShown) {
      _modalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        OfflineNetworkModal.show(
          context,
          errorMessage: widget.diaryViewModel.errorMessage,
          onDismiss: () {
            _modalShown = false;
            widget.diaryViewModel.dismissErrorBanner();
          },
          onRetry: () {
            _modalShown = false;
            widget.diaryViewModel.loadData(forceRefresh: true);
          },
          isDark: widget.diaryViewModel.isDarkTheme,
        );
      });
    }
  }

  String _getTitleForTab(int index) {
    switch (index) {
      case 0:
        return 'Расписание';
      case 1:
        return 'Оценки МЭШ';
      case 2:
        return 'Домашние задания';
      case 3:
        return 'Школа-Трекер';
      default:
        return 'Дневник';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.diaryViewModel, widget.trackerViewModel]),
      builder: (context, _) {
        final isDark = widget.diaryViewModel.isDarkTheme;
        final textPrimary =
            isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
        final profile = widget.diaryViewModel.profile;

        return CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            currentIndex: _currentTabIndex,
            onTap: (index) {
              setState(() => _currentTabIndex = index);
            },
            backgroundColor: isDark
                ? const Color(0xEE121214)
                : const Color(0xEEFFFFFF),
            activeColor:
                isDark ? CupertinoColors.white : CupertinoColors.black,
            inactiveColor:
                isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
            iconSize: 22,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.calendar),
                label: 'Расписание',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chart_bar_square),
                label: 'Оценки',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.checkmark_square),
                label: 'Домашка',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.stopwatch),
                label: 'Трекер',
              ),
            ],
          ),
          tabBuilder: (context, index) {
            return CupertinoPageScaffold(
              backgroundColor: isDark
                  ? AppTheme.darkBackground
                  : AppTheme.lightBackground,
              navigationBar: CupertinoNavigationBar(
                backgroundColor: isDark
                    ? const Color(0xCC121214)
                    : const Color(0xCCFFFFFF),
                middle: Text(
                  _getTitleForTab(index),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurfaceSecondary
                          : AppTheme.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      profile?.className.isNotEmpty == true
                          ? profile!.className
                          : 'МЭШ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ProfileModal.show(
                      context,
                      viewModel: widget.diaryViewModel,
                      onLogout: widget.onLogout,
                      isDark: isDark,
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        profile != null && profile.fullName.isNotEmpty
                            ? profile.fullName.substring(0, 1)
                            : 'У',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? CupertinoColors.black
                              : CupertinoColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: _buildTabContent(index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabContent(int index) {
    final isDark = widget.diaryViewModel.isDarkTheme;

    switch (index) {
      case 0:
        return ScheduleScreen(
          diaryViewModel: widget.diaryViewModel,
          trackerViewModel: widget.trackerViewModel,
          isDark: isDark,
        );
      case 1:
        return GradesScreen(
          viewModel: widget.diaryViewModel,
          isDark: isDark,
        );
      case 2:
        return HomeworkScreen(
          viewModel: widget.diaryViewModel,
          isDark: isDark,
        );
      case 3:
        return TrackerScreen(
          diaryViewModel: widget.diaryViewModel,
          trackerViewModel: widget.trackerViewModel,
          isDark: isDark,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
