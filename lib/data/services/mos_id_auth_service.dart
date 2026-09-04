import 'cache_service.dart';
import '../models/user_profile.dart';

class MosIdAuthService {
  final CacheService _cacheService;

  MosIdAuthService({CacheService? cacheService})
      : _cacheService = cacheService ?? CacheService();

  Future<void> saveAuthSession({
    required String authToken,
    String? cookies,
    String? studentId,
    UserProfile? profile,
  }) async {
    await _cacheService.saveAuthToken(authToken);
    if (cookies != null && cookies.isNotEmpty) {
      await _cacheService.saveCookies(cookies);
    }
    if (studentId != null && studentId.isNotEmpty) {
      await _cacheService.saveStudentId(studentId);
    }
    if (profile != null) {
      await _cacheService.saveProfile(profile);
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _cacheService.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _cacheService.clearAll();
  }
}
