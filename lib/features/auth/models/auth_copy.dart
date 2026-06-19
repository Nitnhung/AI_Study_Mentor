class AuthCopy {
  const AuthCopy({
    required this.loginTitle,
    required this.signUpTitle,
    required this.loginSubtitle,
    required this.signUpSubtitle,
    required this.fullName,
    required this.email,
    required this.password,
    required this.signUpPrompt,
    required this.loginPrompt,
    required this.showPassword,
    required this.hidePassword,
    required this.switchLanguageTooltip,
    required this.demoAccount,
    required this.invalidDemoAccount,
  });

  final String loginTitle;
  final String signUpTitle;
  final String loginSubtitle;
  final String signUpSubtitle;
  final String fullName;
  final String email;
  final String password;
  final String signUpPrompt;
  final String loginPrompt;
  final String showPassword;
  final String hidePassword;
  final String switchLanguageTooltip;
  final String demoAccount;
  final String invalidDemoAccount;

  static const vietnamese = AuthCopy(
    loginTitle: 'Đăng nhập',
    signUpTitle: 'Đăng ký',
    loginSubtitle: 'Quản lý chi tiêu thông minh',
    signUpSubtitle: 'Tạo tài khoản học tập thông minh',
    fullName: 'Họ và tên',
    email: 'Email',
    password: 'Mật khẩu',
    signUpPrompt: 'Chưa có tài khoản? Đăng ký',
    loginPrompt: 'Đã có tài khoản? Đăng nhập',
    showPassword: 'Hiện mật khẩu',
    hidePassword: 'Ẩn mật khẩu',
    switchLanguageTooltip: 'Chuyển sang tiếng Anh',
    demoAccount: 'Tài khoản demo',
    invalidDemoAccount: 'Vui lòng dùng tài khoản demo để đăng nhập',
  );

  static const english = AuthCopy(
    loginTitle: 'Login',
    signUpTitle: 'Sign up',
    loginSubtitle: 'Smart expense management',
    signUpSubtitle: 'Create a smart learning account',
    fullName: 'Full name',
    email: 'Email',
    password: 'Password',
    signUpPrompt: 'No account yet? Sign up',
    loginPrompt: 'Already have an account? Login',
    showPassword: 'Show password',
    hidePassword: 'Hide password',
    switchLanguageTooltip: 'Switch to Vietnamese',
    demoAccount: 'Demo account',
    invalidDemoAccount: 'Please use the demo account to login',
  );
}
