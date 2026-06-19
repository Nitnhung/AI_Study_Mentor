import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
  static const _demoEmail = 'admin@gmail.com';
  static const _demoPassword = '123456';

  bool _isSignUp = false;
  bool _isEnglish = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final _emailController = TextEditingController(text: _demoEmail);
  final _passwordController = TextEditingController(text: _demoPassword);

  AuthCopy get _copy => _isEnglish ? AuthCopy.english : AuthCopy.vietnamese;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, 18, 16, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 42,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: _copy.switchLanguageTooltip,
                        onPressed: () {
                          setState(() => _isEnglish = !_isEnglish);
                        },
                        icon: const Icon(
                          Icons.language,
                          color: AppColors.primary,
                          size: 25,
                        ),
                      ),
                    ),
                    SizedBox(height: _isSignUp ? 70 : 112),
                    AuthHeroMark(isSignUp: _isSignUp),
                    const SizedBox(height: 24),
                    Text(
                      _isSignUp ? _copy.signUpTitle : _copy.loginTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp ? _copy.signUpSubtitle : _copy.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 38),
                    if (_isSignUp) ...[
                      AuthTextField(
                        icon: Icons.person,
                        hintText: _copy.fullName,
                      ),
                      const SizedBox(height: 20),
                    ],
                    AuthTextField(
                      icon: Icons.mail,
                      hintText: _copy.email,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    AuthTextField(
                      icon: Icons.lock,
                      hintText: _copy.password,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? _copy.showPassword
                            : _copy.hidePassword,
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.border,
                          size: 21,
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_copy.demoAccount}: $_demoEmail / $_demoPassword',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() => _isSignUp = !_isSignUp);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(
                          _isSignUp ? _copy.loginPrompt : _copy.signUpPrompt,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 46,
                      child: FilledButton(
                        onPressed: _submitAuth,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(
                          _isSignUp ? _copy.signUpTitle : _copy.loginTitle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _submitAuth() {
    if (_isSignUp ||
        (_emailController.text.trim() == _demoEmail &&
            _passwordController.text == _demoPassword)) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      return;
    }

    setState(() {
      _errorMessage = _copy.invalidDemoAccount;
    });
  }
}
