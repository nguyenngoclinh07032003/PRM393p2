import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';

class LocalStorageService {
  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // User ID
  Future<void> saveUserId(String userId) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.keyUserId, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getString(AppConstants.keyUserId);
  }

  // User Role
  Future<void> saveUserRole(String role) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.keyUserRole, role);
  }

  Future<String?> getUserRole() async {
    final prefs = await _prefs;
    return prefs.getString(AppConstants.keyUserRole);
  }

  // Login Status
  Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await _prefs;
    await prefs.setBool(AppConstants.keyIsLoggedIn, isLoggedIn);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _prefs;
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  // Clear all data
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
