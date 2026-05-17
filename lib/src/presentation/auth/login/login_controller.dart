import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_config.dart';
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
      debugPrint('[LoginController] login() start — email=$email  env=${AppConfig.flavor}  endpoint=${AppConfig.graphqlEndpoint}');

      await authRepo.loginWithEmail(email, password);
      debugPrint('[LoginController] Firebase signIn OK — reinitializing GraphQL client');

      await GraphQLClientProvider.reinitWithToken();
      debugPrint('[LoginController] GraphQL client reinitialized — calling validateAppAccess(STAFF)');

      final user = await authRepo.validateAppAccess();
      debugPrint('[LoginController] validateAppAccess OK — id=${user.id}  role=${user.role}  roles=${user.roles}  storeId=${user.storeId}');

      final session = Get.find<SessionManager>();
      session.setUser(user);

      if (user.storeId == null || user.storeId!.isEmpty) {
        debugPrint('[LoginController] no storeId — routing to InviteCodePage');
        Get.offAll(() => const InviteCodePage(), binding: InviteCodeBinding());
        return;
      }

      try {
        final store = await authRepo.getStoreById(user.storeId!);
        if (store != null) {
          session.setStore(store);
          debugPrint('[LoginController] store loaded — ${store.name}');
        }
      } catch (e) {
        debugPrint('[LoginController] getStoreById non-fatal error: $e');
      }

      final token = await Get.find<NotificationService>().getToken();
      if (token != null) {
        await authRepo.updateFcmToken(token);
        debugPrint('[LoginController] FCM token registered');
      }

      debugPrint('[LoginController] login complete — routing to HomePage');
      Get.offAll(() => const HomePage(), binding: HomeBinding());
    } catch (e) {
      debugPrint('[LoginController] login() FAILED ✗  $e');
      errorMessage.value = _friendlyError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  String _friendlyError(String raw) {
    // Strip exception wrapper to get the actual message text
    final msg = raw.startsWith('Exception: ')
        ? raw.substring('Exception: '.length)
        : raw;
    final lower = msg.toLowerCase();

    // ── Firebase Auth errors (checked first — same in all envs) ────────────
    if (lower.contains('user-not-found') || lower.contains('wrong-password') ||
        lower.contains('invalid-credential') ||
        lower.contains('invalid-login-credentials') ||
        lower.contains('invalid-email')) {
      return 'Invalid email or password.';
    }
    if (lower.contains('too-many-requests') || lower.contains('too many')) {
      return 'Too many failed attempts. Please wait a moment and try again.';
    }
    if (lower.contains('user-disabled')) {
      return 'This account has been disabled. Contact your store admin.';
    }

    // ── Backend access/role errors — pass through verbatim in all envs ──────
    if (msg.contains('does not have staff') || msg.contains('not a staff') ||
        msg.contains('No staff account') || msg.contains('staff access') ||
        msg.contains('not authorized') || msg.contains('no access') ||
        msg.contains('Customer account') || msg.contains('Staff account') ||
        msg.contains('permission') || msg.contains('inactive') ||
        msg.contains('not active')) {
      return msg;
    }

    // ── UAT: surface ALL other errors verbatim so testers can diagnose ──────
    // This runs before the generic network/session buckets so tester always
    // sees the actual exception rather than a categorised placeholder.
    if (AppConfig.isUat) {
      return '[UAT] $msg';
    }

    // ── Production: user-friendly categorised messages ───────────────────────
    if (lower.contains('network') || lower.contains('connection') ||
        lower.contains('socket') || lower.contains('no_network') ||
        lower.contains('failed to connect') || lower.contains('timed out') ||
        lower.contains('unreachable')) {
      return 'Network error. Check your internet connection and try again.';
    }
    if (lower.contains('session_expired') || lower.contains('unauthenticated') ||
        lower.contains('token expired') || lower.contains('jwt expired')) {
      return 'Session expired. Please sign in again.';
    }
    if (msg.contains('not found') || msg.contains('not registered')) return msg;

    return 'Login failed. Please try again.';
  }
}
