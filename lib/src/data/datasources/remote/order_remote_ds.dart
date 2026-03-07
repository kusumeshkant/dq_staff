import 'package:dq_staff/src/service_core/networks/graphql_client_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class OrderRemoteDs {
  // Always use the current client so token refreshes are picked up
  GraphQLClient get _client => GraphQLClientProvider.client;

  OrderRemoteDs();

  // ── Logger helpers ────────────────────────────────────────────────────────

  void _logRequest(String method, [Map<String, dynamic>? variables]) {
    debugPrint('╔══ [StaffOrder] $method ══');
    if (variables != null && variables.isNotEmpty) {
      debugPrint('║  vars: $variables');
    }
  }

  void _logSuccess(String method, dynamic data) {
    debugPrint('╚══ [StaffOrder] $method ✓  $data');
  }

  void _logError(String method, OperationException exception) {
    debugPrint('╚══ [StaffOrder] $method ✗');
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

  static const _storeOrdersQuery = r'''
    query StoreOrders($storeId: ID!) {
      storeOrders(storeId: $storeId) {
        id
        storeName
        storeId
        storeCode
        total
        tax
        grandTotal
        status
        createdAt
        items { barcode name price quantity }
        staffActions { staffId staffName action timestamp note }
        flaggedIssue { reason note staffName timestamp }
      }
    }
  ''';

  static const _orderByIdQuery = r'''
    query OrderById($orderId: ID!) {
      orderById(orderId: $orderId) {
        id
        storeName
        storeId
        storeCode
        total
        tax
        grandTotal
        status
        createdAt
        items { barcode name price quantity }
        staffActions { staffId staffName action timestamp note }
        flaggedIssue { reason note staffName timestamp }
      }
    }
  ''';

  static const _updateStatusMutation = r'''
    mutation UpdateOrderStatus($orderId: ID!, $status: String!) {
      updateOrderStatus(orderId: $orderId, status: $status) {
        id
        status
        staffActions { staffId staffName action timestamp note }
        flaggedIssue { reason note staffName timestamp }
      }
    }
  ''';

  static const _flagIssueMutation = r'''
    mutation FlagOrderIssue($orderId: ID!, $reason: String!, $note: String) {
      flagOrderIssue(orderId: $orderId, reason: $reason, note: $note) {
        id
        status
        flaggedIssue { reason note staffName timestamp }
        staffActions { staffId staffName action timestamp note }
      }
    }
  ''';

  Future<List<Map<String, dynamic>>> getStoreOrders(String storeId) async {
    _logRequest('getStoreOrders [query: StoreOrders]', {'storeId': storeId});
    final result = await _client.query(
      QueryOptions(
        document: gql(_storeOrdersQuery),
        variables: {'storeId': storeId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    _check('getStoreOrders', result);
    final list = (result.data!['storeOrders'] as List).cast<Map<String, dynamic>>();
    _logSuccess('getStoreOrders', '${list.length} orders');
    return list;
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    _logRequest('getOrderById [query: OrderById]', {'orderId': orderId});
    final result = await _client.query(
      QueryOptions(
        document: gql(_orderByIdQuery),
        variables: {'orderId': orderId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    _check('getOrderById', result);
    final data = result.data!['orderById'] as Map<String, dynamic>?;
    _logSuccess('getOrderById', data?['id']);
    return data;
  }

  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    _logRequest('updateOrderStatus [mutation: UpdateOrderStatus]', {'orderId': orderId, 'status': status});
    final result = await _client.mutate(
      MutationOptions(
        document: gql(_updateStatusMutation),
        variables: {'orderId': orderId, 'status': status},
      ),
    );
    _check('updateOrderStatus', result);
    final data = result.data!['updateOrderStatus'] as Map<String, dynamic>;
    _logSuccess('updateOrderStatus', 'status → $status');
    return data;
  }

  Future<Map<String, dynamic>> flagOrderIssue(String orderId, String reason, String note) async {
    _logRequest('flagOrderIssue [mutation: FlagOrderIssue]', {'orderId': orderId, 'reason': reason, 'note': note});
    final result = await _client.mutate(
      MutationOptions(
        document: gql(_flagIssueMutation),
        variables: {'orderId': orderId, 'reason': reason, 'note': note},
      ),
    );
    _check('flagOrderIssue', result);
    final data = result.data!['flagOrderIssue'] as Map<String, dynamic>;
    _logSuccess('flagOrderIssue', 'reason: $reason');
    return data;
  }
}
