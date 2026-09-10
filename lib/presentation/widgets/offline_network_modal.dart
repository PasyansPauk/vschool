import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';

class OfflineNetworkModal extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onDismiss;
  final VoidCallback onRetry;
  final bool isDark;

  const OfflineNetworkModal({
    super.key,
    this.errorMessage,
    required this.onDismiss,
    required this.onRetry,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    String? errorMessage,
    required VoidCallback onDismiss,
    required VoidCallback onRetry,
    required bool isDark,
  }) {
    return showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OfflineNetworkModal(
        errorMessage: errorMessage,
        onDismiss: () {
          Navigator.of(ctx).pop();
          onDismiss();
        },
        onRetry: () {
          Navigator.of(ctx).pop();
          onRetry();
        },
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Icon with subtle badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.wifi_slash,
              size: 28,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            'Не удалось подключиться',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            errorMessage ??
                'Проверьте подключение к интернету или выключите VPN. Сервисы МЭШ и Mos ID могут блокировать зарубежный трафик.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          // Offline cached info badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.archivebox,
                  size: 14,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Доступно старое расписание и оценки из кэша',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Action button: Dismiss to see cache
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              borderRadius: BorderRadius.circular(14),
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: onDismiss,
              child: Text(
                'Посмотреть кэш',
                style: TextStyle(
                  color: isDark ? CupertinoColors.black : CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Secondary button: Retry
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onRetry,
            child: Text(
              'Повторить попытку',
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
