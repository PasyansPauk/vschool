import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class DevSettingsScreen extends StatefulWidget {
  final bool isDark;

  const DevSettingsScreen({super.key, required this.isDark});

  @override
  State<DevSettingsScreen> createState() => _DevSettingsScreenState();
}

class _DevSettingsScreenState extends State<DevSettingsScreen> {
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _isExporting = false;
  bool _isCopied = false;
  String? _previewLogs;

  Future<String> _buildLogString() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList()..sort();
    final sb = StringBuffer();

    sb.writeln('=== VSchool Dev Logs ===');
    sb.writeln('Date: ${DateTime.now().toIso8601String()}');
    sb.writeln('Total Keys: ${keys.length}');
    sb.writeln('=======================\n');

    for (final key in keys) {
      sb.writeln('--- $key ---');
      final value = prefs.get(key);
      if (value is String) {
        try {
          final parsed = jsonDecode(value);
          sb.writeln(const JsonEncoder.withIndent('  ').convert(parsed));
        } catch (_) {
          sb.writeln(value);
        }
      } else {
        sb.writeln(value.toString());
      }
      sb.writeln('\n');
    }

    return sb.toString();
  }

  Future<void> _exportLogs(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final logContent = await _buildLogString();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/vschool_logs.txt');
      await file.writeAsString(logContent);

      if (!context.mounted) return;

      final RenderBox? buttonBox =
          _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final Rect origin;
      if (buttonBox != null && buttonBox.hasSize && buttonBox.size.width > 0 && buttonBox.size.height > 0) {
        origin = buttonBox.localToGlobal(Offset.zero) & buttonBox.size;
      } else {
        final media = MediaQuery.of(context);
        origin = Rect.fromLTWH(0, media.padding.top, media.size.width, 100);
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Dev Logs',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Ошибка'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              )
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _copyLogsToClipboard(BuildContext context) async {
    try {
      final logContent = await _buildLogString();
      await Clipboard.setData(ClipboardData(text: logContent));
      HapticFeedback.mediumImpact();
      setState(() {
        _isCopied = true;
        _previewLogs = logContent;
      });

      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Скопировано!'),
            content: const Text(
                'Все логи и кэш скопированы в буфер обмена. Теперь вы можете просто вставить их в чат.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Отлично'),
                onPressed: () => Navigator.of(ctx).pop(),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Ошибка'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              )
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textPrimary =
        widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final tileBg = widget.isDark
        ? AppTheme.darkSurfaceSecondary
        : AppTheme.lightSurfaceSecondary;

    return CupertinoPageScaffold(
      backgroundColor:
          widget.isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: bg.withValues(alpha: 0.9),
        middle: Text('Для разработчика', style: TextStyle(color: textPrimary)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 16),
            CupertinoButton(
              key: _shareButtonKey,
              color: CupertinoColors.activeBlue,
              onPressed: _isExporting ? null : () => _exportLogs(context),
              child: _isExporting
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('Поделиться файлом логов (Share)'),
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              color: CupertinoColors.systemGreen,
              onPressed: () => _copyLogsToClipboard(context),
              child: Text(
                _isCopied ? 'Скопировано в буфер ✓' : 'Скопировать все логи в буфер',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'В этом меню собирается весь кэш (включая сырые ответы API МЭШ, токен и расписание). Нажмите "Скопировать все логи в буфер", чтобы сразу вставить их в переписку, либо "Поделиться файлом логов".',
                style: TextStyle(color: textPrimary, fontSize: 14),
              ),
            ),
            if (_previewLogs != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                height: 250,
                decoration: BoxDecoration(
                  color: widget.isDark ? CupertinoColors.black : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: textPrimary.withValues(alpha: 0.2),
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _previewLogs!,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      color: textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

