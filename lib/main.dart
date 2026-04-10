import 'package:dq_staff/src/data/datasources/remote/auth_remote_ds.dart';
import 'package:dq_staff/src/data/repo_impl/auth_repository_impl.dart';
import 'package:dq_staff/src/domain/entity/user_entity.dart';
import 'package:dq_staff/src/domain/usecase/get_profile_usecase.dart';
import 'package:dq_staff/src/presentation/auth/login/login_binding.dart';
import 'package:dq_staff/src/presentation/auth/login/login_page.dart';
import 'package:dq_staff/src/presentation/home/home_binding.dart';
import 'package:dq_staff/src/presentation/home/home_page.dart';
import 'package:dq_staff/src/presentation/invite/invite_code_binding.dart';
import 'package:dq_staff/src/presentation/invite/invite_code_page.dart';
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

/// Cold-start routing.
///
/// Priority:
///   1. Live backend profile (if reachable)  → cache it and route
///   2. Cached profile (if network fails)    → route from cache
///   3. No cache + no network                → login (Firebase session kept)
Future<_StartConfig> _resolveStartPage(SessionManager session) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;

  if (firebaseUser == null) {
    await session.clearCache();
    return _StartConfig(page: const LoginPage(), binding: LoginBinding());
  }

  try {
    await GraphQLClientProvider.reinitWithToken();

    final user = await GetProfileUseCase(
      AuthRepositoryImpl(AuthRemoteDs()),
    ).execute();

    // Cache on every successful fetch so offline cold starts work.
    await session.cacheProfile(user);
    return _routeFrom(session, user);
  } catch (_) {
    // Network / auth error — fall back to cached profile so staff are not
    // kicked to login just because the backend was momentarily unreachable.
    final cached = await session.loadCachedProfile();
    if (cached != null) {
      return _routeFrom(session, cached);
    }
    // No cache — ask the user to sign in when online.
    // Do NOT call FirebaseAuth.signOut(): the Firebase session is valid.
    return _StartConfig(page: const LoginPage(), binding: LoginBinding());
  }
}

/// Routes based on role and store assignment.
_StartConfig _routeFrom(SessionManager session, UserEntity user) {
  session.setUser(user);

  if (!user.isStaff && !user.isAdmin) {
    // Valid Firebase account but not a staff member — go to login.
    // Do not sign out; they may be a customer who downloaded the wrong app.
    return _StartConfig(page: const LoginPage(), binding: LoginBinding());
  }

  if (user.storeId == null || user.storeId!.isEmpty) {
    // Staff account exists but no store assigned yet.
    return _StartConfig(
      page: const InviteCodePage(),
      binding: InviteCodeBinding(),
    );
  }

  // Fetch store details best-effort (non-blocking — staff card shows cached)
  _fetchStoreAsync(session, user.storeId!);

  return _StartConfig(page: const HomePage(), binding: HomeBinding());
}

/// Fire-and-forget store fetch so it does not block the cold-start route.
void _fetchStoreAsync(SessionManager session, String storeId) {
  AuthRepositoryImpl(AuthRemoteDs()).getStoreById(storeId).then((store) {
    if (store != null) session.setStore(store);
  }).catchError((_) {});
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
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      initialBinding: binding,
      home: home,
    );
  }
}
