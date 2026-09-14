import 'package:flutter/material.dart';
import 'package:truck_mate/core/theme/app_theme.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'otp_verify_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepository = AuthRepositoryImpl();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validate);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_validate);
    _phoneController.dispose();
    super.dispose();
  }

  void _validate() {
    final text = _phoneController.text.trim();
    setState(() {
      if (text.isEmpty) {
        _errorText = null;
        _isButtonEnabled = false;
      } else if (text.length == 10 && RegExp(r'^[0-9]+$').hasMatch(text)) {
        _errorText = null;
        _isButtonEnabled = true;
      } else {
        _isButtonEnabled = false;
        if (text.length > 10) {
          _errorText = 'Mobile number cannot exceed 10 digits';
        } else if (!RegExp(r'^[0-9]*$').hasMatch(text)) {
          _errorText = 'Please enter numbers only';
        } else {
          _errorText = null;
        }
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _errorText = 'Enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await _authRepository.sendOtp(phone);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(phoneNumber: phone),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(e.toString())),
        ]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Branding ─────────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: isDark ? 0.3 : 0.06),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_shipping,
                            color: Colors.white, size: 38),
                      ),
                    ),
                    const SizedBox(height: 24),
                    RichText(
                      text: TextSpan(
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  letterSpacing: -0.5,
                                ),
                        children: const [
                          TextSpan(text: 'Truck'),
                          TextSpan(
                            text: 'Mate',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Safe & On-time Delivery 🚚',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                    ),
                    Text(
                      'Pan India Services',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),

                // ── Form ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Get Started',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your mobile number to receive a one-time verification code.',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                      ),
                      const SizedBox(height: 24),
                      CustomPhoneField(
                        controller: _phoneController,
                        errorText: _errorText,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Get OTP',
                        onPressed: _isButtonEnabled ? _handleSendOtp : null,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),

                // ── Footer ────────────────────────────────────────────────
                Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'By continuing, you agree to our',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.grey.shade500
                                : const Color(0xFF8E8E8E),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Terms of Service',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text('  &  ',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : const Color(0xFF8E8E8E))),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Privacy Policy',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
