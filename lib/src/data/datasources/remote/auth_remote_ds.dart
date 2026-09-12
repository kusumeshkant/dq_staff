import 'package:dq_staff/src/service_core/networks/graphql_client_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../service_core/networks/app_access_exception.dart';

class AuthRemoteDs {
  // Always use the current client so reinitWithToken() is picked up immediately
  GraphQLClient get _client => GraphQLClientProvider.client;

  AuthRemoteDs();

  // ── Logger helpers ────────────────────────────────────────────────────────

  void _logRequest(String method, [Map<String, dynamic>? variables]) {
    debugPrint('╔══ [StaffAuth] $method ══');
    if (variables != null && variables.isNotEmpty) {
      debugPrint('║  vars: $variables');
    }
  }

  void _logSuccess(String method, dynamic data) {
    debugPrint('╚══ [StaffAuth] $method ✓  $data');
  }

  void _logError(String method, OperationException exception) {
    debugPrint('╚══ [StaffAuth] $method ✗');
    for (final e in exception.graphqlErrors) {
      debugPrint('   GraphQL error: ${e.message}');
    }
    if (exception.linkException != null) {
      debugPrint('   Network error: ${exception.linkException}');
    }
  }

  String _errorMessage(OperationException exception) {
    if (exception.graphqlErrors.isNotEmpty) {
      return exception.graphqlErrors.map((e) => e.message).join(', ');
    }
    if (exception.linkException != null) return 'Network error — check your connection';
    return exception.toString();
  }

  void _check(String method, QueryResult result) {
    if (result.hasException) {
      _logError(method, result.exception!);
      throw Exception(_errorMessage(result.exception!));
    }
  }

  static const _meQuery = r'''
    query Me {
      me {
        id
        name
        email
        phone
        role
        roles
        storeId
      }
    }
  ''';

  static const _validateAppAccessQuery = r'''
    query ValidateAppAccess($appId: String!) {
      validateAppAccess(appId: $appId) {
        id
        name
        email
        phone
        role
        roles
        storeId
      }
    }
  ''';

  static const _storeQuery = r'''
    query Store($id: ID!) {
      store(id: $id) {
        id name address storeCode
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

  /// Invite-gated staff signup.
  ///
  /// Replaces the previous registerAsCustomer call, which created the account
  /// with the customer role and so produced an account that
  /// validateAppAccess(STAFF) then refused — no invited staff member could get
  /// into this app at all.
  static const _registerStaffWithInviteMutation = r'''
    mutation RegisterStaffWithInvite($token: String!, $name: String) {
      registerStaffWithInvite(token: $token, name: $name) {
        id name email role roles storeId
      }
    }
  ''';

  Future<void> loginWithEmail(String email, String password) async {
    _logRequest('loginWithEmail [Firebase]', {'email': email});
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      _logSuccess('loginWithEmail [Firebase]', 'signed in');
    } catch (e) {
      debugPrint('╚══ [StaffAuth] loginWithEmail ✗  $e');
      rethrow;
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    _logRequest('registerWithEmail [Firebase]', {'email': email});
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      _logSuccess('registerWithEmail [Firebase]', 'account created');
    } catch (e) {
      debugPrint('╚══ [StaffAuth] registerWithEmail ✗  $e');
      rethrow;
    }
  }

  /// Creates the backend staff record from an admin-issued invite code.
  ///
  /// The name is set by the same mutation, so there is no follow-up
  /// updateProfile call — one round trip, and no window in which the account
  /// exists without its name.
  Future<void> registerInBackend(String name, String inviteCode) async {
    _logRequest('registerInBackend [registerStaffWithInvite]',
        {'name': name, 'token': inviteCode});
    final result = await _client.mutate(
      MutationOptions(
        document: gql(_registerStaffWithInviteMutation),
        variables: {'token': inviteCode, 'name': name},
      ),
    );
    if (result.hasException) {
      _logError('registerInBackend', result.exception!);
      // Pass the backend message through verbatim — invite errors ("expired",
      // "issued to a different email") are already written for the user, and a
      // categorised placeholder would hide the one thing they need to know.
      if (result.exception!.graphqlErrors.isNotEmpty) {
        throw Exception(result.exception!.graphqlErrors.first.message);
      }
      throw Exception(_errorMessage(result.exception!));
    }
    _logSuccess('registerInBackend', name);
  }

  Future<void> updateProfileName(String name) async {
    _logRequest('updateProfileName [mutation: UpdateProfile]', {'name': name});
    final result = await _client.mutate(
      MutationOptions(document: gql(_updateProfileMutation), variables: {'name': name}),
    );
    _check('updateProfileName', result);
    _logSuccess('updateProfileName', result.data!['updateProfile']);
  }

  Future<Map<String, dynamic>> getProfile() async {
    _logRequest('getProfile [query: Me]');
    final result = await _client.query(QueryOptions(document: gql(_meQuery)));
    _check('getProfile', result);
    final data = result.data!['me'] as Map<String, dynamic>;
    _logSuccess('getProfile', data);
    return data;
  }

  Future<Map<String, dynamic>> validateAppAccess() async {
    _logRequest('validateAppAccess [query: ValidateAppAccess]', {'appId': 'STAFF'});
    final result = await _client.query(
      QueryOptions(
        document: gql(_validateAppAccessQuery),
        variables: const {'appId': 'STAFF'},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      _logError('validateAppAccess', result.exception!);
      // Carry the server's extensions through, not just the prose. A role
      // rejection and an unreachable backend need different copy, and the
      // message text alone is not a reliable way to tell them apart.
      if (result.exception!.graphqlErrors.isNotEmpty) {
        final err = result.exception!.graphqlErrors.first;
        throw AppAccessException(
          err.message,
          code: err.extensions?['code'] as String?,
          hint: err.extensions?['hint'] as String?,
        );
      }
      throw Exception(_errorMessage(result.exception!));
    }
    final data = result.data!['validateAppAccess'] as Map<String, dynamic>;
    _logSuccess('validateAppAccess', data);
    return data;
  }

  Future<void> updateFcmToken(String token) async {
    _logRequest('updateFcmToken [mutation: UpdateFcmToken]', {'token': '${token.substring(0, 10)}...'});
    final result = await _client.mutate(
      MutationOptions(document: gql(_updateFcmMutation), variables: {'token': token}),
    );
    if (result.hasException) {
      _logError('updateFcmToken', result.exception!);
    } else {
      _logSuccess('updateFcmToken', true);
    }
  }

  Future<Map<String, dynamic>?> getStoreById(String id) async {
    _logRequest('getStoreById [query: Store]', {'id': id});
    final result = await _client.query(
      QueryOptions(
        document: gql(_storeQuery),
        variables: {'id': id},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    _check('getStoreById', result);
    final data = result.data!['store'] as Map<String, dynamic>?;
    _logSuccess('getStoreById', data?['name']);
    return data;
  }

  Future<void> signOut() async {
    _logRequest('signOut [Firebase]');
    await FirebaseAuth.instance.signOut();
    _logSuccess('signOut', 'signed out');
  }
}
