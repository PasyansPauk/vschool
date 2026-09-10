import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'data/services/mos_id_auth_service.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/main_navigation_screen.dart';
import 'presentation/view_models/diary_view_model.dart';
import 'presentation/view_models/school_tracker_view_model.dart';

/// Dedicated Android Application Entrypoint matching iOS HIG design,
/// CupertinoApp navigation, ProMotion spring animations, and docked Liquid Glass navigation.
class AndroidSchoolDiaryApp extends StatefulWidget {
  const AndroidSchoolDiaryApp({super.key});

  @override
  State<AndroidSchoolDiaryApp> createState() => _AndroidSchoolDiaryAppState();
}

class _AndroidSchoolDiaryAppState extends State<AndroidSchoolDiaryApp> {
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

        final systemOverlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemOverlayStyle,
          child: CupertinoApp(
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
          ),
        );
      },
    );
  }
}
