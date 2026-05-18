import 'package:dq_staff/design_system/design_system.dart';
import 'package:dq_staff/src/utils/responsive/responsive.dart';
import 'package:dq_staff/widgets/themed_background.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';
import 'register_controller.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RegisterController>();

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Create Account'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: AppTheme.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg + 2),
                          const Text('Staff Registration',
                              style: AppTypography.titleLarge),
                          const SizedBox(height: AppSpacing.xs + 2),
                          const Text(
                            'Create your account. Admin will activate it.',
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
                                  controller: c.nameController,
                                  keyboardType: TextInputType.name,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary),
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: Icon(Icons.person_outline,
                                        color: AppTheme.textSecondary),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md + 2),
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
                                const SizedBox(height: AppSpacing.md + 2),
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
                                // Error — covers both Firebase and registerInBackend errors
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
                                            : c.register,
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
                                            : const Text('Create Account',
                                                style:
                                                    AppTypography.button),
                                      )),
                                ),
                              ],
                            ),
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
