import '../models/user.dart';
import '../models/auth_request.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthRepository {
  // Register user
  Future<ApiResponse<User>> register(RegisterRequest request) async {
    final response = await ApiService.register(request);
    
    if (response.success && response.data != null) {
      await StorageService.saveUser(response.data!);
    }
    
    return response;
  }

  // Login user
  Future<ApiResponse<User>> login(LoginRequest request) async {
    final response = await ApiService.login(request);
    
    if (response.success && response.data != null) {
      await StorageService.saveUser(response.data!);
      
    }
    
    return response;
  }

  // Logout user
  Future<ApiResponse<void>> logout() async {
    final token = await StorageService.getToken();
    
    if (token != null) {
      final response = await ApiService.logout(token);
      await StorageService.clearUser();
      return response;
    } else {
      await StorageService.clearUser();
      return const ApiResponse<void>(
        success: true,
        message: 'Logged out successfully',
      );
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    return await StorageService.getUser();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await StorageService.isLoggedIn();
  }

  // Clear user session
  Future<void> clearSession() async {
    await StorageService.clearUser();
  }
}