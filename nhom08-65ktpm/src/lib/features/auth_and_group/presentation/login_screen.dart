import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';

/// Màn hình Đăng nhập — chuyển trực tiếp từ Stitch (ng_nh_p_travel_buddy).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: '2351170568@e.tlu.edu.vn');
  final _passwordController = TextEditingController(text: '12345678');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // TODO(Module 1): Thay bằng AuthRepository.signInWithEmailAndPassword()
    context.go('/trips');
  }

  void _handleGoogleSignIn() {
    // TODO(Module 1): Thay bằng AuthRepository.signInWithGoogle()
    context.go('/trips');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.explore,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Travel Buddy',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Checklist chuẩn bị • Quỹ nhóm MoMo • Ngân sách',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    // Form
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppInsetCard(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 80,
                                      child: Text(
                                        'Email',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          hintText: 'tenban@e.tlu.edu.vn',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(indent: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 80,
                                      child: Text(
                                        'Mật khẩu',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        decoration: const InputDecoration(
                                          hintText: 'Nhập mật khẩu',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO(Module 1): Mở luồng Quên mật khẩu Firebase Auth
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('TODO: Gửi email đặt lại mật khẩu')),
                              );
                            },
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                color: AppColors.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppPrimaryButton(
                          label: 'Đăng nhập',
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _handleGoogleSignIn,
                            icon: const Icon(Icons.g_mobiledata, size: 28, color: AppColors.primary),
                            label: const Text(
                              'Tiếp tục với Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.surfaceContainer,
                              side: const BorderSide(color: AppColors.outlineVariantSoft),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Footer
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Chưa có tài khoản? ', style: Theme.of(context).textTheme.bodySmall),
                          GestureDetector(
                            onTap: () {
                              // TODO(Module 1): Điều hướng tới màn hình Đăng ký
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('TODO: Mở màn hình Đăng ký tài khoản')),
                              );
                            },
                            child: const Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
