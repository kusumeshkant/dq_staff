import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'invite_code_controller.dart';

class InviteCodePage extends StatelessWidget {
  const InviteCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<InviteCodeController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.mail_outline_rounded, color: Color(0xFF4CAF50), size: 38),
              ),
              const SizedBox(height: 28),

              // Title
              const Text(
                'Enter Invite Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your store admin sent you an invite email.\nEnter the code from that email to join your store.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 40),

              // Code input
              TextField(
                controller: c.codeCtrl,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                decoration: InputDecoration(
                  hintText: 'DQ-XXXX-XXXX',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 20,
                    letterSpacing: 4,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                  ),
                ),
                onSubmitted: (_) => c.submitCode(),
              ),
              const SizedBox(height: 12),

              // Error message
              Obx(() => c.errorMessage.value.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        c.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    )),
              const SizedBox(height: 12),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(() => ElevatedButton(
                      onPressed: c.isLoading.value ? null : c.submitCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: c.isLoading.value
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Join Store',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    )),
              ),
              const SizedBox(height: 48),

              // Divider
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 20),

              // Help text
              const Text(
                "Don't have a code?",
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ask your store admin to invite you from the DQ Admin app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
              const SizedBox(height: 24),

              // Sign out
              GestureDetector(
                onTap: c.signOut,
                child: const Text(
                  'Sign out',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
