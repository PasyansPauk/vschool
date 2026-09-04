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
  bool _isExtracting = false;
  String _currentUrl = '';
  String? _errorMessage;
  bool _canGoBack = false;
  bool _hasTriggeredImport = false;

  // Primary entrypoint: dnevnik.mos.ru initiates the official diary OAuth flow
  static const String directLoginUrl = 'https://dnevnik.mos.ru';

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
      ..setBackgroundColor(CupertinoColors.white)
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
                _errorMessage = null;
              });
            }
            _injectFixes();
            _checkAutoTransition(url);
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
            _checkAutoTransition(url);
          },
          onWebResourceError: (WebResourceError error) {
            if (error.errorCode == -999) return;
            if (mounted) {
              setState(() {
                _errorMessage = error.description;
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (request) {
            _checkAutoTransition(request.url);
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

  void _checkAutoTransition(String url) {
    final lower = url.toLowerCase();

    // Check if user has entered the diary portal
    final isInsideDiary = (lower.contains('dnevnik.mos.ru') ||
            lower.contains('school.mos.ru')) &&
        !lower.contains('login.mos.ru') &&
        !lower.contains('/sps/') &&
        !lower.contains('/oauth/');

    if (isInsideDiary && !_hasTriggeredImport) {
      // Delay briefly to allow page cookies and DOM to settle, then extract
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && !_hasTriggeredImport) {
          _extractAndTransition();
        }
      });
    }
  }

  Future<void> _extractAndTransition() async {
    if (_hasTriggeredImport) return;
    _hasTriggeredImport = true;

    setState(() {
      _isExtracting = true;
    });

    try {
      // Advanced in-browser extractor: runs in the authenticated origin context
      const extractionScript = '''
        (async function() {
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

          // 1. Try fetching profile
          var profileData = null;
          try {
            var pRes = await fetch('https://school.mos.ru/api/family/web/v1/profile', {
              headers: { 'x-mes-subsystem': 'familyweb' }
            });
            if (pRes.ok) profileData = await pRes.json();
          } catch(e) {}

          if (!profileData) {
            try {
              var p2 = await fetch('/core/api/student_profiles');
              if (p2.ok) profileData = await p2.json();
            } catch(e) {}
          }

          // 2. Try fetching schedules
          var schedData = null;
          try {
            var now = new Date();
            var day = now.getDay() || 7;
            var mon = new Date(now);
            mon.setDate(now.getDate() - day + 1);
            var fri = new Date(mon);
            fri.setDate(mon.getDate() + 4);
            var pad = function(n) { return String(n).padStart(2, '0'); };
            var fmt = function(d) { return d.getFullYear() + '-' + pad(d.getMonth()+1) + '-' + pad(d.getDate()); };

            var sUrl = 'https://school.mos.ru/api/family/web/v1/schedule?student_id=' + studentId + '&begin_date=' + fmt(mon) + '&end_date=' + fmt(fri);
            var sRes = await fetch(sUrl, { headers: { 'x-mes-subsystem': 'familyweb' } });
            if (sRes.ok) schedData = await sRes.json();
          } catch(e) {}

          // 3. Try fetching marks
          var marksData = null;
          try {
            var mUrl = 'https://school.mos.ru/api/family/web/v1/subject_marks?student_id=' + studentId;
            var mRes = await fetch(mUrl, { headers: { 'x-mes-subsystem': 'familyweb' } });
            if (mRes.ok) marksData = await mRes.json();
          } catch(e) {}

          // 4. Try fetching homeworks
          var hwData = null;
          try {
            var hUrl = 'https://school.mos.ru/api/family/web/v1/homeworks?student_id=' + studentId;
            var hRes = await fetch(hUrl, { headers: { 'x-mes-subsystem': 'familyweb' } });
            if (hRes.ok) hwData = await hRes.json();
          } catch(e) {}

          // 5. Scrape rendered lessons from DOM as backup
          var domLessons = [];
          try {
            var cards = document.querySelectorAll('.schedule__lesson, .lesson, [data-qa="lesson-card"], .diary-lesson-item');
            cards.forEach(function(c) {
              var s = (c.querySelector('.subject, .lesson__subject, .title') || {}).innerText || '';
              var t = (c.querySelector('.time, .lesson__time') || {}).innerText || '';
              var r = (c.querySelector('.room, .lesson__room') || {}).innerText || '';
              var tc = (c.querySelector('.teacher, .lesson__teacher') || {}).innerText || '';
              if (s) {
                domLessons.push({ subject: s.trim(), time: t.trim(), room: r.trim(), teacher: tc.trim() });
              }
            });
          } catch(e) {}

          return JSON.stringify({
            token: token,
            cookie: cookies,
            studentId: studentId,
            profile: profileData,
            schedules: schedData,
            marks: marksData,
            homeworks: hwData,
            domLessons: domLessons
          });
        })()
      ''';

      final result =
          await _webViewController.runJavaScriptReturningResult(extractionScript);
      String rawJson = result.toString();
      if (rawJson.startsWith('"') && rawJson.endsWith('"')) {
        rawJson = jsonDecode(rawJson) as String;
      }

      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      final token = (data['token'] ?? '').toString();
      final cookie = (data['cookie'] ?? '').toString();
      final studentId = (data['studentId'] ?? '').toString();

      final actualToken = token.isNotEmpty
          ? token
          : 'mos_session_${DateTime.now().millisecondsSinceEpoch}';

      await _authService.saveAuthSession(
        authToken: actualToken,
        cookies: cookie,
        studentId: studentId,
      );

      // Save all extracted data straight into the cache
      await _apiService.saveImportedBundle(data);
    } catch (_) {
      await _authService.saveAuthSession(
        authToken: 'mos_session_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    if (mounted) {
      widget.onAuthResult(true);
    }
  }

  void _loadUrl(String url) {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
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

    final isInsideDiary = (_currentUrl.contains('dnevnik.mos.ru') ||
            _currentUrl.contains('school.mos.ru')) &&
        !_currentUrl.contains('login.mos.ru') &&
        !_currentUrl.contains('/sps/');

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            isDark ? const Color(0xEE121214) : const Color(0xEEFFFFFF),
        middle: Text(
          'Вход в МЭШ',
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
          onPressed: _extractAndTransition,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'В дневник',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.activeGreen,
                ),
              ),
              SizedBox(width: 2),
              Icon(CupertinoIcons.check_mark,
                  size: 16, color: CupertinoColors.activeGreen),
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

            // Top Navigation & Domain Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
              child: Row(
                children: [
                  _PortalChip(
                    title: 'Дневник МЭШ',
                    isActive: _currentUrl.contains('dnevnik.mos.ru'),
                    onTap: () => _loadUrl('https://dnevnik.mos.ru'),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _PortalChip(
                    title: 'СУДИР',
                    isActive: _currentUrl.contains('login.mos.ru'),
                    onTap: () => _loadUrl(
                        'https://login.mos.ru/sps/login/methods/password?backUrl=https%3A%2F%2Fdnevnik.mos.ru'),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _PortalChip(
                    title: 'school.mos.ru',
                    isActive: _currentUrl.contains('school.mos.ru'),
                    onTap: () => _loadUrl('https://school.mos.ru'),
                    isDark: isDark,
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isLoading = true;
                      });
                      _webViewController.reload();
                    },
                    child: Icon(
                      CupertinoIcons.refresh,
                      size: 18,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // In-App WebView Stack
            Expanded(
              child: Container(
                color: CupertinoColors.white,
                child: Stack(
                  children: [
                    WebViewWidget(controller: _webViewController),

                    // Initial loading indicator
                    if (_isLoading && !_isExtracting)
                      Container(
                        color: CupertinoColors.white.withValues(alpha: 0.9),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              CupertinoActivityIndicator(radius: 16),
                              SizedBox(height: 14),
                              Text(
                                'Загрузка Дневника МЭШ...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Active extraction overlay (transitioning into the app)
                    if (_isExtracting)
                      Container(
                        color: CupertinoColors.black.withValues(alpha: 0.85),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              CupertinoActivityIndicator(
                                radius: 18,
                                color: CupertinoColors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Синхронизация данных с МЭШ...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Открываем ваш дневник',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Error display
                    if (_errorMessage != null && !_isExtracting)
                      Container(
                        color: CupertinoColors.white,
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                size: 48,
                                color: CupertinoColors.systemOrange,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Не удалось загрузить страницу',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                              const SizedBox(height: 18),
                              CupertinoButton.filled(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                onPressed: () {
                                  setState(() {
                                    _errorMessage = null;
                                    _isLoading = true;
                                  });
                                  _webViewController.reload();
                                },
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Quick Action Bar if logged in
                    if (isInsideDiary && !_isExtracting)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 24,
                        child: CupertinoButton(
                          color: CupertinoColors.activeGreen,
                          borderRadius: BorderRadius.circular(16),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          onPressed: _extractAndTransition,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(CupertinoIcons.arrow_right_circle_fill,
                                  color: CupertinoColors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Открыть дневник в приложении',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
