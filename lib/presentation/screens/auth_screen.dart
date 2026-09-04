import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/app_theme.dart';
import 'mos_id_webview_screen.dart';

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
  bool _isConnecting = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = 'v${info.version} (Build ${info.buildNumber})';
    });
  }

  Future<void> _handleMosIdLogin() async {
    setState(() => _isConnecting = true);

    final success = await MosIdWebViewScreen.show(
      context,
      isDark: widget.isDark,
    );

    if (!mounted) return;
    setState(() => _isConnecting = false);

    if (success == true) {
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
      child: Stack(
        children: [
          SafeArea(
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
                      color: isDark
                          ? AppTheme.darkSurfaceElevated
                          : CupertinoColors.white,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
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

                  const SizedBox(height: 16),
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
          Positioned(
            top: 60, // Adjust for safe area
            left: 20,
            child: Text(
              _version.isNotEmpty ? _version : 'Загрузка...',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
