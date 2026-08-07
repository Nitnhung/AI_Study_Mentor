import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../home/pages/home_screen.dart';
import '../models/auth_copy.dart';
import '../widgets/auth_hero_mark.dart';
import '../widgets/auth_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _isEnglish = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  AuthCopy get _copy => _isEnglish ? AuthCopy.english : AuthCopy.vietnamese;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ── VALIDATION ────────────────────────────────────────
  String? _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (_isSignUp && name.isEmpty) return 'Vui lòng nhập họ tên.';
    if (email.isEmpty) return 'Vui lòng nhập email.';
    if (!email.contains('@') || !email.contains('.')) return 'Email không hợp lệ.';
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (password.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.';
    return null;
  }

  Future<void> _submitAuth() async {
    // Validate trước — không gửi API nếu thiếu thông tin
    final error = _validate();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = _isSignUp
          ? await ApiService.register(_emailController.text.trim(), _passwordController.text, _nameController.text.trim())
          : await ApiService.login(_emailController.text.trim(), _passwordController.text);
      if (result['success'] == true) {
        if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() => _errorMessage = result['message']?.toString() ?? 'Thao tác thất bại');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Không kết nối được server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 18, 16, 24 + bottomInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerRight,
                    child: IconButton(tooltip: _copy.switchLanguageTooltip,
                      onPressed: () => setState(() => _isEnglish = !_isEnglish),
                      icon: const Icon(Icons.language, color: AppColors.primary, size: 25))),
                  SizedBox(height: _isSignUp ? 70 : 112),
                  AuthHeroMark(isSignUp: _isSignUp),
                  const SizedBox(height: 24),
                  Text(_isSignUp ? _copy.signUpTitle : _copy.loginTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.primary, fontSize: 27, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(_isSignUp ? _copy.signUpSubtitle : _copy.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 38),
                  if (_isSignUp) ...[
                    AuthTextField(icon: Icons.person, hintText: _copy.fullName, controller: _nameController, maxLength: 50),
                    const SizedBox(height: 20),
                  ],
                  AuthTextField(icon: Icons.mail, hintText: _copy.email, controller: _emailController,
                    keyboardType: TextInputType.emailAddress, maxLength: 100),
                  const SizedBox(height: 20),
                  AuthTextField(icon: Icons.lock, hintText: _copy.password, controller: _passwordController,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? _copy.showPassword : _copy.hidePassword,
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.border, size: 21))),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage!, textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() { _isSignUp = !_isSignUp; _errorMessage = null; }),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      child: Text(_isSignUp ? _copy.loginPrompt : _copy.signUpPrompt))),
                  const SizedBox(height: 14),
                  SizedBox(height: 46,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submitAuth,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white, shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isSignUp ? _copy.signUpTitle : _copy.loginTitle))),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
