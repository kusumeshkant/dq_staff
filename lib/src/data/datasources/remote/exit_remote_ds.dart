import 'package:dq_staff/src/service_core/networks/graphql_client_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../domain/entity/exit_entity.dart';
import '../../../domain/repo/exit_api.dart';

class ExitRemoteDs implements ExitApi {
  // Always use the current client so token refreshes are picked up
  GraphQLClient get _client => GraphQLClientProvider.client;

  static const _orderFields = '''
    id storeName grandTotal createdAt ageMinutes hasOpenFlag
    flaggedIssue { reason note staffName timestamp }
    items { id barcode name color size price quantity entryMethod }
  ''';

  static const _resultFields = 'outcome message exitedAt exitedByName order { $_orderFields }';

  static const _verify = '''
    query VerifyExit(\$code: String!) { verifyExit(code: \$code) { $_resultFields } }
  ''';

  static const _complete = '''
    mutation CompleteExit(\$code: String!, \$lines: [ID!]!, \$requestId: String!) {
      completeExit(code: \$code, verifiedLineIds: \$lines, requestId: \$requestId) { $_resultFields }
    }
  ''';

  static const _completeManual = '''
    mutation CompleteManualExit(\$orderId: ID!, \$reason: String!, \$lines: [ID!]!, \$requestId: String!) {
      completeManualExit(orderId: \$orderId, reason: \$reason, verifiedLineIds: \$lines, requestId: \$requestId) { $_resultFields }
    }
  ''';

  static const _openPaid = '''
    query OpenPaidOrders { openPaidOrders { $_orderFields } }
  ''';

  static const _clearFlag = r'''
    mutation ClearOrderFlag($orderId: ID!, $note: String!) {
      clearOrderFlag(orderId: $orderId, note: $note) { id hasOpenFlag }
    }
  ''';

  Map<String, dynamic> _data(String op, QueryResult r) {
    if (r.hasException) {
      final e = r.exception!;
      debugPrint('[Exit] $op failed: ${e.graphqlErrors.map((g) => g.message).join(', ')} ${e.linkException ?? ''}');
      if (e.graphqlErrors.isNotEmpty) throw Exception(e.graphqlErrors.map((g) => g.message).join(', '));
      throw Exception('Network error — check your connection');
    }
    return r.data!;
  }

  Future<Map<String, dynamic>> _mutate(String op, String doc, Map<String, dynamic> vars) async {
    final r = await _client.mutate(MutationOptions(document: gql(doc), variables: vars, fetchPolicy: FetchPolicy.noCache));
    return _data(op, r);
  }

  @override
  Future<ExitResult> verifyExit(String code) async {
    final r = await _client.query(QueryOptions(
      document: gql(_verify),
      variables: {'code': code},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    return ExitResult.fromJson((_data('verifyExit', r)['verifyExit'] as Map).cast<String, dynamic>());
  }

  @override
  Future<ExitResult> completeExit({
    required String code,
    required List<String> verifiedLineIds,
    required String requestId,
  }) async {
    final d = await _mutate('completeExit', _complete, {'code': code, 'lines': verifiedLineIds, 'requestId': requestId});
    return ExitResult.fromJson((d['completeExit'] as Map).cast<String, dynamic>());
  }

  @override
  Future<ExitResult> completeManualExit({
    required String orderId,
    required String reason,
    required List<String> verifiedLineIds,
    required String requestId,
  }) async {
    final d = await _mutate('completeManualExit', _completeManual,
        {'orderId': orderId, 'reason': reason, 'lines': verifiedLineIds, 'requestId': requestId});
    return ExitResult.fromJson((d['completeManualExit'] as Map).cast<String, dynamic>());
  }

  @override
  Future<List<ExitOrder>> openPaidOrders() async {
    final r = await _client.query(QueryOptions(document: gql(_openPaid), fetchPolicy: FetchPolicy.networkOnly));
    return (_data('openPaidOrders', r)['openPaidOrders'] as List)
        .map((o) => ExitOrder.fromJson((o as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<void> clearOrderFlag({required String orderId, required String note}) async {
    await _mutate('clearOrderFlag', _clearFlag, {'orderId': orderId, 'note': note});
  }
}
