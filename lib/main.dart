import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:dq_staff/core/observability/observability.dart';
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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';

void main() {
  // runZonedGuarded catches all uncaught async errors in the app's zone.
  runZonedGuarded(_bootstrap, (error, stack) {
    if (!kIsWeb && Get.isRegistered<CrashlyticsService>()) {
      Get.find<CrashlyticsService>().recordError(
        error, stack, category: CrashCategory.unknown, fatal: true,
      );
    }
    debugPrint('\n=== [DQ-Staff] UNCAUGHT ZONE ERROR ===\n$error\n$stack\n=====================================\n');
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Step 1: Firebase ────────────────────────────────────────────────────────
  debugPrint('[DQ-Staff] startup: Firebase.initializeApp...');
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final opts = Firebase.app().options;
    debugPrint('[DQ-Staff] startup: Firebase OK'
        ' project=${opts.projectId}'
        ' authDomain=${opts.authDomain}'
        ' appId=${opts.appId}');
    if (kIsWeb) {
      // ignore: avoid_print
      print('[DQ-Staff] window.origin=${Uri.base.origin}');
    }
  } catch (e, st) {
    debugPrint('[DQ-Staff] startup: Firebase FAILED: $e\n$st');
    rethrow; // fatal — app cannot function without Firebase
  }

  // ── Step 1b: Observability services ─────────────────────────────────────────
  // Must run immediately after Firebase so error handlers can record crashes.
  final crashlytics = Get.put(CrashlyticsService(), permanent: true);
  Get.put(AnalyticsService(), permanent: true);
  Get.put(PerformanceService(), permanent: true);
  Get.put(BreadcrumbService(), permanent: true);
  Get.put(ReleaseHealthService(), permanent: true);
  Get.put(FramePerformanceTracker(), permanent: true);
  Get.put(AnrDetector(), permanent: true);

  // Wire global error handlers to Crashlytics.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (!kIsWeb) crashlytics.recordFlutterError(details);
  };
  if (!kIsWeb) {
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack,
          category: CrashCategory.rendering, fatal: true);
      return true;
    };
  }

  // ── Step 2: Platform UI (non-web only) ──────────────────────────────────────
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  // ── Step 3: GetX services ───────────────────────────────────────────────────
  debugPrint('[DQ-Staff] startup: SessionManager...');
  final sessionManager = Get.put(SessionManager());
  debugPrint('[DQ-Staff] startup: SessionManager OK');

  debugPrint('[DQ-Staff] startup: NotificationService...');
  try {
    await Get.putAsync(() => NotificationService().init());
    debugPrint('[DQ-Staff] startup: NotificationService OK');
  } catch (e, st) {
    // Non-fatal: the app functions without push notifications.
    debugPrint('[DQ-Staff] startup: NotificationService FAILED (non-fatal): $e\n$st');
    // Ensure the service is registered so Get.find<NotificationService>() works.
    if (!Get.isRegistered<NotificationService>()) {
      Get.put(NotificationService());
    }
  }

  // ── Step 4: Initial page routing ────────────────────────────────────────────
  debugPrint('[DQ-Staff] startup: resolving start page...');
  final startConfig = await _resolveStartPage(sessionManager);
  debugPrint('[DQ-Staff] startup: start page = ${startConfig.page.runtimeType}');

  // ── Step 5: Launch ──────────────────────────────────────────────────────────
  debugPrint('[DQ-Staff] startup: runApp...');
  runApp(DQStaffApp(
    home: startConfig.page,
    binding: startConfig.binding,
  ));
  debugPrint('[DQ-Staff] startup: runApp done');
}

/// Cold-start routing.
///
/// Priority:
///   1. Live backend profile (if reachable)  → cache it and route
///   2. Cached profile (if network fails)    → route from cache
///   3. No cache + no network                → login (Firebase session kept)
Future<_StartConfig> _resolveStartPage(SessionManager session) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  debugPrint('[DQ-Staff] _resolveStartPage: firebaseUser=${firebaseUser?.uid ?? "null"}');

  if (firebaseUser == null) {
    await session.clearCache();
    return _StartConfig(page: const LoginPage(), binding: LoginBinding());
  }

  try {
    await GraphQLClientProvider.reinitWithToken();
    debugPrint('[DQ-Staff] _resolveStartPage: GraphQL client initialised');

    final user = await GetProfileUseCase(
      AuthRepositoryImpl(AuthRemoteDs()),
    ).execute();
    debugPrint('[DQ-Staff] _resolveStartPage: profile fetched id=${user.id} role=${user.role}');

    // Cache on every successful fetch so offline cold starts work.
    await session.cacheProfile(user);
    return _routeFrom(session, user);
  } catch (e) {
    debugPrint('[DQ-Staff] _resolveStartPage: backend error, trying cache: $e');
    // Network / auth error — fall back to cached profile so staff are not
    // kicked to login just because the backend was momentarily unreachable.
    final cached = await session.loadCachedProfile();
    if (cached != null) {
      debugPrint('[DQ-Staff] _resolveStartPage: routing from cache');
      return _routeFrom(session, cached);
    }
    // No cache — ask the user to sign in when online.
    // Do NOT call FirebaseAuth.signOut(): the Firebase session is valid.
    debugPrint('[DQ-Staff] _resolveStartPage: no cache, routing to login');
    return _StartConfig(page: const LoginPage(), binding: LoginBinding());
  }
}

/// Routes based on role and store assignment.
_StartConfig _routeFrom(SessionManager session, UserEntity user) {
  session.setUser(user);
  debugPrint('[DQ-Staff] _routeFrom: isStaff=${user.isStaff} isAdmin=${user.isAdmin} storeId=${user.storeId}');

  if (!user.isStaff && !user.isAdmin) {
    // Valid Firebase account but not a staff member — go to login.
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
      navigatorObservers: [AnalyticsNavigatorObserver()],
      home: home,
    );
  }
}
