import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truck_mate/core/network/api_constants.dart';
import 'package:truck_mate/features/auth/presentation/screens/login_screen.dart';
import 'package:truck_mate/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:truck_mate/features/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _navigateToLogin();
      return;
    }

    try {
      // Decode JWT to check expiration
      final parts = token.split('.');
      if (parts.length != 3) {
        _navigateToLogin();
        return;
      }

      final payloadString = _decodeBase64(parts[1]);
      final payloadMap = json.decode(payloadString);

      if (payloadMap is Map<String, dynamic> && payloadMap.containsKey('exp')) {
        final exp = payloadMap['exp'] as int;
        final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (exp < currentTime) {
          await prefs.remove('access_token');
          _navigateToLogin();
          return;
        }
      }

      // Ask the backend if the profile is complete — source of truth
      final profileDone = await _checkProfileCompletedFromBackend(token);
      if (!mounted) return;
      if (profileDone) {
        _navigateToHome();
      } else {
        _navigateToProfileSetup();
      }
    } catch (e) {
      await prefs.remove('access_token');
      _navigateToLogin();
    }
  }

  /// Calls GET /api/v1/profile and reads the profileCompleted field.
  /// Returns true if the profile has been completed on the backend.
  Future<bool> _checkProfileCompletedFromBackend(String token) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profile}');
      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        return data['profileCompleted'] == true;
      }
      // On error fall back to local flag so app doesn't break offline
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('profile_completed') ?? false;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('profile_completed') ?? false;
    }
  }


  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!');
    }
    return utf8.decode(base64Url.decode(output));
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToProfileSetup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0095F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 24),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                ),
                children: const [
                  TextSpan(text: 'Truck'),
                  TextSpan(
                    text: 'Mate',
                    style: TextStyle(color: Color(0xFF0095F6)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0095F6)),
            ),
          ],
        ),
      ),
    );
  }
}
