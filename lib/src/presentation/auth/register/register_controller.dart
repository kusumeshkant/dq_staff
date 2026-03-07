import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/repo/auth_repository.dart';
import '../../../service_core/networks/graphql_client_provider.dart';
import '../login/login_page.dart';
import '../login/login_binding.dart';

class RegisterController extends GetxController {
  final AuthRepository authRepo;

  RegisterController({required this.authRepo});

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final obscurePassword = true.obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Please fill in all fields.';
      return;
    }
    if (password.length < 6) {
      errorMessage.value = 'Password must be at least 6 characters.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await authRepo.registerWithEmail(email, password);
      await GraphQLClientProvider.reinitWithToken();
      await authRepo.updateProfileName(name);
      await authRepo.signOut();
      GraphQLClientProvider.reset();

      Get.offAll(
        () => const LoginPage(),
        binding: LoginBinding(),
      );
      Get.snackbar(
        'Account Created',
        'Your account is pending activation. Contact your admin to get access.',
        backgroundColor: Colors.green.withValues(alpha: 0.85),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      errorMessage.value = _friendlyError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('invalid-email')) return 'Invalid email address.';
    if (raw.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (raw.contains('network')) return 'Network error. Check your connection.';
    return 'Registration failed. Please try again.';
  }
}
