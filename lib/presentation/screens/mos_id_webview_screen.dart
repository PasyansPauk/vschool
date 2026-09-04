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

  // Стартовая страница: страница входа СУДИР (Mos.ID)
  // backUrl — куда СУДИР перенаправит после успешного входа
  static const String _loginUrl =
      'https://login.mos.ru/sps/login/methods/password'
      '?backUrl=https%3A%2F%2Fdnevnik.mos.ru%2F';

  // Домены, означающие успешную авторизацию и редирект от СУДИР
  static const List<String> _successDomains = [
    'dnevnik.mos.ru',
    'school.mos.ru',
  ];

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
            // Детектируем успешный редирект СРАЗУ при старте навигации
            _checkIfSuccessRedirect(url);
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
            // Детектируем повторно после полной загрузки страницы
            _checkIfSuccessRedirect(url);
          },
          onWebResourceError: (WebResourceError error) {
            // -999 — отмена навигации (при редиректе), не ошибка
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
      ..loadRequest(Uri.parse(_loginUrl));
  }

  /// Проверяет, является ли URL признаком успешного входа через Mos.ID
  void _checkIfSuccessRedirect(String url) {
    if (_isExtracting) return;
    final isSuccess = _successDomains.any((domain) => url.contains(domain));
    final isLoginPage =
        url.contains('login.mos.ru') || url.contains('/sps/');

    if (isSuccess && !isLoginPage) {
      // Пользователь успешно авторизовался и СУДИР перенаправил на дневник
      _extractAndTransition();
    }
  }

  Future<void> _injectFixes() async {
    try {
      await _webViewController.runJavaScript(_jsPopupFix);
    } catch (_) {}
  }

  Future<void> _extractAndTransition() async {
    if (_isExtracting) return;
    if (mounted) {
      setState(() {
        _isExtracting = true;
        _errorMessage = null;
      });
    }

    try {
      // Извлекаем токен и куки из браузерной сессии
      const extractionScript = r'''
        (async function() {
          var cookies = '';
          var token = '';
          var studentId = '';

          // 1. Читаем куки документа
          try { cookies = document.cookie || ''; } catch(e) {}

          // 2. Ищем токен в localStorage (dnevnik.mos.ru хранит там auth-token)
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

          // 3. Ищем токен в куках
          if (!token) {
            var parts = cookies.split(';');
            for (var p of parts) {
              var kv = p.trim().split('=');
              var k = kv[0].trim();
              var v = (kv[1] || '').trim();
              if ((k === 'auth-token' || k === 'auth_token' || k === 'token') && v.length > 10) {
                token = v;
              }
              if ((k === 'profile_id' || k === 'student_id') && v) {
                studentId = v;
              }
            }
          }

          // 4. Получаем профиль через API (куки уже в браузере — запрос пройдет)
          var profileData = null;
          try {
            var pRes = await fetch('https://school.mos.ru/api/family/web/v1/profile', {
              headers: { 'x-mes-subsystem': 'familyweb' },
              credentials: 'include'
            });
            if (pRes.ok) {
              profileData = await pRes.json();
              if (!studentId && profileData) {
                try {
                  var children = profileData['children'] || profileData['payload'] || [];
                  if (Array.isArray(children) && children.length > 0) {
                    studentId = String(children[0]['id'] || children[0]['student_id'] || '');
                  }
                } catch(e) {}
              }
            }
          } catch(e) {}

          // 5. Расписание
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

          // 6. Оценки
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

          // 7. Домашние задания
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

          return JSON.stringify({
            token: token,
            cookie: cookies,
            studentId: studentId,
            profile: profileData,
            schedules: schedData,
            marks: marksData,
            homeworks: hwData
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

      // Токен из localStorage или синтетический (куки уже сохранены — достаточно для API)
      final authToken = token.isNotEmpty
          ? token
          : 'mos_session_${DateTime.now().millisecondsSinceEpoch}';

      await _authService.saveAuthSession(
        authToken: authToken,
        cookies: cookie,
        studentId: studentId,
      );

      // Сохраняем все данные, которые удалось получить через API
      await _apiService.saveImportedBundle(data);
    } catch (e) {
      // Даже если извлечение не удалось — сессия была (браузер перешёл на дневник)
      await _authService.saveAuthSession(
        authToken: 'mos_session_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    if (mounted) {
      widget.onAuthResult(true);
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
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _currentUrl = '';
    });
    _webViewController.loadRequest(Uri.parse(_loginUrl));
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
        _currentUrl.contains('/sps/') ||
        _currentUrl.isEmpty;

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            isDark ? const Color(0xEE121214) : const Color(0xEEFFFFFF),
        middle: Text(
          isOnLoginPage ? 'Вход через Mos.ID' : 'Авторизация МЭШ',
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
            // Прогресс-бар загрузки
            if (_isLoading && !_isExtracting)
              Container(
                height: 2.5,
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_loadingProgress / 100.0).clamp(0.05, 1.0),
                  child: Container(color: AppTheme.mosRedAccent),
                ),
              ),

            // Подсказка пользователю на странице входа
            if (isOnLoginPage && !_isLoading && !_isExtracting && _errorMessage == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.info_circle_fill,
                      size: 16,
                      color: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Войдите в Mos.ID — приложение откроется автоматически',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Основная WebView область
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _webViewController),

                  // Индикатор начальной загрузки
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
                              'Открываем страницу входа Mos.ID...',
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

                  // Оверлей синхронизации (после успешного входа)
                  if (_isExtracting)
                    Container(
                      color: CupertinoColors.black.withValues(alpha: 0.88),
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
                              'Вход выполнен!',
                              style: TextStyle(
                                fontSize: 20,
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Загружаем данные из МЭШ...',
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Экран ошибки загрузки
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
                              'Убедитесь, что устройство подключено к интернету и сайт login.mos.ru доступен.',
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
                                      color: CupertinoColors.black,
                                    ),
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
