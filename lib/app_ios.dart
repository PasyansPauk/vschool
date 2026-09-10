import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'data/services/mos_id_auth_service.dart';
import 'presentation/view_models/diary_view_model.dart';
import 'presentation/view_models/school_tracker_view_model.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/main_navigation_screen.dart';

/// Dedicated iOS Application Entrypoint adhering strictly to Apple HIG,
/// CupertinoApp navigation, and custom ProMotion transitions.
class IosSchoolDiaryApp extends StatefulWidget {
  const IosSchoolDiaryApp({super.key});

  @override
  State<IosSchoolDiaryApp> createState() => _IosSchoolDiaryAppState();
}

class _IosSchoolDiaryAppState extends State<IosSchoolDiaryApp> {
  final MosIdAuthService _authService = MosIdAuthService();
  final DiaryViewModel _diaryViewModel = DiaryViewModel();
  final SchoolTrackerViewModel _trackerViewModel = SchoolTrackerViewModel();

  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final authed = await _authService.isAuthenticated();
    if (authed) {
      await _diaryViewModel.loadData();
    }
    if (mounted) {
      setState(() {
        _isAuthenticated = authed;
        _isCheckingAuth = false;
      });
    }
  }

  void _onLoginSuccess() {
    setState(() => _isAuthenticated = true);
    _diaryViewModel.loadData();
  }

  void _onLogout() {
    setState(() => _isAuthenticated = false);
  }

  @override
  void dispose() {
    _diaryViewModel.dispose();
    _trackerViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _diaryViewModel,
      builder: (context, _) {
        final isDark = _diaryViewModel.isDarkTheme;

        return CupertinoApp(
          title: 'Школьный Дневник МЭШ',
          theme: AppTheme.getCupertinoTheme(isDark: isDark),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: _isCheckingAuth
              ? CupertinoPageScaffold(
                  backgroundColor: isDark
                      ? AppTheme.darkBackground
                      : AppTheme.lightBackground,
                  child: const Center(
                    child: CupertinoActivityIndicator(radius: 16),
                  ),
                )
              : (_isAuthenticated
                  ? Material(
                      type: MaterialType.transparency,
                      child: MainNavigationScreen(
                        diaryViewModel: _diaryViewModel,
                        trackerViewModel: _trackerViewModel,
                        onLogout: _onLogout,
                      ),
                    )
                  : AuthScreen(
                      onLoginSuccess: _onLoginSuccess,
                      isDark: isDark,
                    )),
        );
      },
    );
  }
}
