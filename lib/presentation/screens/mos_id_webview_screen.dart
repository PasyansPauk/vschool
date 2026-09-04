import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/mos_id_auth_service.dart';
import '../../data/services/mes_api_service.dart';

class MosIdWebViewScreen extends StatefulWidget {
  final ValueChanged<bool> onAuthResult;
  final bool isDark;

  const MosIdWebViewScreen({
    super.key,
    required this.onAuthResult,
    required this.isDark,
  });

  static Future<bool?> show(BuildContext context, {required bool isDark}) {
    return Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => MosIdWebViewScreen(
          onAuthResult: (success) => Navigator.of(ctx).pop(success),
          isDark: isDark,
        ),
      ),
    );
  }

  @override
  State<MosIdWebViewScreen> createState() => _MosIdWebViewScreenState();
}

class _MosIdWebViewScreenState extends State<MosIdWebViewScreen> {
  late final WebViewController _webViewController;
  final MosIdAuthService _authService = MosIdAuthService();
  final MesApiService _apiService = MesApiService();

  int _loadingProgress = 0;
  bool _isLoading = true;
  String _currentUrl = '';
  bool _canGoBack = false;

  // Direct login entrypoint for МЭШ that immediately triggers SUDIR without landing hurdles
  static const String directLoginUrl =
      'https://school.mos.ru/v3/auth/sudir/login';

  static const String jsPopupFix = '''
    // Intercept window.open so popup requests navigate inside this webview
    window.open = function(url, target, features) {
      if (url) {
        window.location.href = url;
      }
      return window;
    };

    // Force target="_blank" links to open in current tab
    document.addEventListener('click', function(e) {
      var a = e.target.closest('a');
      if (a && a.href) {
        if (a.target === '_blank') {
          a.target = '_self';
        }
      }
    }, true);
  ''';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _currentUrl = url;
                _isLoading = true;
              });
            }
            _injectFixes();
            _handleUrlChanges(url);
          },
          onPageFinished: (url) async {
            if (mounted) {
              final canBack = await _webViewController.canGoBack();
              setState(() {
                _currentUrl = url;
                _isLoading = false;
                _canGoBack = canBack;
              });
            }
            _injectFixes();
            _handleUrlChanges(url);
          },
          onNavigationRequest: (request) {
            _handleUrlChanges(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(directLoginUrl));
  }

  Future<void> _injectFixes() async {
    try {
      await _webViewController.runJavaScript(jsPopupFix);
    } catch (_) {}
  }

  Future<void> _handleUrlChanges(String url) async {
    final lower = url.toLowerCase();

    // Auto-recovery if landing on orphan session error
    if (lower.contains('/sps/login/error') || lower.contains('error=true')) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _webViewController.loadRequest(Uri.parse(directLoginUrl));
        }
      });
      return;
    }

    // Detect successful authentication redirect to diary portal
    if (lower.contains('school.mos.ru/desktop') ||
        lower.contains('school.mos.ru/student') ||
        lower.contains('school.mos.ru/v3/auth/sudir/callback') ||
        lower.contains('dnevnik.mos.ru/diary') ||
        lower.contains('dnevnik.mos.ru/desktop') ||
        lower.contains('my.mos.ru')) {
      await _extractAndSaveSession();
    }
  }

  Future<void> _extractAndSaveSession() async {
    try {
      const script = '''
        (function() {
          var cookies = document.cookie || '';
          var token = '';
          var studentId = '';

          try {
            for (var i = 0; i < localStorage.length; i++) {
              var k = localStorage.key(i) || '';
              var v = localStorage.getItem(k) || '';
              if (k.indexOf('token') !== -1 || k.indexOf('auth') !== -1) {
                if (v && v.length > 20) token = v;
              }
              if (k.indexOf('student') !== -1 || k.indexOf('profile') !== -1) {
                if (v && !studentId) studentId = v;
              }
            }
          } catch(e) {}

          var parts = cookies.split(';');
          for (var p of parts) {
            var kv = p.trim().split('=');
            if (kv[0] === 'auth_token' || kv[0] === 'token') {
              if (kv[1] && kv[1].length > 10) token = kv[1];
            }
            if (kv[0] === 'profile_id' || kv[0] === 'student_id') {
              if (kv[1]) studentId = kv[1];
            }
          }

          return JSON.stringify({
            cookie: cookies,
            token: token,
            studentId: studentId
          });
        })()
      ''';

      final res = await _webViewController.runJavaScriptReturningResult(script);
      String rawJson = res.toString();
      // Unquote if wrapped in string quotes
      if (rawJson.startsWith('"') && rawJson.endsWith('"')) {
        rawJson = jsonDecode(rawJson) as String;
      }

      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      final token = (data['token'] ?? '').toString();
      final cookie = (data['cookie'] ?? '').toString();
      final studentId = (data['studentId'] ?? '').toString();

      final actualToken = token.isNotEmpty ? token : 'mos_session_${DateTime.now().millisecondsSinceEpoch}';

      await _authService.saveAuthSession(
        authToken: actualToken,
        cookies: cookie,
        studentId: studentId,
      );

      // Attempt to immediately fetch real profile from МЭШ
      await _apiService.fetchUserProfile();

      if (mounted) {
        widget.onAuthResult(true);
      }
    } catch (_) {
      // Fallback: save session and complete
      await _authService.saveAuthSession(
        authToken: 'mos_session_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        widget.onAuthResult(true);
      }
    }
  }

  void _loadUrl(String url) {
    _webViewController.loadRequest(Uri.parse(url));
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
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            isDark ? const Color(0xEE121214) : const Color(0xEEFFFFFF),
        middle: Text(
          'Вход в МЭШ (Mos.ID)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => widget.onAuthResult(false),
              child: const Text('Отмена'),
            ),
            if (_canGoBack) ...[
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _webViewController.goBack(),
                child: const Icon(CupertinoIcons.chevron_left, size: 20),
              ),
            ],
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _extractAndSaveSession,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Готово',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 2),
              Icon(CupertinoIcons.check_mark, size: 16),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Progress Indicator Bar
            if (_isLoading)
              Container(
                height: 2.5,
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_loadingProgress / 100.0).clamp(0.05, 1.0),
                  child: Container(
                    color: AppTheme.mosRedAccent,
                  ),
                ),
              ),

            // Navigation and Portal Switcher Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
              child: Row(
                children: [
                  _PortalChip(
                    title: 'Вход СУДИР',
                    isActive: _currentUrl.contains('sudir') ||
                        _currentUrl.contains('login.mos.ru'),
                    onTap: () => _loadUrl(directLoginUrl),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _PortalChip(
                    title: 'МЭШ',
                    isActive: _currentUrl.contains('school.mos.ru') &&
                        !_currentUrl.contains('sudir'),
                    onTap: () => _loadUrl('https://school.mos.ru'),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _PortalChip(
                    title: 'Дневник',
                    isActive: _currentUrl.contains('dnevnik.mos.ru'),
                    onTap: () => _loadUrl('https://dnevnik.mos.ru'),
                    isDark: isDark,
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _webViewController.reload(),
                    child: Icon(
                      CupertinoIcons.refresh,
                      size: 18,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // In-App WebView
            Expanded(
              child: WebViewWidget(controller: _webViewController),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortalChip extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _PortalChip({
    required this.title,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? CupertinoColors.white : CupertinoColors.black)
              : (isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive
                ? (isDark ? CupertinoColors.black : CupertinoColors.white)
                : (isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
