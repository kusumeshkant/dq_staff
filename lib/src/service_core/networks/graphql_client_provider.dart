import 'package:firebase_auth/firebase_auth.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../constants/app_config.dart';

class GraphQLClientProvider {
  static GraphQLClient? _client;

  static GraphQLClient get client {
    _client ??= _build(token: null);
    return _client!;
  }

  static Future<void> reinitWithToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    _client = _build(token: token);
  }

  static void reset() => _client = null;

  static GraphQLClient _build({String? token}) {
    final httpLink = HttpLink(AppConfig.graphqlEndpoint);
    Link link = httpLink;

    if (token != null) {
      final authLink = AuthLink(getToken: () async => 'Bearer $token');
      link = authLink.concat(httpLink);
    }

    return GraphQLClient(
      link: link,
      cache: GraphQLCache(),
    );
  }
}
