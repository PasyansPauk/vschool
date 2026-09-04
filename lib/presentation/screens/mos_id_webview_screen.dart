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
  final MosIdAuthService _authService = MosIdAuthService();

  int _loadingProgress = 0;
  bool _isLoading = true;
  String _currentUrl = '';

  // Primary URL for Mos.ID login
  static const String initialUrl =
      'https://login.mos.ru/sps/login/methods/password';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
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
              _checkAutoLogin(url);
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _currentUrl = url;
                _isLoading = false;
              });
              _checkAutoLogin(url);
            }
          },
          onNavigationRequest: (request) {
            _checkAutoLogin(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }

  Future<void> _checkAutoLogin(String url) async {
    final lower = url.toLowerCase();
    // Detect successful authentication redirect or session completion
    if (lower.contains('school.mos.ru/v3') ||
        lower.contains('dnevnik.mos.ru/diary') ||
        lower.contains('my.mos.ru') ||
        lower.contains('oauth/callback') ||
        lower.contains('sudir/callback') ||
        (lower.contains('login.mos.ru') && lower.contains('ticket='))) {
      await _handleLoginCompleted();
    }
  }

  Future<void> _handleLoginCompleted() async {
    await _authService.loginWithMosIdSuccess();
    if (mounted) {
      widget.onAuthResult(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            isDark ? const Color(0xEE121214) : const Color(0xEEFFFFFF),
        middle: Text(
          'Вход через Mos.ID',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => widget.onAuthResult(false),
          child: const Text('Отмена'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _handleLoginCompleted,
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

            // Quick domain switcher bar for convenience
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentUrl.isNotEmpty ? _currentUrl : initialUrl,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.systemGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _webViewController.reload(),
                    child: const Icon(CupertinoIcons.refresh, size: 16),
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
