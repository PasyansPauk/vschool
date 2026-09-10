import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../screens/mos_id_webview_screen.dart';

class AndroidAuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final bool isDark;

  const AndroidAuthScreen({
    super.key,
    required this.onLoginSuccess,
    required this.isDark,
  });

  @override
  State<AndroidAuthScreen> createState() => _AndroidAuthScreenState();
}

class _AndroidAuthScreenState extends State<AndroidAuthScreen> {
  bool _isConnecting = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'v${info.version} (Build ${info.buildNumber})';
      });
    }
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // App Logo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurfaceElevated
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
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
              const SizedBox(height: 24),

              Text(
                'vSchool',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Электронный дневник школьника МЭШ',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Mos.ID Login Button
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.mosRedAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isConnecting ? null : _handleMosIdLogin,
                child: _isConnecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Войти через Mos.ID',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              if (_version.isNotEmpty)
                Text(
                  _version,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary.withValues(alpha: 0.6),
                  ),
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
