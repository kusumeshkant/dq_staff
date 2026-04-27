import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../service_core/networks/graphql_client_provider.dart';

class PermissionRemoteDs {
  GraphQLClient get _client => GraphQLClientProvider.client;

  static const _myPermissionsQuery = r'''
    query MyPermissions($storeId: ID!) {
      myPermissions(storeId: $storeId) {
        staffId storeId
        canDiscount maxDiscountPercent
        canEditProductInfo canAddProduct canDeleteProduct
        canBulkUploadProducts
        isActive grantedAt
      }
    }
  ''';

  static const _myRequestsQuery = r'''
    query MyPermissionRequests($storeId: ID!) {
      myPermissionRequests(storeId: $storeId) {
        id requestType status reason
        requestedMaxDiscountPercent requestedProductPerms
        grantedMaxDiscountPercent grantedProductPerms
        reviewNote createdAt reviewedAt
      }
    }
  ''';

  static const _requestPermissionMutation = r'''
    mutation RequestPermission(
      $storeId: ID!
      $requestType: String!
      $reason: String!
      $requestedMaxDiscountPercent: Float
      $requestedProductPerms: [String!]
    ) {
      requestPermission(
        storeId: $storeId
        requestType: $requestType
        reason: $reason
        requestedMaxDiscountPercent: $requestedMaxDiscountPercent
        requestedProductPerms: $requestedProductPerms
      ) {
        id status createdAt
      }
    }
  ''';

  static const _generateDiscountCodeMutation = r'''
    mutation GenerateDiscountCode($storeId: ID!, $discountPercent: Float!) {
      generateDiscountCode(storeId: $storeId, discountPercent: $discountPercent) {
        code discountPercent expiresAt
      }
    }
  ''';

  String _err(OperationException e) {
    if (e.graphqlErrors.isNotEmpty) return e.graphqlErrors.map((e) => e.message).join(', ');
    if (e.linkException != null) return 'Network error — check your connection';
    return e.toString();
  }

  void _check(QueryResult r) {
    if (r.hasException) throw Exception(_err(r.exception!));
  }

  Future<Map<String, dynamic>?> getMyPermissions(String storeId) async {
    final result = await _client.query(QueryOptions(
      document: gql(_myPermissionsQuery),
      variables: {'storeId': storeId},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    _check(result);
    return result.data?['myPermissions'] as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> getMyRequests(String storeId) async {
    final result = await _client.query(QueryOptions(
      document: gql(_myRequestsQuery),
      variables: {'storeId': storeId},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    _check(result);
    return (result.data!['myPermissionRequests'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> requestPermission({
    required String storeId,
    required String requestType,
    required String reason,
    double? requestedMaxDiscountPercent,
    List<String>? requestedProductPerms,
  }) async {
    final result = await _client.mutate(MutationOptions(
      document: gql(_requestPermissionMutation),
      variables: {
        'storeId': storeId,
        'requestType': requestType,
        'reason': reason,
        if (requestedMaxDiscountPercent != null)
          'requestedMaxDiscountPercent': requestedMaxDiscountPercent,
        if (requestedProductPerms != null)
          'requestedProductPerms': requestedProductPerms,
      },
    ));
    if (result.hasException) throw Exception(_err(result.exception!));
    return result.data!['requestPermission'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateDiscountCode({
    required String storeId,
    required double discountPercent,
  }) async {
    final result = await _client.mutate(MutationOptions(
      document: gql(_generateDiscountCodeMutation),
      variables: {'storeId': storeId, 'discountPercent': discountPercent},
    ));
    if (result.hasException) throw Exception(_err(result.exception!));
    return result.data!['generateDiscountCode'] as Map<String, dynamic>;
  }
}
