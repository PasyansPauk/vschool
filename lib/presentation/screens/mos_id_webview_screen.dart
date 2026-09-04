import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/mos_id_auth_service.dart';

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

  int _loadingProgress = 0;
  bool _isLoading = true;
  bool _hasTransferred = false;
  String _currentUrl = '';
  String? _errorMessage;
  bool _canGoBack = false;

  bool _hasVisitedLoginPage = false;
  Timer? _authCheckTimer;

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

  static const String _jsNetworkInterceptor = r'''
    (function() {
      if (window._interceptorInjected) return;
      window._interceptorInjected = true;

      function sendToken(token, pId) {
        if (token && token.startsWith('Bearer ')) {
          token = token.substring(7);
        }
        if (token && window.AuthChannel) {
           window.AuthChannel.postMessage(JSON.stringify({authToken: token, profileId: pId}));
        }
      }

      var originalFetch = window.fetch;
      window.fetch = async function() {
        var args = arguments;
        var url = args[0];
        var options = args[1];
        
        if (options && options.headers) {
          var token = '';
          var pid = '';
          
          if (options.headers instanceof Headers) {
            token = options.headers.get('auth-token') || options.headers.get('Auth-Token') || options.headers.get('Authorization');
            pid = options.headers.get('profile-id');
          } else {
            // It's a plain object
            var lowerHeaders = {};
            for (var k in options.headers) {
              lowerHeaders[k.toLowerCase()] = options.headers[k];
            }
            token = lowerHeaders['auth-token'] || lowerHeaders['authorization'];
            pid = lowerHeaders['profile-id'];
          }

          if (!pid && typeof url === 'string') {
            var match = url.match(/student_id=(\d+)/);
            if (match) pid = match[1];
          }
          sendToken(token, pid);
        }
        return originalFetch.apply(this, arguments);
      };

      var originalXhrOpen = XMLHttpRequest.prototype.open;
      var originalXhrSend = XMLHttpRequest.prototype.send;
      var originalXhrSetRequestHeader = XMLHttpRequest.prototype.setRequestHeader;
      
      XMLHttpRequest.prototype.open = function() {
        this._url = arguments[1];
        return originalXhrOpen.apply(this, arguments);
      };
      
      XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
        if (!this._headers) this._headers = {};
        this._headers[header.toLowerCase()] = value;
        return originalXhrSetRequestHeader.apply(this, arguments);
      };

      XMLHttpRequest.prototype.send = function() {
        if (this._headers) {
          var token = this._headers['auth-token'] || this._headers['authorization'];
          var pid = this._headers['profile-id'];
          if (!pid && typeof this._url === 'string') {
            var match = this._url.match(/student_id=(\d+)/);
            if (match) pid = match[1];
          }
          sendToken(token, pid);
        }
        return originalXhrSend.apply(this, arguments);
      };
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _authCheckTimer?.cancel();
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
            _evaluateAuthStatus(url);
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
            _evaluateAuthStatus(url);
          },
          onWebResourceError: (WebResourceError error) {
            if (error.errorCode == -999) return;
            if (_hasTransferred) return;
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
      ..addJavaScriptChannel(
        'AuthChannel',
        onMessageReceived: (JavaScriptMessage message) async {
          if (_hasTransferred) return;
          try {
            final data = jsonDecode(message.message);
            final authToken = data['authToken'] as String?;
            final profileId = data['profileId'] as String?;

            if (authToken != null && authToken.isNotEmpty) {
              String cookieHeader = '';
              try {
                final cookies = await _cookieManager.getCookies(domain: Uri.parse('https://school.mos.ru'));
                cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');
              } catch (_) {}

              await _authService.saveAuthSession(
                authToken: authToken,
                studentId: profileId ?? '',
                cookies: cookieHeader,
              );
              _completeLogin();
            }
          } catch (_) {}
        },
      )
      ..loadRequest(Uri.parse(_startUrl));
  }

  Future<void> _injectFixes() async {
    try {
      await _webViewController.runJavaScript(_jsPopupFix);
      await _webViewController.runJavaScript(_jsNetworkInterceptor);
    } catch (_) {}
  }

  void _evaluateAuthStatus(String url) {
    if (_hasTransferred) return;

    final isBackOnDiary = url.contains('dnevnik.mos.ru') ||
        url.contains('school.mos.ru');
    final isStillOnLogin =
        url.contains('login.mos.ru') || url.contains('/sps/');

    if (isBackOnDiary && !isStillOnLogin && _hasVisitedLoginPage) {
      // Start rapid, lightweight check of cookies and localStorage
      _startRapidAuthCheck();
    }
  }

  void _startRapidAuthCheck() {
    _authCheckTimer?.cancel();
    int count = 0;
    _authCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      count++;
      if (_hasTransferred) {
        timer.cancel();
        return;
      }

      final success = await _checkAndSaveSession();
      if (success) {
        timer.cancel();
        _completeLogin();
      } else if (count >= 20) {
        // Stop polling after 10 seconds, user can still use manual button
        timer.cancel();
      }
    });
  }

  Future<bool> _checkAndSaveSession() async {
    try {
      final domains = [
        Uri.parse('https://school.mos.ru'),
        Uri.parse('https://dnevnik.mos.ru'),
        Uri.parse('https://mos.ru'),
      ];

      final Map<String, String> cookieMap = {};
      String authToken = '';
      String studentId = '';

      for (final domain in domains) {
        try {
          final cookies = await _cookieManager.getCookies(domain: domain);
          for (final c in cookies) {
            if (c.name.isNotEmpty && c.value.isNotEmpty) {
              cookieMap[c.name] = c.value;

              if (c.name == 'auth_token' || c.name == 'token') {
                if (c.value.length > 10) authToken = c.value;
              }
              if (c.name == 'profile_id' || c.name == 'student_id') {
                if (studentId.isEmpty) studentId = c.value;
              }
            }
          }
        } catch (_) {}
      }

      // Check localStorage for auth-token as backup
      if (authToken.isEmpty || studentId.isEmpty) {
        try {
          final res = await _webViewController.runJavaScriptReturningResult(
            r'''
            (function() {
              var t = '';
              var s = '';
              try {
                t = localStorage.getItem('auth-token') || localStorage.getItem('token') || '';
                s = localStorage.getItem('student_id') || localStorage.getItem('profile_id') || '';
              } catch(e) {}
              return JSON.stringify({t: t, s: s});
            })()
            ''',
          );
          String raw = res.toString();
          if (raw.startsWith('"') && raw.endsWith('"')) {
            raw = raw.substring(1, raw.length - 1).replaceAll(r'\"', '"');
          }
          final decoded = jsonDecode(raw);
          if (authToken.isEmpty && decoded['t'] != null && decoded['t'].toString().isNotEmpty) {
            authToken = decoded['t'].toString();
          }
          if (studentId.isEmpty && decoded['s'] != null && decoded['s'].toString().isNotEmpty) {
            studentId = decoded['s'].toString();
          }
        } catch (_) {}
      }

      final cookieHeader =
          cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');

      // Accept aupd_token or mos.ru session cookies as valid auth
      final bool hasAuth = authToken.isNotEmpty || 
                           cookieMap.containsKey('aupd_token') || 
                           cookieMap.containsKey('auth_token') ||
                           cookieHeader.contains('mos_id');

      if (hasAuth) {
        await _authService.saveAuthSession(
          authToken: authToken.isNotEmpty ? authToken : 'cookie_auth_only',
          cookies: cookieHeader,
          studentId: studentId,
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _completeLogin() {
    if (_hasTransferred) return;
    _hasTransferred = true;
    _authCheckTimer?.cancel();

    if (mounted) {
      widget.onAuthResult(true);
    }
  }

  Future<void> _manualSyncAndClose() async {
    final success = await _checkAndSaveSession();
    if (success) {
      _completeLogin();
    } else {
      // Fallback: save whatever cookies exist
      try {
        final cookies = await _cookieManager.getCookies(
            domain: Uri.parse('https://school.mos.ru'));
        final cookieHeader =
            cookies.map((c) => '${c.name}=${c.value}').join('; ');
        if (cookieHeader.isNotEmpty) {
          await _authService.saveAuthSession(
            authToken: 'mos_authenticated',
            cookies: cookieHeader,
          );
          _completeLogin();
          return;
        }
      } catch (_) {}

      // If really nothing found, prompt reload
      _reload();
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
    _authCheckTimer?.cancel();
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _currentUrl = '';
      _hasVisitedLoginPage = false;
      _hasTransferred = false;
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
            if (_canGoBack && !_hasTransferred) ...[
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _webViewController.goBack(),
                child: const Icon(CupertinoIcons.chevron_left, size: 20),
              ),
            ],
          ],
        ),
        trailing: _hasTransferred
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
            // Progress bar
            if (_isLoading && !_hasTransferred)
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

            // Subtle helper banner on login page
            if (isOnLoginPage && !_isLoading && _errorMessage == null)
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
                        'Войдите в Mos.ID — дневник откроется автоматически',
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

                  // Initial Loading
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

                  // Manual Sync button as backup if diary is already open
                  if (isDiaryVisible && !_hasTransferred)
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

                  // Error Display
                  if (_errorMessage != null && !_hasTransferred)
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
                              'Убедитесь, что интернет подключён и сайт mos.ru доступен.',
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
