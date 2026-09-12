import 'package:dq_staff/design_system/design_system.dart';
import 'package:dq_staff/src/constants/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/repo/auth_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../service_core/networks/graphql_client_provider.dart';

class RegisterController extends GetxController {
  final AuthRepository authRepo;

  RegisterController({required this.authRepo});

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final inviteCodeController = TextEditingController();
  final obscurePassword = true.obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    inviteCodeController.dispose();
    super.onClose();
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final inviteCode = inviteCodeController.text.trim().toUpperCase();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Please fill in all fields.';
      return;
    }
    // Staff registration is invite-only. Checked here as well as server-side so
    // the user is not asked to create a Firebase account we would then have to
    // roll back.
    if (inviteCode.isEmpty) {
      errorMessage.value =
          'An invite code is required. Ask your store admin to send you one.';
      return;
    }
    if (password.length < 8) {
      errorMessage.value = 'Password must be at least 8 characters.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // ── Step 1: Create Firebase account ────────────────────────────────────
      // After this succeeds the user is signed in to Firebase.
      debugPrint('[Register] step 1: Firebase createUser email=$email');
      await authRepo.registerWithEmail(email, password);
      debugPrint('[Register] step 1 OK');

      // ── Step 2: Init GraphQL client (auth token now available) ──────────────
      await GraphQLClientProvider.reinitWithToken();

      // ── Step 3: Create backend DB record and set display name ───────────────
      // Uses a login-scoped GraphQL client (no ErrorLink), so any backend
      // error surfaces as a plain exception rather than triggering
      // SessionManager.expireSession() and showing a false "Session Expired".
      debugPrint('[Register] step 3: backend onboarding name=$name code=$inviteCode');
      try {
        await authRepo.registerInBackend(name, inviteCode);
        debugPrint('[Register] step 3 OK');
      } catch (backendError) {
        // Backend creation failed — roll back by deleting the Firebase account
        // so there is no zombie Firebase user with no backend record.
        debugPrint('[Register] step 3 FAILED — rolling back Firebase account: $backendError');
        try {
          await FirebaseAuth.instance.currentUser?.delete();
          debugPrint('[Register] Firebase account deleted (rollback OK)');
        } catch (deleteErr) {
          // Non-fatal: the account may already be in an inconsistent state.
          // The user can try again with the same email once Firebase propagates
          // the deletion (usually within seconds).
          debugPrint('[Register] Firebase delete failed (non-fatal): $deleteErr');
        }
        GraphQLClientProvider.reset();
        errorMessage.value = _friendlyBackendError(backendError.toString());
        return;
      }

      // ── Step 4: Sign out Firebase — login page starts clean ─────────────────
      debugPrint('[Register] step 4: signOut + navigate to LoginPage');
      await authRepo.signOut();
      GraphQLClientProvider.reset();

      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Account Created',
        'Your staff account is ready. Sign in to get started.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Firebase account creation failed (e.g. email-already-in-use) or an
      // unexpected pre-step-3 error. No backend record was created so no
      // rollback is needed.
      debugPrint('[Register] FAILED (pre-backend): $e');
      errorMessage.value = _friendlyFirebaseError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  String _friendlyFirebaseError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('invalid-email')) return 'Invalid email address.';
    if (raw.contains('weak-password')) {
      return 'Password is too weak. Use at least 8 characters.';
    }
    if (raw.contains('network-request-failed') || raw.contains('network')) {
      return 'Network error. Check your connection and try again.';
    }
    if (AppConfig.isUat) {
      final msg = raw.startsWith('Exception: ')
          ? raw.substring('Exception: '.length)
          : raw;
      return '[UAT] $msg';
    }
    return 'Registration failed. Please try again.';
  }

  String _friendlyBackendError(String raw) {
    final msg =
        raw.startsWith('Exception: ') ? raw.substring('Exception: '.length) : raw;
    final lower = msg.toLowerCase();

    // Invite errors are the most likely failure here and the backend already
    // phrases them for the user ("expired", "already been used", "issued to a
    // different email address"). Pass them through — replacing them with a
    // generic message would strip the only actionable detail.
    if (lower.contains('invite')) return msg;

    if (lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('reach')) {
      return 'Could not connect to server. Check your internet connection and try again.';
    }
    if (AppConfig.isUat) return '[UAT] $msg';
    return 'Account setup failed. Please try again.';
  }
}
