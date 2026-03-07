import 'package:dq_staff/widgets/themed_background.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';
import '../register/register_binding.dart';
import '../register/register_page.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoginController>();

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo / title
                  const SizedBox(height: 16),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          width: 2),
                    ),
                    child: const Icon(Icons.store_rounded,
                        color: AppTheme.primary, size: 36),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'DQ Staff',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to manage your store orders',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Email field
                  TextField(
                    controller: c.emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  Obx(() => TextField(
                        controller: c.passwordController,
                        obscureText: c.obscurePassword.value,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppTheme.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              c.obscurePassword.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () => c.obscurePassword.toggle(),
                          ),
                        ),
                      )),
                  const SizedBox(height: 12),

                  // Error message
                  Obx(() => c.errorMessage.value.isNotEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(c.errorMessage.value,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13)),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink()),

                  const SizedBox(height: 8),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Obx(() => ElevatedButton(
                          onPressed: c.isLoading.value ? null : c.login,
                          child: c.isLoading.value
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Sign In',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        )),
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                      GestureDetector(
                        onTap: () => Get.to(
                          () => const RegisterPage(),
                          binding: RegisterBinding(),
                        ),
                        child: Text('Register',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.primary,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
