/// Maps to the backend AuthResult record.
/// status: "NEW_USER" or "EXISTING_USER"
class AuthResponse {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final int? userId;
  final String? status; // "NEW_USER" | "EXISTING_USER"

  const AuthResponse({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.status,
  });

  bool get isNewUser => status == 'NEW_USER';

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: true,
      message: '',
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      userId: json['userId'] is int
          ? json['userId'] as int
          : int.tryParse(json['userId']?.toString() ?? ''),
      status: json['status'],
    );
  }

  factory AuthResponse.error(String msg) =>
      AuthResponse(success: false, message: msg);
}
