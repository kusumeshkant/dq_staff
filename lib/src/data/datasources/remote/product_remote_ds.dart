import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../service_core/networks/graphql_client_provider.dart';

class ProductRemoteDs {
  GraphQLClient get _client => GraphQLClientProvider.client;

  void _logRequest(String method, [Map<String, dynamic>? variables]) {
    debugPrint('╔══ [StaffProduct] $method ══');
    if (variables != null && variables.isNotEmpty) {
      debugPrint('║  vars: $variables');
    }
  }

  void _logSuccess(String method, dynamic data) {
    debugPrint('╚══ [StaffProduct] $method ✓  $data');
  }

  void _logError(String method, OperationException exception) {
    debugPrint('╚══ [StaffProduct] $method ✗');
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

  static const _storeProductsQuery = r'''
    query StoreProducts($storeId: ID!) {
      storeProducts(storeId: $storeId) {
        id storeId barcode sku name description price stock
      }
    }
  ''';

  static const _createProductMutation = r'''
    mutation CreateProduct(
      $storeId: ID!, $barcode: String!, $sku: String,
      $name: String!, $description: String, $price: Float!, $stock: Int!
    ) {
      createProduct(
        storeId: $storeId, barcode: $barcode, sku: $sku,
        name: $name, description: $description, price: $price, stock: $stock
      ) {
        id storeId barcode sku name description price stock
      }
    }
  ''';

  static const _updateProductMutation = r'''
    mutation UpdateProduct(
      $id: ID!, $sku: String, $name: String!,
      $description: String, $price: Float!, $stock: Int!
    ) {
      updateProduct(
        id: $id, sku: $sku, name: $name,
        description: $description, price: $price, stock: $stock
      ) {
        id storeId barcode sku name description price stock
      }
    }
  ''';

  static const _deleteProductMutation = r'''
    mutation DeleteProduct($id: ID!) {
      deleteProduct(id: $id)
    }
  ''';

  Future<List<Map<String, dynamic>>> getStoreProducts(String storeId) async {
    _logRequest('getStoreProducts', {'storeId': storeId});
    final result = await _client.query(
      QueryOptions(
        document: gql(_storeProductsQuery),
        variables: {'storeId': storeId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    _check('getStoreProducts', result);
    final list = (result.data!['storeProducts'] as List).cast<Map<String, dynamic>>();
    _logSuccess('getStoreProducts', '${list.length} products');
    return list;
  }

  Future<Map<String, dynamic>> createProduct({
    required String storeId,
    required String barcode,
    String? sku,
    required String name,
    String? description,
    required double price,
    required int stock,
  }) async {
    final vars = {
      'storeId': storeId,
      'barcode': barcode,
      if (sku != null) 'sku': sku,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'stock': stock,
    };
    _logRequest('createProduct', vars);
    final result = await _client.mutate(
      MutationOptions(document: gql(_createProductMutation), variables: vars),
    );
    _check('createProduct', result);
    final data = result.data!['createProduct'] as Map<String, dynamic>;
    _logSuccess('createProduct', data['id']);
    return data;
  }

  Future<Map<String, dynamic>> updateProduct(
    String id, {
    String? sku,
    required String name,
    String? description,
    required double price,
    required int stock,
  }) async {
    final vars = {
      'id': id,
      if (sku != null) 'sku': sku,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'stock': stock,
    };
    _logRequest('updateProduct', vars);
    final result = await _client.mutate(
      MutationOptions(document: gql(_updateProductMutation), variables: vars),
    );
    _check('updateProduct', result);
    final data = result.data!['updateProduct'] as Map<String, dynamic>;
    _logSuccess('updateProduct', data['id']);
    return data;
  }

  Future<bool> deleteProduct(String id) async {
    _logRequest('deleteProduct', {'id': id});
    final result = await _client.mutate(
      MutationOptions(
        document: gql(_deleteProductMutation),
        variables: {'id': id},
      ),
    );
    _check('deleteProduct', result);
    final ok = result.data!['deleteProduct'] as bool;
    _logSuccess('deleteProduct', ok);
    return ok;
  }
}
