import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/repo/auth_repository.dart';
import '../../../service_core/auth/session_manager.dart';
import '../../../service_core/networks/graphql_client_provider.dart';
import '../../../service_core/notifications/notification_service.dart';
import '../../home/home_binding.dart';
import '../../home/home_page.dart';
import '../../invite/invite_code_binding.dart';
import '../../invite/invite_code_page.dart';

class LoginController extends GetxController {
  final AuthRepository authRepo;

  LoginController({required this.authRepo});

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final obscurePassword = true.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Please enter email and password.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await authRepo.loginWithEmail(email, password);
      await GraphQLClientProvider.reinitWithToken();

      // validateAppAccess enforces role separation on the backend and returns
      // specific, user-readable error messages when the wrong account type is
      // used (e.g. customer account, or unregistered account).
      final user = await authRepo.validateAppAccess();

      final session = Get.find<SessionManager>();
      session.setUser(user);

      // No storeId yet → staff needs to enter their invite code
      if (user.storeId == null || user.storeId!.isEmpty) {
        Get.offAll(() => const InviteCodePage(), binding: InviteCodeBinding());
        return;
      }

      // Fetch store details for the staff card
      try {
        final store = await authRepo.getStoreById(user.storeId!);
        if (store != null) session.setStore(store);
      } catch (_) {}

      // Register FCM token
      final token = await Get.find<NotificationService>().getToken();
      if (token != null) await authRepo.updateFcmToken(token);

      Get.offAll(() => const HomePage(), binding: HomeBinding());
    } catch (e) {
      errorMessage.value = _friendlyError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password') ||
        raw.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (raw.contains('network') || raw.contains('NO_NETWORK')) {
      return 'Network error. Check your connection.';
    }
    if (raw.contains('SESSION_EXPIRED')) {
      return 'Session expired. Please sign in again.';
    }
    // Pass through backend-originated messages verbatim — they are already
    // user-readable (account separation errors, role errors, etc.).
    if (raw.contains('Customer') || raw.contains('Staff') ||
        raw.contains('No staff account') || raw.contains('does not have staff')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return 'Login failed. Please try again.';
  }
}
