import '../entities/auth_response.dart';

abstract class AuthRepository {
  /// Step 1: Sends OTP to the given phone number.
  Future<void> sendOtp(String phoneNumber);

  /// Step 2: Verifies OTP. Returns AuthResult with accessToken + refreshToken.
  Future<AuthResponse> verifyOtp(String phoneNumber, String otp);

  /// Refresh the access token using a refresh token.
  Future<AuthResponse> refreshAccessToken(String refreshToken);

  /// Logout — invalidates the refresh token on the backend.
  Future<void> logout();
}
