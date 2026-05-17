import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../constants/app_config.dart';
import '../auth/session_manager.dart';
import 'graphql_observability_link.dart';

class GraphQLClientProvider {
  static GraphQLClient? _client;

  static GraphQLClient get client {
    _client ??= _build();
    return _client!;
  }

  static Future<void> reinitWithToken() async {
    _client = _build();
  }

  static void reset() => _client = null;

  static GraphQLClient _build() {
    final httpLink = HttpLink(AppConfig.graphqlEndpoint);

    // Fetches a fresh Firebase ID token on every request.
    final authLink = AuthLink(
      getToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
        final token = await user.getIdToken();
        return token != null ? 'Bearer $token' : null;
      },
    );

    // Catches UNAUTHENTICATED errors, force-refreshes the Firebase token,
    // and retries the original request once before expiring the session.
    final errorLink = ErrorLink(
      onGraphQLError: (request, forward, response) async* {
        final isUnauthenticated = response.errors
                ?.any((e) => e.extensions?['code'] == 'UNAUTHENTICATED') ??
            false;

        if (!isUnauthenticated) {
          yield response;
          return;
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          await _expireSession();
          return;
        }

        try {
          await user.getIdToken(true); // force server-side refresh
        } catch (_) {
          await _expireSession();
          return;
        }

        // Retry once — AuthLink will use the fresh token
        await for (final result in forward(request)) {
          if (result.errors
                  ?.any((e) => e.extensions?['code'] == 'UNAUTHENTICATED') ??
              false) {
            await _expireSession();
            return;
          }
          yield result;
        }
      },
    );

    final link = GraphQLObservabilityLink()
        .concat(GraphQLLoggingLink())
        .concat(errorLink.concat(authLink.concat(httpLink)));

    return GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  // A minimal client with no ErrorLink — used during the login flow so that
  // an UNAUTHENTICATED backend response does not trigger _expireSession()
  // while the user is actively trying to sign in.
  static GraphQLClient buildLoginClient() {
    final httpLink = HttpLink(AppConfig.graphqlEndpoint);
    final authLink = AuthLink(
      getToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
        final token = await user.getIdToken();
        return token != null ? 'Bearer $token' : null;
      },
    );
    return GraphQLClient(
      link: authLink.concat(httpLink),
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  static Future<void> _expireSession() async {
    _client = null;
    try {
      await Get.find<SessionManager>().expireSession();
    } catch (_) {}
  }
}
