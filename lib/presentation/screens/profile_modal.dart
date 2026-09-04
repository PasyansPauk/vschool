import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';
import '../view_models/diary_view_model.dart';
import '../../data/services/mos_id_auth_service.dart';
import 'mos_id_webview_screen.dart';

class ProfileModal extends StatefulWidget {
  final DiaryViewModel viewModel;
  final VoidCallback onLogout;
  final bool isDark;

  const ProfileModal({
    super.key,
    required this.viewModel,
    required this.onLogout,
    required this.isDark,
  });

  static void show(
    BuildContext context, {
    required DiaryViewModel viewModel,
    required VoidCallback onLogout,
    required bool isDark,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => ProfileModal(
        viewModel: viewModel,
        onLogout: () {
          Navigator.of(ctx).pop();
          onLogout();
        },
        isDark: isDark,
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

  @override
  Widget build(BuildContext context) {
    final profile = widget.viewModel.profile;
    final isDark = widget.isDark;
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final tileBg =
        isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary;

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

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3F3F46)
                        : const Color(0xFFD4D4D8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Student Profile Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: border),
                ),
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
                      child: Center(
                        child: Text(
                          fullName.isNotEmpty ? fullName.substring(0, 1) : 'У',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? CupertinoColors.black
                                : CupertinoColors.white,
                          ),
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
                            maxLines: 1,
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
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tileBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tileBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
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

              // Settings
              Text(
                'Синхронизация и настройки',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Real Sync with MES Button
              GestureDetector(
                onTap: _isRefreshing ? null : _handleRefresh,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      if (_isRefreshing)
                        const CupertinoActivityIndicator(radius: 10)
                      else
                        Icon(
                          CupertinoIcons.arrow_2_circlepath,
                          size: 20,
                          color: textPrimary,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isRefreshing
                                  ? 'Синхронизация с МЭШ...'
                                  : 'Обновить данные из МЭШ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Загрузить свежие оценки и расписание',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Re-auth via Mos.ID Button
              GestureDetector(
                onTap: _handleReAuth,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.person_crop_circle_badge_checkmark,
                        size: 20,
                        color: CupertinoColors.activeBlue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Повторная авторизация Mos.ID',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Обновить сессию доступа к дневнику',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Theme Switcher Row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDark
                              ? CupertinoIcons.moon_fill
                              : CupertinoIcons.sun_max_fill,
                          size: 20,
                          color: textPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Темная монохромная тема',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    CupertinoSwitch(
                      value: isDark,
                      activeTrackColor: CupertinoColors.white,
                      thumbColor: CupertinoColors.black,
                      onChanged: (_) => widget.viewModel.toggleTheme(),
                    ),
                  ],
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}
