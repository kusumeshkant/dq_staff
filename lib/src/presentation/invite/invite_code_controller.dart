import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../data/model/user_model.dart';
import '../../domain/repo/auth_repository.dart';
import '../../service_core/auth/session_manager.dart';
import '../../service_core/networks/graphql_client_provider.dart';
import '../../service_core/notifications/notification_service.dart';
import '../home/home_binding.dart';
import '../home/home_page.dart';

class InviteCodeController extends GetxController {
  final AuthRepository authRepo;
  InviteCodeController({required this.authRepo});

  final codeCtrl     = TextEditingController();
  final isLoading    = false.obs;
  final errorMessage = ''.obs;

  static const _acceptInviteMutation = r'''
    mutation AcceptInvite($token: String!) {
      acceptInvite(token: $token) {
        id name email phone role storeId
      }
    }
  ''';

  Future<void> submitCode() async {
    final token = codeCtrl.text.trim().toUpperCase();
    if (token.isEmpty) {
      errorMessage.value = 'Please enter your invite code.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await GraphQLClientProvider.client.mutate(
        MutationOptions(
          document: gql(_acceptInviteMutation),
          variables: {'token': token},
        ),
      );

      if (result.hasException) {
        final msg = result.exception?.graphqlErrors.firstOrNull?.message
            ?? 'Invalid or expired invite code.';
        throw Exception(msg);
      }

      final data = result.data?['acceptInvite'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Unexpected error. Please try again.');

      final user = UserModel.fromJson(data);
      final session = Get.find<SessionManager>();
      session.setUser(user);

      // Fetch store info
      if (user.storeId != null) {
        try {
          final store = await authRepo.getStoreById(user.storeId!);
          if (store != null) session.setStore(store);
        } catch (_) {}
      }

      // Register FCM token
      final fcmToken = await Get.find<NotificationService>().getToken();
      if (fcmToken != null) await authRepo.updateFcmToken(fcmToken);

      Get.offAll(() => const HomePage(), binding: HomeBinding());
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    GraphQLClientProvider.reset();
    try { await authRepo.signOut(); } catch (_) {}
    await Get.find<SessionManager>().expireSession();
  }

  @override
  void onClose() {
    codeCtrl.dispose();
    super.onClose();
  }
}
