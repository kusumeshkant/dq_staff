import 'package:dq_staff/src/service_core/networks/graphql_client_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class AuthRemoteDs {
  // Always use the current client so reinitWithToken() is picked up immediately
  GraphQLClient get _client => GraphQLClientProvider.client;

  AuthRemoteDs();

  static const _meQuery = r'''
    query Me {
      me {
        id
        name
        email
        phone
        role
        storeId
      }
    }
  ''';

  static const _updateFcmMutation = r'''
    mutation UpdateFcmToken($token: String!) {
      updateFcmToken(token: $token)
    }
  ''';

  static const _updateProfileMutation = r'''
    mutation UpdateProfile($name: String) {
      updateProfile(name: $name) { id name email phone role storeId }
    }
  ''';

  Future<void> loginWithEmail(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> registerWithEmail(String email, String password) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> updateProfileName(String name) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(_updateProfileMutation),
        variables: {'name': name},
      ),
    );
    if (result.hasException) throw Exception(result.exception.toString());
  }

  Future<Map<String, dynamic>> getProfile() async {
    final result = await client.query(
      QueryOptions(document: gql(_meQuery)),
    );
    if (result.hasException) throw Exception(result.exception.toString());
    return result.data!['me'] as Map<String, dynamic>;
  }

  Future<void> updateFcmToken(String token) async {
    await client.mutate(
      MutationOptions(
        document: gql(_updateFcmMutation),
        variables: {'token': token},
      ),
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
