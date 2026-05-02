import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/model/user_model.dart';
import '../../domain/entity/store_entity.dart';
import '../../domain/entity/user_entity.dart';
import '../../presentation/auth/login/login_binding.dart';
import '../../presentation/auth/login/login_page.dart';

class SessionManager extends GetxService {
  static const _cacheKey = 'dq_staff_profile_v1';

  final Rx<UserEntity?> currentUser = Rx<UserEntity?>(null);

  // Guard: prevents duplicate expireSession() calls when multiple
  // concurrent requests all hit 401 and all try to expire the session.
  bool _isExpiring = false;
  final Rx<StoreEntity?> currentStore = Rx<StoreEntity?>(null);

  bool get isLoggedIn => currentUser.value != null;
  String? get storeId => currentUser.value?.storeId;
  String? get staffName => currentUser.value?.name;
  String? get staffId => currentUser.value?.id;

  void setUser(UserEntity user) {
    _isExpiring = false; // reset so future expiry works after re-login
    currentUser.value = user;
  }
  void setStore(StoreEntity store) => currentStore.value = store;

  void clearUser() {
    currentUser.value = null;
    currentStore.value = null;
  }

  // ── Profile cache (shared_preferences) ──────────────────────────────────────

  Future<void> cacheProfile(UserEntity user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'role': user.role,
          'roles': user.roles,
          'storeId': user.storeId,
        }),
      );
    } catch (e) {
      debugPrint('[SessionManager] cacheProfile failed: $e');
    }
  }

  Future<UserEntity?> loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }

  // ── Session expiry ───────────────────────────────────────────────────────────

  Future<void> expireSession() async {
    if (_isExpiring) return;
    _isExpiring = true;

    // Sign out from Firebase so the next cold start finds no live credential.
    // Must happen before clearing the local cache to avoid a race where the
    // app restarts and AuthLink fetches a token before Firebase is signed out.
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    await clearCache();
    clearUser();
    Get.closeAllSnackbars();
    if (Get.isDialogOpen ?? false) Get.back();
    if (Get.isBottomSheetOpen ?? false) Get.back();
    // Deferred to avoid "setState() called after dispose()" when dialog/sheet
    // animation is still in progress when Get.offAll fires.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(
        () => const LoginPage(),
        binding: LoginBinding(),
        transition: Transition.fadeIn,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Session Expired',
          'Please sign in again to continue.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.lock_outline, color: Colors.white),
        );
        _isExpiring = false; // reset so future logins can expire again
      });
    });
  }
}
