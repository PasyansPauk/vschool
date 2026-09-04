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

  /// Флаг: пользователь уже побывал на странице login.mos.ru (СУДИР).
  /// Нужен чтобы не сработал авто-close при первом открытии dnevnik.mos.ru
  /// ДО того, как произойдёт редирект на login.mos.ru.
  bool _hasVisitedLoginPage = false;

  // Стартовая страница: dnevnik.mos.ru.
  // Он сам инициирует правильный OAuth-поток и перенаправляет на login.mos.ru
  // с валидными OAuth-параметрами (client_id, scope, redirect_uri и т.д.)
  // Нельзя ходить на login.mos.ru напрямую — СУДИР выдаёт ошибку
  // "Вход в сервис не осуществлен" без контекста сервис-провайдера.
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
            // Запоминаем что пользователь был на странице входа СУДИР
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
            // Запоминаем что пользователь был на странице входа СУДИР
            if (url.contains('login.mos.ru') || url.contains('/sps/')) {
              _hasVisitedLoginPage = true;
            }
            _injectFixes();

            // Проверяем: вернулись ли мы на dnevnik/school ПОСЛЕ login.mos.ru?
            // Если да — авторизация прошла успешно → извлекаем данные и закрываем
            _checkIfAuthCompleted(url);
          },
          onWebResourceError: (WebResourceError error) {
            if (error.errorCode == -999) return; // отмена навигации при редиректе
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

  /// Проверяет, завершилась ли OAuth-авторизация.
  /// Логика: если пользователь УЖЕ побывал на login.mos.ru (ввёл логин/пароль),
  /// и сейчас URL снова на dnevnik.mos.ru или school.mos.ru — значит
  /// СУДИР сделал успешный редирект обратно → авторизация прошла.
  void _checkIfAuthCompleted(String url) {
    if (_isExtracting) return;
    if (!_hasVisitedLoginPage) return; // ещё не были на login.mos.ru

    final isBackOnService = url.contains('dnevnik.mos.ru') ||
        url.contains('school.mos.ru');
    final isStillOnLogin =
        url.contains('login.mos.ru') || url.contains('/sps/');

    if (isBackOnService && !isStillOnLogin) {
      // Пользователь вошёл через Mos.ID и СУДИР перенаправил обратно
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
      // Даём странице 2 секунды загрузить JS и записать токены в localStorage/cookies
      await Future.delayed(const Duration(seconds: 2));

      const extractionScript = r'''
        (async function() {
          var cookies = '';
          var token = '';
          var studentId = '';

          try { cookies = document.cookie || ''; } catch(e) {}

          // localStorage: ищем auth-token, student_id
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

          // Cookies: ищем auth_token, profile_id
          if (!token || !studentId) {
            try {
              var parts = cookies.split(';');
              for (var p of parts) {
                var kv = p.trim().split('=');
                var k = kv[0].trim();
                var v = (kv[1] || '').trim();
                if (!token && (k === 'auth-token' || k === 'auth_token' || k === 'token') && v.length > 10) {
                  token = v;
                }
                if (!studentId && (k === 'profile_id' || k === 'student_id') && v) {
                  studentId = v;
                }
              }
            } catch(e) {}
          }

          // API: получаем профиль (куки сессии уже в браузере)
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

          // API: расписание на неделю
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

          // API: оценки
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

          // API: домашние задания
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

      final authToken = token.isNotEmpty
          ? token
          : 'mos_session_${DateTime.now().millisecondsSinceEpoch}';

      await _authService.saveAuthSession(
        authToken: authToken,
        cookies: cookie,
        studentId: studentId,
      );

      await _apiService.saveImportedBundle(data);
    } catch (e) {
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
      _hasVisitedLoginPage = false;
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

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            isDark ? const Color(0xEE121214) : const Color(0xEEFFFFFF),
        middle: Text(
          isOnLoginPage ? 'Вход через Mos.ID' : 'Авторизация',
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
            // Прогресс-бар
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

            // Подсказка на странице входа
            if (isOnLoginPage &&
                !_isLoading &&
                !_isExtracting &&
                _errorMessage == null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isDark
                    ? const Color(0xFF1C1C1E)
                    : const Color(0xFFF2F2F7),
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

                  // Начальная загрузка
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
                              'Подключаемся к Mos.ID...',
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

                  // Ошибка загрузки
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
                              'Убедитесь, что устройство подключено '
                              'к интернету и сервисы mos.ru доступны.',
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
