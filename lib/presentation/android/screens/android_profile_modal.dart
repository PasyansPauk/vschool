import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/mos_id_auth_service.dart';
import '../../screens/dev_settings_screen.dart';
import '../../screens/mos_id_webview_screen.dart';
import '../../view_models/diary_view_model.dart';

class AndroidProfileModal extends StatefulWidget {
  final DiaryViewModel viewModel;
  final VoidCallback onLogout;
  final bool isDark;
  final ScrollController? scrollController;

  const AndroidProfileModal({
    super.key,
    required this.viewModel,
    required this.onLogout,
    required this.isDark,
    this.scrollController,
  });

  static void show(
    BuildContext context, {
    required DiaryViewModel viewModel,
    required VoidCallback onLogout,
    required bool isDark,
  }) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => AndroidProfileModal(
          viewModel: viewModel,
          scrollController: scrollController,
          onLogout: () {
            Navigator.of(ctx).pop();
            onLogout();
          },
          isDark: isDark,
        ),
      ),
    );
  }

  @override
  State<AndroidProfileModal> createState() => _AndroidProfileModalState();
}

class _AndroidProfileModalState extends State<AndroidProfileModal> {
  bool _isRefreshing = false;
  String? _refreshFeedback;
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

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _refreshFeedback = null;
    });

    try {
      await widget.viewModel.loadData(forceRefresh: true);
      if (mounted) {
        final hasData = widget.viewModel.schedules.isNotEmpty ||
            widget.viewModel.grades.isNotEmpty ||
            (widget.viewModel.profile?.fullName.isNotEmpty ?? false);

        setState(() {
          _isRefreshing = false;
          _refreshFeedback = hasData
              ? 'Данные успешно обновлены'
              : (widget.viewModel.errorMessage ??
                  'Данные не получены. Возможно, требуется вход в Mos.ID');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _refreshFeedback = 'Ошибка обновления данных';
        });
      }
    }
  }

  Future<void> _handleReAuth() async {
    Navigator.of(context).pop();
    final result =
        await MosIdWebViewScreen.show(context, isDark: widget.isDark);
    if (result == true) {
      await widget.viewModel.loadData(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final profile = widget.viewModel.profile;
    final fullName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : 'Ученик МЭШ';
    final className = profile?.className.isNotEmpty == true
        ? '${profile!.className} класс'
        : '11 класс';

    return SafeArea(
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Профиль и настройки',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                color: textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Profile Info Card
          Card(
            color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FB),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF242426) : const Color(0xFFE4E4E7),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF0A84FF),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'У',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          className,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Refresh & Re-auth
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isRefreshing ? null : _handleRefresh,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text('Обновить'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleReAuth,
                  icon: const Icon(Icons.vpn_key_outlined, size: 18),
                  label: const Text('Mos.ID вход'),
                ),
              ),
            ],
          ),

          if (_refreshFeedback != null) ...[
            const SizedBox(height: 10),
            Text(
              _refreshFeedback!,
              style: TextStyle(
                fontSize: 12,
                color: _refreshFeedback!.contains('успешно')
                    ? Colors.green
                    : Colors.amber,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),

          // Settings Section
          Card(
            color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FB),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF242426) : const Color(0xFFE4E4E7),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Темная тема',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: textSecondary,
                  ),
                  value: widget.viewModel.isDarkTheme,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    widget.viewModel.toggleTheme();
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF242426) : const Color(0xFFE4E4E7),
                ),
                ListTile(
                  title: Text(
                    'Режим разработчика',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  leading: Icon(Icons.code, color: textSecondary),
                  trailing: Icon(Icons.chevron_right, color: textSecondary),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DevSettingsScreen(
                          isDark: isDark,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Logout Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dCtx) => AlertDialog(
                  title: const Text('Выход из аккаунта'),
                  content: const Text(
                      'Вы уверены, что хотите выйти из профиля МЭШ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dCtx).pop(false),
                      child: const Text('Отмена'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      onPressed: () => Navigator.of(dCtx).pop(true),
                      child: const Text('Выйти'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await MosIdAuthService().logout();
                widget.onLogout();
              }
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Выйти из аккаунта'),
          ),

          const SizedBox(height: 20),

          // Version Info
          if (_version.isNotEmpty)
            Center(
              child: Text(
                _version,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
