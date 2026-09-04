import 'package:url_launcher/url_launcher.dart';
import 'cache_service.dart';
import '../models/user_profile.dart';

class MosIdAuthService {
  final CacheService _cacheService;

  MosIdAuthService({CacheService? cacheService})
      : _cacheService = cacheService ?? CacheService();

  static const String mosIdLoginUrl =
      'https://login.mos.ru/sps/login/methods/password?backUrl=https%3A%2F%2Fschool.mos.ru';

  Future<bool> launchMosIdWebsite() async {
    final uri = Uri.parse(mosIdLoginUrl);
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  Future<UserProfile> loginWithMosIdSuccess({String? authToken}) async {
    final token = authToken ?? 'mos_id_token_${DateTime.now().millisecondsSinceEpoch}';
    await _cacheService.saveAuthToken(token);
    final profile = UserProfile.sample();
    await _cacheService.saveProfile(profile);
    return profile;
  }

  Future<bool> isAuthenticated() async {
    final token = await _cacheService.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _cacheService.clearAll();
  }
}
