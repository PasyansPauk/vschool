import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../view_models/diary_view_model.dart';
import '../../view_models/school_tracker_view_model.dart';
import '../../widgets/offline_network_modal.dart';
import 'android_schedule_screen.dart';
import 'android_grades_screen.dart';
import 'android_homework_screen.dart';
import 'android_tracker_screen.dart';
import 'android_profile_modal.dart';

class AndroidMainNavigationScreen extends StatefulWidget {
  final DiaryViewModel diaryViewModel;
  final SchoolTrackerViewModel trackerViewModel;
  final VoidCallback onLogout;

  const AndroidMainNavigationScreen({
    super.key,
    required this.diaryViewModel,
    required this.trackerViewModel,
    required this.onLogout,
  });

  @override
  State<AndroidMainNavigationScreen> createState() => _AndroidMainNavigationScreenState();
}

class _AndroidMainNavigationScreenState extends State<AndroidMainNavigationScreen> {
  int _currentTabIndex = 0;
  bool _modalShown = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTabIndex);
    widget.diaryViewModel.addListener(_handleViewModelUpdates);
  }

  @override
  void dispose() {
    _pageController.dispose();
    widget.diaryViewModel.removeListener(_handleViewModelUpdates);
    super.dispose();
  }

  void _handleViewModelUpdates() {
    if (!mounted) return;
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

  void _onTabTapped(int index) {
    if (index != _currentTabIndex) {
      HapticFeedback.selectionClick();
      setState(() => _currentTabIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.diaryViewModel, widget.trackerViewModel]),
      builder: (context, _) {
        final isDark = widget.diaryViewModel.isDarkTheme;
        final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
        final profile = widget.diaryViewModel.profile;

        return PopScope(
          canPop: _currentTabIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_currentTabIndex != 0) {
              _onTabTapped(0);
            }
          },
          child: Scaffold(
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            appBar: AppBar(
              backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              elevation: 0,
              scrolledUnderElevation: 2,
              title: Text(
                _getTitleForTab(_currentTabIndex),
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              leading: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfaceSecondary
                        : AppTheme.lightSurfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    profile?.className.isNotEmpty == true
                        ? profile!.className
                        : 'МЭШ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: CircleAvatar(
                      radius: 16,
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      child: Text(
                        profile != null && profile.fullName.isNotEmpty
                            ? profile.fullName.substring(0, 1)
                            : 'У',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    onPressed: () {
                      AndroidProfileModal.show(
                        context,
                        viewModel: widget.diaryViewModel,
                        onLogout: widget.onLogout,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
              ],
            ),
            body: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                HapticFeedback.lightImpact();
                setState(() => _currentTabIndex = index);
              },
              children: [
                AndroidScheduleScreen(
                  diaryViewModel: widget.diaryViewModel,
                  trackerViewModel: widget.trackerViewModel,
                  isDark: isDark,
                ),
                AndroidGradesScreen(
                  viewModel: widget.diaryViewModel,
                  isDark: isDark,
                ),
                AndroidHomeworkScreen(
                  viewModel: widget.diaryViewModel,
                  isDark: isDark,
                ),
                AndroidTrackerScreen(
                  diaryViewModel: widget.diaryViewModel,
                  trackerViewModel: widget.trackerViewModel,
                  isDark: isDark,
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentTabIndex,
              onDestinationSelected: _onTabTapped,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today),
                  label: 'Расписание',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Оценки',
                ),
                NavigationDestination(
                  icon: Icon(Icons.checklist_outlined),
                  selectedIcon: Icon(Icons.checklist),
                  label: 'Домашка',
                ),
                NavigationDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer),
                  label: 'Трекер',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
