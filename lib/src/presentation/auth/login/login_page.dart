import 'package:dq_staff/design_system/design_system.dart';
import 'package:dq_staff/src/utils/responsive/responsive.dart';
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
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                // minHeight keeps Center vertically centering on tall viewports
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.pagePadding,
                    vertical: AppSpacing.xxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Brand mark ──────────────────────────────────
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.store_rounded,
                              color: AppTheme.primary,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const Text('DQ Staff',
                              style: AppTypography.displayMedium),
                          const SizedBox(height: AppSpacing.xs + 2),
                          const Text(
                            'Sign in to manage your store orders',
                            style: AppTypography.labelLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xxxl - 4),

                          // ── Auth glass card ──────────────────────────────
                          DsGlassCard(
                            padding:
                                const EdgeInsets.all(AppSpacing.xxl),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: c.emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary),
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined,
                                        color: AppTheme.textSecondary),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Obx(() => TextField(
                                      controller: c.passwordController,
                                      obscureText: c.obscurePassword.value,
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(
                                            Icons.lock_outline,
                                            color: AppTheme.textSecondary),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            c.obscurePassword.value
                                                ? Icons
                                                    .visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppTheme.textSecondary,
                                          ),
                                          onPressed: () =>
                                              c.obscurePassword.toggle(),
                                        ),
                                      ),
                                    )),
                                const SizedBox(height: AppSpacing.md),
                                Obx(() => c.errorMessage.value.isNotEmpty
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: AppSpacing.sm + 2,
                                        ),
                                        margin: const EdgeInsets.only(
                                            bottom: AppSpacing.sm),
                                        decoration: BoxDecoration(
                                          color: AppColors.errorSubtle,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  AppRadius.md - 2),
                                          border: Border.all(
                                              color: AppColors.errorBorder),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: AppColors.error,
                                              size: 16,
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.sm),
                                            Expanded(
                                              child: Text(
                                                c.errorMessage.value,
                                                style: AppTypography
                                                    .bodySmall
                                                    .copyWith(
                                                        color:
                                                            AppColors.error),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink()),
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  height: AppSizes.buttonMd + 2,
                                  child: Obx(() => ElevatedButton(
                                        onPressed: c.isLoading.value
                                            ? null
                                            : c.login,
                                        child: c.isLoading.value
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text('Sign In',
                                                style:
                                                    AppTypography.button),
                                      )),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // ── Register link ────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ",
                                  style: AppTypography.label),
                              GestureDetector(
                                onTap: () => Get.to(
                                  () => const RegisterPage(),
                                  binding: RegisterBinding(),
                                ),
                                child: Text(
                                  'Register',
                                  style: AppTypography.label.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
