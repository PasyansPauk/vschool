import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/mos_id_auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final bool isDark;

  const AuthScreen({
    super.key,
    required this.onLoginSuccess,
    required this.isDark,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final MosIdAuthService _authService = MosIdAuthService();
  bool _isConnecting = false;

  Future<void> _handleMosIdLogin() async {
    setState(() => _isConnecting = true);
    // Launch browser with official login.mos.ru
    await _authService.launchMosIdWebsite();

    if (!mounted) return;

    // Show confirmation dialog after returning from browser
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Авторизация Mos.ID'),
        content: const Text(
          'Вы перешли на портал mos.ru для авторизации в СУДИР. Подтвердить успешный вход и синхронизацию профиля МЭШ?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isConnecting = false);
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Войти'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _authService.loginWithMosIdSuccess();
              if (mounted) {
                setState(() => _isConnecting = false);
                widget.onLoginSuccess();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleDemoLogin() async {
    setState(() => _isConnecting = true);
    await _authService.loginWithMosIdSuccess();
    if (mounted) {
      setState(() => _isConnecting = false);
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return CupertinoPageScaffold(
      backgroundColor: bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Aesthetic App Logo (Minimalist Monogram)
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceElevated : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.book_fill,
                    size: 42,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Brand Title
              Text(
                'Электронный Дневник',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.6,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Московская электронная школа • МЭШ',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 36),

              // Feature Highlights in Samsung / Apple pill style
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _FeatureRow(
                      icon: CupertinoIcons.calendar_today,
                      title: 'Расписание и кабинеты',
                      subtitle: 'Уроки, звонки и ФИО преподавателей',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _FeatureRow(
                      icon: CupertinoIcons.chart_bar_alt_fill,
                      title: 'Оценки с весами МЭШ',
                      subtitle: 'Расчет точного среднего балла',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _FeatureRow(
                      icon: CupertinoIcons.stopwatch,
                      title: 'Живой трекер времени',
                      subtitle: 'Посекундный учет времени в школе',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _FeatureRow(
                      icon: CupertinoIcons.cloud_download,
                      title: 'Офлайн-доступ из кэша',
                      subtitle: 'Работает даже при выключенном интернете',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Mos.ID Official Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: _isConnecting ? null : _handleMosIdLogin,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppTheme.mosRedAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Text(
                            'М',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Войти через Mos.ID',
                        style: TextStyle(
                          color: isDark
                              ? CupertinoColors.black
                              : CupertinoColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quick Demo Login Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: isDark
                      ? AppTheme.darkSurfaceSecondary
                      : AppTheme.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _isConnecting ? null : _handleDemoLogin,
                  child: Text(
                    'Быстрый демо-вход',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Text(
                'Авторизация через СУДИР г. Москвы',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF202024) : const Color(0xFFEBEBF0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
