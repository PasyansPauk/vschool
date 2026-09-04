import 'dart:async';
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
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  final MosIdAuthService _authService = MosIdAuthService();
  final MesApiService _apiService = MesApiService();

  int _loadingProgress = 0;
  bool _isLoading = true;
  bool _isExtracting = false;
  String _currentUrl = '';
  String? _errorMessage;
  bool _canGoBack = false;

  bool _hasVisitedLoginPage = false;
  bool _syncAttemptStarted = false;
  String _statusText = '';
  Timer? _pollingTimer;

  static const String _startUrl = 'https://dnevnik.mos.ru';

  static const String _jsPopupFix = r'''
    window.open = function(url, target, features) {
      if (url) { window.location.href = url; }
      return window;
    };
    document.addEventListener('click', function(e) {
      var a = e.target.closest('a');
      if (a && a.href && a.target === '_blank') {
        a.target = '_self';
      }
    }, true);
  ''';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(CupertinoColors.white)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) '
        'Version/17.5 Mobile/15E148 Safari/604.1',
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
            if (url.contains('login.mos.ru') || url.contains('/sps/')) {
              _hasVisitedLoginPage = true;
            }
            _injectFixes();
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
            if (url.contains('login.mos.ru') || url.contains('/sps/')) {
              _hasVisitedLoginPage = true;
            }
            _injectFixes();
            _checkIfAuthCompleted(url);
          },
          onWebResourceError: (WebResourceError error) {
            if (error.errorCode == -999) return;
            if (_isExtracting) return;
            if (mounted) {
              setState(() {
                _errorMessage = error.description;
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_startUrl));
  }

  void _checkIfAuthCompleted(String url) {
    final isBackOnService = url.contains('dnevnik.mos.ru') ||
        url.contains('school.mos.ru');
    final isStillOnLogin =
        url.contains('login.mos.ru') || url.contains('/sps/');

    if (isBackOnService && !isStillOnLogin && _hasVisitedLoginPage && !_syncAttemptStarted) {
      _startDataSyncLoop();
    }
  }

  Future<void> _injectFixes() async {
    try {
      await _webViewController.runJavaScript(_jsPopupFix);
    } catch (_) {}
  }

  void _startDataSyncLoop() {
    _syncAttemptStarted = true;
    setState(() {
      _statusText = 'Авторизация успешна. Загружаем данные...';
    });

    int attempts = 0;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1600), (timer) async {
      attempts++;
      final success = await _attemptDataExtraction();
      if (success) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _statusText = 'Данные получены! Открываем дневник...';
          });
          await Future.delayed(const Duration(milliseconds: 500));
          widget.onAuthResult(true);
        }
      } else if (attempts >= 12) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _statusText = 'Дневник открыт. Нажмите зелёную кнопку ниже.';
          });
        }
      }
    });
  }

  Future<String> _extractAllHttpCookies() async {
    final domains = [
      Uri.parse('https://school.mos.ru'),
      Uri.parse('https://dnevnik.mos.ru'),
      Uri.parse('https://mos.ru'),
    ];

    final Map<String, String> cookiesMap = {};
    for (final domain in domains) {
      try {
        final list = await _cookieManager.getCookies(domain: domain);
        for (final c in list) {
          if (c.name.isNotEmpty && c.value.isNotEmpty) {
            cookiesMap[c.name] = c.value;
          }
        }
      } catch (_) {}
    }

    return cookiesMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  Future<bool> _attemptDataExtraction() async {
    try {
      final httpCookies = await _extractAllHttpCookies();

      const extractionScript = r'''
        (async function() {
          var cookies = '';
          var token = '';
          var studentId = '';

          try { cookies = document.cookie || ''; } catch(e) {}

          // 1. Check localStorage
          try {
            for (var i = 0; i < localStorage.length; i++) {
              var k = localStorage.key(i) || '';
              var v = localStorage.getItem(k) || '';
              if ((k === 'auth-token' || k === 'auth_token' || k === 'token' ||
                   k.indexOf('auth') !== -1) && v && v.length > 20) {
                token = v;
              }
              if ((k === 'student_id' || k === 'studentId' || k === 'profile_id') && v) {
                studentId = v;
              }
            }
          } catch(e) {}

          // 2. Try fetching profile via internal fetch (uses WebView credentials)
          var profileData = null;
          try {
            var pRes = await fetch('https://school.mos.ru/api/family/web/v1/profile', {
              headers: { 'x-mes-subsystem': 'familyweb' },
              credentials: 'include'
            });
            if (pRes.ok) {
              profileData = await pRes.json();
              if (profileData) {
                var children = profileData['children'] || profileData['payload'] || [];
                if (Array.isArray(children) && children.length > 0) {
                  studentId = String(children[0]['id'] || children[0]['student_id'] || '');
                }
              }
            }
          } catch(e) {}

          if (!profileData) {
            try {
              var p2 = await fetch('/core/api/student_profiles', { credentials: 'include' });
              if (p2.ok) profileData = await p2.json();
            } catch(e) {}
          }

          // 3. Try fetching schedule if studentId is present
          var schedData = null;
          if (studentId) {
            try {
              var now = new Date();
              var day = now.getDay() || 7;
              var mon = new Date(now); mon.setDate(now.getDate() - day + 1);
              var fri = new Date(mon); fri.setDate(mon.getDate() + 4);
              var pad = function(n) { return String(n).padStart(2,'0'); };
              var fmt = function(d) { return d.getFullYear()+'-'+pad(d.getMonth()+1)+'-'+pad(d.getDate()); };
              var sRes = await fetch(
                'https://school.mos.ru/api/family/web/v1/schedule?student_id='+studentId+'&begin_date='+fmt(mon)+'&end_date='+fmt(fri),
                { headers: {'x-mes-subsystem':'familyweb'}, credentials:'include' }
              );
              if (sRes.ok) schedData = await sRes.json();
            } catch(e) {}
          }

          // 4. Try fetching marks
          var marksData = null;
          if (studentId) {
            try {
              var mRes = await fetch(
                'https://school.mos.ru/api/family/web/v1/subject_marks?student_id='+studentId,
                { headers: {'x-mes-subsystem':'familyweb'}, credentials:'include' }
              );
              if (mRes.ok) marksData = await mRes.json();
            } catch(e) {}
          }

          // 5. Try fetching homeworks
          var hwData = null;
          if (studentId) {
            try {
              var hRes = await fetch(
                'https://school.mos.ru/api/family/web/v1/homeworks?student_id='+studentId,
                { headers: {'x-mes-subsystem':'familyweb'}, credentials:'include' }
              );
              if (hRes.ok) hwData = await hRes.json();
            } catch(e) {}
          }

          // 6. DOM Scraper for student name and rendered lessons
          var studentName = '';
          var nameEl = document.querySelector('.user-name, .header__profile-name, [data-qa="user-name"], .profile__name, .user-info__name');
          if (nameEl) studentName = nameEl.innerText.trim();

          var domLessons = [];
          try {
            var cards = document.querySelectorAll('.schedule__lesson, .lesson, [data-qa="lesson-card"], .diary-lesson-item, .lesson-card, .schedule-item');
            cards.forEach(function(c) {
              var s = (c.querySelector('.subject, .lesson__subject, .title, [data-qa="lesson-name"]') || {}).innerText || '';
              var t = (c.querySelector('.time, .lesson__time, [data-qa="lesson-time"]') || {}).innerText || '';
              var r = (c.querySelector('.room, .lesson__room, [data-qa="lesson-room"]') || {}).innerText || '';
              var tc = (c.querySelector('.teacher, .lesson__teacher, [data-qa="lesson-teacher"]') || {}).innerText || '';
              var tp = (c.querySelector('.topic, .lesson__topic, [data-qa="lesson-topic"]') || {}).innerText || '';
              if (s) {
                domLessons.push({ subject: s.trim(), startTime: t.trim(), room: r.trim(), teacher: tc.trim(), topic: tp.trim() });
              }
            });
          } catch(e) {}

          return JSON.stringify({
            token: token,
            cookie: cookies,
            studentId: studentId,
            studentName: studentName,
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
      final jsCookie = (data['cookie'] ?? '').toString();
      final studentId = (data['studentId'] ?? '').toString();
      final studentName = (data['studentName'] ?? '').toString();
      final profile = data['profile'];
      final schedules = data['schedules'];
      final domLessons = data['domLessons'];

      final combinedCookies = [httpCookies, jsCookie]
          .where((s) => s.isNotEmpty)
          .join('; ');

      final bool hasUsefulData = (profile != null) ||
          studentName.isNotEmpty ||
          (schedules != null) ||
          (domLessons is List && domLessons.isNotEmpty) ||
          (studentId.isNotEmpty && combinedCookies.isNotEmpty);

      if (hasUsefulData) {
        final authToken = token.isNotEmpty
            ? token
            : (combinedCookies.isNotEmpty ? 'mos_cookie_session' : '');

        if (authToken.isNotEmpty) {
          await _authService.saveAuthSession(
            authToken: authToken,
            cookies: combinedCookies,
            studentId: studentId,
          );
        }

        await _apiService.saveImportedBundle(data);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _manualSyncAndClose() async {
    setState(() {
      _isExtracting = true;
      _statusText = 'Загрузка дневника в приложение...';
    });

    final success = await _attemptDataExtraction();
    if (success) {
      if (mounted) {
        widget.onAuthResult(true);
      }
    } else {
      final httpCookies = await _extractAllHttpCookies();
      if (httpCookies.isNotEmpty) {
        await _authService.saveAuthSession(
          authToken: 'mos_cookie_session',
          cookies: httpCookies,
        );
        if (mounted) {
          widget.onAuthResult(true);
        }
      } else {
        setState(() {
          _isExtracting = false;
          _statusText = 'Не удалось получить данные. Убедитесь, что дневник открыт.';
        });
      }
    }
  }

  void _reload() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    _webViewController.reload();
  }

  void _restartLogin() {
    _pollingTimer?.cancel();
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _currentUrl = '';
      _hasVisitedLoginPage = false;
      _syncAttemptStarted = false;
      _statusText = '';
    });
    _webViewController.loadRequest(Uri.parse(_startUrl));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final isOnLoginPage = _currentUrl.contains('login.mos.ru') ||
        _currentUrl.contains('/sps/');

    final isDiaryVisible = (_currentUrl.contains('dnevnik.mos.ru') ||
            _currentUrl.contains('school.mos.ru')) &&
        !isOnLoginPage &&
        _currentUrl.isNotEmpty;

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            isDark ? const Color(0xEE121214) : const Color(0xEEFFFFFF),
        middle: Text(
          isOnLoginPage ? 'Вход через Mos.ID' : 'Электронный дневник',
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
            if (_canGoBack && !_isExtracting) ...[
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _webViewController.goBack(),
                child: const Icon(CupertinoIcons.chevron_left, size: 20),
              ),
            ],
          ],
        ),
        trailing: _isExtracting
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _reload,
                child: Icon(
                  CupertinoIcons.refresh,
                  size: 20,
                  color: textSecondary,
                ),
              ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Loading Progress Bar
            if (_isLoading && !_isExtracting)
              Container(
                height: 2.5,
                color: isDark
                    ? const Color(0xFF27272A)
                    : const Color(0xFFE4E4E7),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_loadingProgress / 100.0).clamp(0.05, 1.0),
                  child: Container(color: AppTheme.mosRedAccent),
                ),
              ),

            // Status Banner if syncing or on login
            if (_statusText.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.grade5Color.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const CupertinoActivityIndicator(radius: 8),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.grade5Color,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (isOnLoginPage && !_isLoading && _errorMessage == null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark
                    ? const Color(0xFF1C1C1E)
                    : const Color(0xFFF2F2F7),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.info_circle_fill,
                      size: 15,
                      color: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Войдите в Mos.ID — дневник откроется в приложении',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

            // WebView
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _webViewController),

                  // Initial Loading Overlay
                  if (_isLoading && _currentUrl.isEmpty)
                    Container(
                      color: CupertinoColors.white,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CupertinoActivityIndicator(radius: 16),
                            SizedBox(height: 14),
                            Text(
                              'Подключение к Mos.ID...',
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

                  // Full Extracting Overlay (only when manual sync or transitioning)
                  if (_isExtracting)
                    Container(
                      color:
                          CupertinoColors.black.withValues(alpha: 0.88),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CupertinoActivityIndicator(
                              radius: 20,
                              color: CupertinoColors.white,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Синхронизация с МЭШ...',
                              style: TextStyle(
                                fontSize: 20,
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Загружаем расписание и оценки в приложение',
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Prominent Action Button: appears when diary page is open
                  if (isDiaryVisible && !_isExtracting)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: CupertinoButton(
                        color: CupertinoColors.activeGreen,
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        onPressed: _manualSyncAndClose,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              CupertinoIcons.arrow_right_circle_fill,
                              color: CupertinoColors.white,
                              size: 22,
                            ),
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

                  // Error Overlay
                  if (_errorMessage != null && !_isExtracting)
                    Container(
                      color: CupertinoColors.white,
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.wifi_slash,
                              size: 52,
                              color: CupertinoColors.systemOrange,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Не удалось загрузить страницу',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Убедитесь, что интернет включён и сайт mos.ru доступен.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  color: CupertinoColors.systemGrey5,
                                  onPressed: _restartLogin,
                                  child: const Text(
                                    'Начать заново',
                                    style: TextStyle(
                                        color: CupertinoColors.black),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                CupertinoButton.filled(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  onPressed: _reload,
                                  child: const Text('Повторить'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
