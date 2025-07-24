import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  // Save user data
  static Future<bool> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      
      if (user.token != null) {
        await prefs.setString(_tokenKey, user.token!);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user data
  static Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        print('Raw stored JSON: $userJson'); // Debug what's actually stored
        
        final userMap = jsonDecode(userJson);
        print('Parsed JSON Map: $userMap'); // Debug the parsed map
        
        return User.fromJson(userMap);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Get token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  // Clear user data
  static Future<bool> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = await getUser();
    final token = await getToken();
    return user != null && token != null;
  }
}