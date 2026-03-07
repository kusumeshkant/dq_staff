import 'package:dq_staff/src/service_core/networks/graphql_client_provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class OrderRemoteDs {
  // Always use the current client so token refreshes are picked up
  GraphQLClient get _client => GraphQLClientProvider.client;

  OrderRemoteDs();

  static const _storeOrdersQuery = r'''
    query StoreOrders($storeId: ID!) {
      storeOrders(storeId: $storeId) {
        id
        storeName
        storeId
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
    final result = await _client.query(
      QueryOptions(
        document: gql(_storeOrdersQuery),
        variables: {'storeId': storeId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw Exception(result.exception.toString());
    final list = result.data!['storeOrders'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(_orderByIdQuery),
        variables: {'orderId': orderId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw Exception(result.exception.toString());
    return result.data!['orderById'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      String orderId, String status) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(_updateStatusMutation),
        variables: {'orderId': orderId, 'status': status},
      ),
    );
    if (result.hasException) throw Exception(result.exception.toString());
    return result.data!['updateOrderStatus'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> flagOrderIssue(
      String orderId, String reason, String note) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(_flagIssueMutation),
        variables: {'orderId': orderId, 'reason': reason, 'note': note},
      ),
    );
    if (result.hasException) throw Exception(result.exception.toString());
    return result.data!['flagOrderIssue'] as Map<String, dynamic>;
  }
}
