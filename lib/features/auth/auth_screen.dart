import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_routes.dart';
import '../../config/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../repositories/user_repository.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginKey = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupLocationController = TextEditingController();
  final _signupPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  bool _isCheckingSession = false;
  String _accountType = 'Farmer';

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    if (_isCheckingSession) return;
    _isCheckingSession = true;

    try {
      final userId = await SessionService.instance.getSessionUserId();
      if (userId == null || userId <= 0) {
        await SessionService.instance.clearSession();
        if (!mounted) return;
        return;
      }

      final user = await UserRepository().getUserById(userId);
      if (user == null) {
        await SessionService.instance.clearSession();
        if (!mounted) return;
        return;
      }

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (route) => false,
      );
    } finally {
      if (mounted) {
        _isCheckingSession = false;
      }
    }
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupPhoneController.dispose();
    _signupEmailController.dispose();
    _signupLocationController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode(bool login) {
    setState(() {
      _isLogin = login;
      _isSubmitting = false;
    });
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final formKey = _isLogin ? _loginKey : _signupKey;
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSubmitting = true);

    try {
      late final AuthResult result;

      if (_isLogin) {
        result = await _authService.signIn(
          email: _loginEmailController.text,
          password: _loginPasswordController.text,
        );
      } else {
        result = await _authService.signUp(
          name: _signupNameController.text,
          email: _signupEmailController.text,
          password: _signupPasswordController.text,
          phone: _signupPhoneController.text,
          role: _accountType,
          location: _signupLocationController.text,
        );
      }

      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Authentication failed.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      if (!_isLogin) {
        _loginEmailController.text = _signupEmailController.text.trim().toLowerCase();
        _loginPasswordController.text = _signupPasswordController.text;
        _signupNameController.clear();
        _signupPhoneController.clear();
        _signupEmailController.clear();
        _signupLocationController.clear();
        _signupPasswordController.clear();
        setState(() {
          _isLogin = true;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Authentication successful.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryDark,
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return isWide
                ? Row(
                    children: [
                      Expanded(
                        child: _WelcomePanel(),
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: _AuthPanel(
                              isLogin: _isLogin,
                              accountType: _accountType,
                              isPasswordVisible: _isPasswordVisible,
                              isSubmitting: _isSubmitting,
                              loginEmailController: _loginEmailController,
                              loginPasswordController: _loginPasswordController,
                              signupNameController: _signupNameController,
                              signupPhoneController: _signupPhoneController,
                              signupEmailController: _signupEmailController,
                              signupLocationController: _signupLocationController,
                              signupPasswordController: _signupPasswordController,
                              loginFormKey: _loginKey,
                              signupFormKey: _signupKey,
                              onToggleMode: _toggleMode,
                              onTogglePassword: () {
                                setState(() => _isPasswordVisible = !_isPasswordVisible);
                              },
                              onAccountTypeChanged: (type) {
                                setState(() => _accountType = type);
                              },
                              onSubmit: _handleSubmit,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: _AuthPanel(
                        isLogin: _isLogin,
                        accountType: _accountType,
                        isPasswordVisible: _isPasswordVisible,
                        isSubmitting: _isSubmitting,
                        loginEmailController: _loginEmailController,
                        loginPasswordController: _loginPasswordController,
                        signupNameController: _signupNameController,
                        signupPhoneController: _signupPhoneController,
                        signupEmailController: _signupEmailController,
                        signupLocationController: _signupLocationController,
                        signupPasswordController: _signupPasswordController,
                        loginFormKey: _loginKey,
                        signupFormKey: _signupKey,
                        onToggleMode: _toggleMode,
                        onTogglePassword: () {
                          setState(() => _isPasswordVisible = !_isPasswordVisible);
                        },
                        onAccountTypeChanged: (type) {
                          setState(() => _accountType = type);
                        },
                        onSubmit: _handleSubmit,
                      ),
                    ),
                  );
          },
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🐄', style: TextStyle(fontSize: 70)),
            SizedBox(height: 20),
            Text(
              'MastiCare Pro',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'A complete smart cattle-health dashboard for thermal-image based mastitis screening, cattle management, health history and veterinary follow-up.',
              style: TextStyle(
                fontSize: 18,
                height: 1.7,
                color: Color(0xFFD9F1E9),
              ),
            ),
            SizedBox(height: 24),
            Text('✓ Farmer & veterinarian accounts', style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('✓ Cattle profiles and health records', style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('✓ Thermal image analysis workflow', style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('✓ History, trends, alerts and reports', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.isLogin,
    required this.accountType,
    required this.isPasswordVisible,
    required this.isSubmitting,
    required this.loginEmailController,
    required this.loginPasswordController,
    required this.signupNameController,
    required this.signupPhoneController,
    required this.signupEmailController,
    required this.signupLocationController,
    required this.signupPasswordController,
    required this.loginFormKey,
    required this.signupFormKey,
    required this.onToggleMode,
    required this.onTogglePassword,
    required this.onAccountTypeChanged,
    required this.onSubmit,
  });

  final bool isLogin;
  final String accountType;
  final bool isPasswordVisible;
  final bool isSubmitting;
  final TextEditingController loginEmailController;
  final TextEditingController loginPasswordController;
  final TextEditingController signupNameController;
  final TextEditingController signupPhoneController;
  final TextEditingController signupEmailController;
  final TextEditingController signupLocationController;
  final TextEditingController signupPasswordController;
  final GlobalKey<FormState> loginFormKey;
  final GlobalKey<FormState> signupFormKey;
  final void Function(bool) onToggleMode;
  final VoidCallback onTogglePassword;
  final ValueChanged<String> onAccountTypeChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Make the auth panel vertically scrollable when the available height
      // is smaller than the content. When there's enough vertical space, the
      // content remains centered to preserve the visual design.
      return Container(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: SingleChildScrollView(
            // Allow the panel to scroll independently when necessary.
            physics: const AlwaysScrollableScrollPhysics(),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Text('🐄', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const Text(
                        'MastiCare Pro',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF5F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onToggleMode(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isLogin ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: isLogin ? const [BoxShadow(color: Color(0x11000000), blurRadius: 8)] : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: isLogin ? AppColors.primary : const Color(0xFF66766F),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onToggleMode(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isLogin ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: !isLogin ? const [BoxShadow(color: Color(0x11000000), blurRadius: 8)] : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: !isLogin ? AppColors.primary : const Color(0xFF66766F),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isLogin) ...[
                    _LoginForm(
                      formKey: loginFormKey,
                      emailController: loginEmailController,
                      passwordController: loginPasswordController,
                      isPasswordVisible: isPasswordVisible,
                      isSubmitting: isSubmitting,
                      onTogglePassword: onTogglePassword,
                      onSubmit: onSubmit,
                    ),
                  ] else ...[
                    _SignupForm(
                      formKey: signupFormKey,
                      accountType: accountType,
                      nameController: signupNameController,
                      phoneController: signupPhoneController,
                      emailController: signupEmailController,
                      locationController: signupLocationController,
                      passwordController: signupPasswordController,
                      isPasswordVisible: isPasswordVisible,
                      isSubmitting: isSubmitting,
                      onTogglePassword: onTogglePassword,
                      onAccountTypeChanged: onAccountTypeChanged,
                      onSubmit: onSubmit,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.isSubmitting,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool isSubmitting;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome back', style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          const Text('Access your cattle health dashboard.', style: AppTypography.bodyMedium),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Email',
            hintText: 'you@example.com',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Password',
            hintText: '••••••••',
            controller: passwordController,
            obscureText: !isPasswordVisible,
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: isSubmitting ? 'Signing In...' : 'Sign In',
              onPressed: isSubmitting ? null : () => onSubmit(),
              isLoading: isSubmitting,
              fullWidth: true,
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _SignupForm extends StatelessWidget {
  const _SignupForm({
    required this.formKey,
    required this.accountType,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.locationController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.isSubmitting,
    required this.onTogglePassword,
    required this.onAccountTypeChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final String accountType;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController locationController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool isSubmitting;
  final VoidCallback onTogglePassword;
  final ValueChanged<String> onAccountTypeChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create account', style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          const Text('Choose your role and enter basic information.', style: AppTypography.bodyMedium),
          const SizedBox(height: 20),
          Text('Account Type', style: AppTypography.label),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onAccountTypeChanged('Farmer'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: accountType == 'Farmer' ? AppColors.primarySoft : Colors.transparent,
                      border: Border.all(
                        color: accountType == 'Farmer' ? AppColors.primary : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Center(
                      child: Text('👨‍🌾 Farmer', style: TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => onAccountTypeChanged('Veterinarian'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: accountType == 'Veterinarian' ? AppColors.primarySoft : Colors.transparent,
                      border: Border.all(
                        color: accountType == 'Veterinarian' ? AppColors.primary : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Center(
                      child: Text('🩺 Veterinarian', style: TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Full Name',
            hintText: 'Full name',
            controller: nameController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required';
              }
              if (value.trim().length < 2) {
                return 'Enter a valid full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Phone',
            hintText: '+91 XXXXX XXXXX',
            controller: phoneController,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone is required';
              }
              if (value.trim().length < 8) {
                return 'Enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Email',
            hintText: 'you@example.com',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Village / City',
            hintText: 'Location',
            controller: locationController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Village or city is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Password',
            hintText: 'Create password',
            controller: passwordController,
            obscureText: !isPasswordVisible,
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: isSubmitting ? 'Creating account...' : 'Create Account',
              onPressed: isSubmitting ? null : () => onSubmit(),
              isLoading: isSubmitting,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}
