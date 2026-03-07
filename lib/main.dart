import 'package:dq_staff/src/data/datasources/remote/auth_remote_ds.dart';
import 'package:dq_staff/src/data/repo_impl/auth_repository_impl.dart';
import 'package:dq_staff/src/domain/usecase/get_profile_usecase.dart';
import 'package:dq_staff/src/presentation/auth/login/login_binding.dart';
import 'package:dq_staff/src/presentation/auth/login/login_page.dart';
import 'package:dq_staff/src/presentation/orders/orders_binding.dart';
import 'package:dq_staff/src/presentation/orders/orders_page.dart';
import 'package:dq_staff/src/service_core/auth/session_manager.dart';
import 'package:dq_staff/src/service_core/networks/graphql_client_provider.dart';
import 'package:dq_staff/src/service_core/notifications/notification_service.dart';
import 'package:dq_staff/src/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final sessionManager = Get.put(SessionManager());
  await Get.putAsync(() => NotificationService().init());

  final startConfig = await _resolveStartPage(sessionManager);

  runApp(DQStaffApp(
    home: startConfig.page,
    binding: startConfig.binding,
  ));
}

Future<_StartConfig> _resolveStartPage(SessionManager session) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;

  if (firebaseUser == null) {
    return _StartConfig(page: const LoginPage(), binding: LoginBinding());
  }

  try {
    await GraphQLClientProvider.reinitWithToken();

    final user = await GetProfileUseCase(
      AuthRepositoryImpl(AuthRemoteDs()),
    ).execute();

    if (!user.isStaff && !user.isAdmin) {
      await FirebaseAuth.instance.signOut();
      GraphQLClientProvider.reset();
      return _StartConfig(page: const LoginPage(), binding: LoginBinding());
    }

    if (user.storeId == null) {
      await FirebaseAuth.instance.signOut();
      GraphQLClientProvider.reset();
      return _StartConfig(page: const LoginPage(), binding: LoginBinding());
    }

    session.setUser(user);

    return _StartConfig(
      page: const OrdersPage(),
      binding: OrdersBinding(),
    );
  } catch (_) {
    return _StartConfig(page: const LoginPage(), binding: LoginBinding());
  }
}

class _StartConfig {
  final Widget page;
  final Bindings binding;
  _StartConfig({required this.page, required this.binding});
}

class DQStaffApp extends StatelessWidget {
  final Widget home;
  final Bindings binding;

  const DQStaffApp({super.key, required this.home, required this.binding});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DQ Staff',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialBinding: binding,
      home: home,
    );
  }
}
