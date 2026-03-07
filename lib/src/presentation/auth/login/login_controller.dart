import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/usecase/get_profile_usecase.dart';
import '../../../domain/repo/auth_repository.dart';
import '../../../service_core/auth/session_manager.dart';
import '../../../service_core/networks/graphql_client_provider.dart';
import '../../../service_core/notifications/notification_service.dart';
import '../../orders/orders_binding.dart';
import '../../orders/orders_page.dart';

class LoginController extends GetxController {
  final AuthRepository authRepo;
  final GetProfileUseCase getProfileUseCase;

  LoginController({
    required this.authRepo,
    required this.getProfileUseCase,
  });

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

      final user = await getProfileUseCase.execute();

      if (!user.isStaff && !user.isAdmin) {
        await authRepo.signOut();
        GraphQLClientProvider.reset();
        errorMessage.value = 'Account not activated yet. Contact your admin.';
        return;
      }

      if (user.storeId == null) {
        await authRepo.signOut();
        GraphQLClientProvider.reset();
        errorMessage.value = 'No store assigned to your account. Contact admin.';
        return;
      }

      Get.find<SessionManager>().setUser(user);

      // Register FCM token
      final token = await Get.find<NotificationService>().getToken();
      if (token != null) await authRepo.updateFcmToken(token);

      Get.offAll(() => const OrdersPage(), binding: OrdersBinding());
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
    if (raw.contains('network')) return 'Network error. Check your connection.';
    return 'Login failed. Please try again.';
  }
}
