import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../view_models/diary_view_model.dart';
import '../../data/services/mos_id_auth_service.dart';
import 'mos_id_webview_screen.dart';
import 'dev_settings_screen.dart';
import 'package:flutter/services.dart';

class ProfileModal extends StatefulWidget {
  final DiaryViewModel viewModel;
  final VoidCallback onLogout;
  final bool isDark;
  final ScrollController? scrollController;

  const ProfileModal({
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.88, 0.95],
        builder: (ctx, scrollController) => ProfileModal(
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
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal> {
  bool _isRefreshing = false;
  String? _refreshFeedback;

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
    final result = await MosIdWebViewScreen.show(context, isDark: widget.isDark);
    if (result == true) {
      widget.viewModel.loadData(forceRefresh: true);
    }
  }

  int _devTapCount = 0;

  void _onVersionTapped() {
    _devTapCount++;
    if (_devTapCount >= 5) {
      _devTapCount = 0;
      HapticFeedback.heavyImpact();
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => DevSettingsScreen(isDark: widget.isDark),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ...

    final profile = widget.viewModel.profile;
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final String fullName = (profile != null && profile.fullName.isNotEmpty)
        ? profile.fullName
        : 'Ученик';
    final String className = (profile != null && profile.className.isNotEmpty)
        ? profile.className
        : 'Класс не указан';
    final String schoolName = (profile != null && profile.schoolName.isNotEmpty)
        ? profile.schoolName
        : 'Школа не указана';
    final String balanceStr = profile != null
        ? '${profile.canteenBalance.toStringAsFixed(0)} ₽'
        : '—';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xC5121214) : const Color(0xE0F2F2F7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0x30FFFFFF) : const Color(0x20000000),
              width: 0.5,
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Profile Card
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color:
                                isDark ? CupertinoColors.white : CupertinoColors.black,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: profile != null && profile.avatarUrl.isNotEmpty
                                ? Image.network(
                                    profile.avatarUrl,
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => _buildFallbackAvatar(fullName, isDark),
                                  )
                                : _buildFallbackAvatar(fullName, isDark),
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
                              ),
                              const SizedBox(height: 2),
                              Text(
                                className,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                schoolName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mos.ID & Moskvyonok Info
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          shape: const LiquidRoundedSuperellipse(borderRadius: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppTheme.mosRedAccent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'М',
                                        style: TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Mos.ID',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                profile != null ? 'Подключён' : 'Не привязан',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: profile != null
                                      ? AppTheme.grade5Color
                                      : AppTheme.grade2Color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          shape: const LiquidRoundedSuperellipse(borderRadius: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.creditcard,
                                    size: 14,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Москвёнок (буфет)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                balanceStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Feedback banner if refresh was clicked
                  if (_refreshFeedback != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFE4E4E7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _refreshFeedback!,
                        style: TextStyle(
                          fontSize: 12,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // Settings Grouped Section
                  GlassGroupedSection(
                    header: Text(
                      'СИНХРОНИЗАЦИЯ И НАСТРОЙКИ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    margin: EdgeInsets.zero,
                    children: [
                      GlassListTile(
                        leading: _isRefreshing
                            ? const CupertinoActivityIndicator(radius: 10)
                            : Icon(
                                CupertinoIcons.arrow_2_circlepath,
                                size: 20,
                                color: textPrimary,
                              ),
                        title: Text(
                          _isRefreshing
                              ? 'Синхронизация с МЭШ...'
                              : 'Обновить данные из МЭШ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Загрузить свежие оценки и расписание',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                        trailing: GlassListTile.chevron,
                        onTap: _isRefreshing ? null : _handleRefresh,
                      ),
                      GlassListTile(
                        leading: const Icon(
                          CupertinoIcons.person_crop_circle_badge_checkmark,
                          size: 20,
                          color: CupertinoColors.activeBlue,
                        ),
                        title: Text(
                          'Повторная авторизация Mos.ID',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Обновить сессию доступа к дневнику',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                        trailing: GlassListTile.chevron,
                        onTap: _handleReAuth,
                      ),
                      GlassListTile(
                        leading: Icon(
                          isDark
                              ? CupertinoIcons.moon_fill
                              : CupertinoIcons.sun_max_fill,
                          size: 20,
                          color: textPrimary,
                        ),
                        title: Text(
                          'Темная монохромная тема',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        trailing: CupertinoSwitch(
                          value: isDark,
                          activeTrackColor: CupertinoColors.white,
                          thumbColor: CupertinoColors.black,
                          onChanged: (_) => widget.viewModel.toggleTheme(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppTheme.grade2Color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onPressed: () async {
                        await MosIdAuthService().logout();
                        widget.onLogout();
                      },
                      child: const Text(
                        'Выйти из профиля Mos.ID',
                        style: TextStyle(
                          color: AppTheme.grade2Color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final text = snapshot.hasData 
                            ? 'v${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})' 
                            : 'Загрузка...';
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _onVersionTapped,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String fullName, bool isDark) {
    return Center(
      child: Text(
        fullName.isNotEmpty ? fullName.substring(0, 1) : 'У',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isDark ? CupertinoColors.black : CupertinoColors.white,
        ),
      ),
    );
  }
}
