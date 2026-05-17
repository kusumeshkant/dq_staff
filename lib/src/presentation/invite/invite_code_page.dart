import 'package:dq_staff/design_system/design_system.dart';
import 'package:dq_staff/widgets/themed_background.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'invite_code_controller.dart';

class InviteCodePage extends StatelessWidget {
  const InviteCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<InviteCodeController>();

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.huge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xxl),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.glassWhite20, width: 2),
                  ),
                  child: const Icon(Icons.mail_outline_rounded,
                      color: AppColors.primary, size: 38),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Title
                Text(
                  'Enter Invite Code',
                  style: AppTypography.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your store admin sent you an invite email.\nEnter the code from that email to join your store.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.huge),

                // Code input
                TextField(
                  controller: c.codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    letterSpacing: 4,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'DQ-XXXX-XXXX',
                    hintStyle: AppTypography.titleSmall.copyWith(
                      color: AppColors.textDisabled,
                      letterSpacing: 4,
                    ),
                    filled: true,
                    fillColor: AppColors.glassWhite07,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(color: AppColors.glassWhite15),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(color: AppColors.glassWhite15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  onSubmitted: (_) => c.submitCode(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Error message
                Obx(() => c.errorMessage.value.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          c.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.error),
                        ),
                      )),
                const SizedBox(height: AppSpacing.md),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => DsButton(
                        label: 'Join Store',
                        isLoading: c.isLoading.value,
                        onPressed: c.isLoading.value ? null : c.submitCode,
                        width: double.infinity,
                      )),
                ),
                const SizedBox(height: AppSpacing.huge),

                // Divider
                const Divider(color: AppColors.divider),
                const SizedBox(height: AppSpacing.xl),

                // Help text
                Text(
                  "Don't have a code?",
                  style:
                      AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Ask your store admin to invite you from the DQ Admin app.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textDisabled),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Sign out
                GestureDetector(
                  onTap: c.signOut,
                  child: Text(
                    'Sign out',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textDisabled,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
