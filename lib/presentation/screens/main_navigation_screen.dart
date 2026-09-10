import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            if (!didPop && _currentTabIndex != 0) {
              _onTabTapped(0);
            }
          },
          child: Scaffold(
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            extendBody: true,
            body: Stack(
              children: [
                PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    HapticFeedback.lightImpact();
                    setState(() => _currentTabIndex = index);
                  },
                  children: [
                    _buildPage(0, isDark, textPrimary, profile),
                    _buildPage(1, isDark, textPrimary, profile),
                    _buildPage(2, isDark, textPrimary, profile),
                    _buildPage(3, isDark, textPrimary, profile),
                  ],
                ),
                
                // Docked Liquid Glass Tab Bar (Apple native bottom bar)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0x75121214)
                              : const Color(0x85FFFFFF),
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? const Color(0x28FFFFFF)
                                  : const Color(0x20000000),
                              width: 0.5,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom,
                        ),
                        height: 52 + MediaQuery.of(context).padding.bottom,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDockedTabItem(
                              index: 0,
                              icon: CupertinoIcons.calendar,
                              label: 'Расписание',
                              isDark: isDark,
                            ),
                            _buildDockedTabItem(
                              index: 1,
                              icon: CupertinoIcons.chart_bar_square,
                              label: 'Оценки',
                              isDark: isDark,
                            ),
                            _buildDockedTabItem(
                              index: 2,
                              icon: CupertinoIcons.checkmark_square,
                              label: 'Домашка',
                              isDark: isDark,
                            ),
                            _buildDockedTabItem(
                              index: 3,
                              icon: CupertinoIcons.stopwatch,
                              label: 'Трекер',
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDockedTabItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = index == _currentTabIndex;
    final selectedColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    const unselectedColor = Color(0xFF8E8E93);
    final color = isSelected ? selectedColor : unselectedColor;

    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _onTabTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index, bool isDark, Color textPrimary, dynamic profile) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark
            ? const Color(0x70121214) // Liquid Glass (44% opacity)
            : const Color(0x70FFFFFF),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
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
                  color: isDark ? CupertinoColors.black : CupertinoColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _buildTabContent(index, isDark),
      ),
    );
  }

  Widget _buildTabContent(int index, bool isDark) {
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
