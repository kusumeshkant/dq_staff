import 'package:graphql_flutter/graphql_flutter.dart';
import '../networks/graphql_client_provider.dart';
import 'subscription_model.dart';

/// Lightweight subscription fetch for dq_app (customer app).
/// Customers do not have admin access — only fetches store status, not feature map.
class SubscriptionRemoteDs {
  GraphQLClient get _client => GraphQLClientProvider.client;

  static const _storeSubscriptionQuery = r'''
    query StoreSubscriptionStatus($storeId: ID!) {
      storeSubscription(storeId: $storeId) {
        status
        trialEndsAt
        gracePeriodEndsAt
        currentPeriodEnd
        plan {
          name
          displayName
        }
      }
    }
  ''';

  Future<SubscriptionInfo> loadSubscription(String storeId) async {
    final result = await _client.query(QueryOptions(
      document: gql(_storeSubscriptionQuery),
      variables: {'storeId': storeId},
      fetchPolicy: FetchPolicy.networkOnly,
    ));

    if (result.hasException) {
      throw Exception('Failed to load subscription: ${result.exception}');
    }

    final subJson = result.data?['storeSubscription'] as Map<String, dynamic>?;
    if (subJson == null) {
      return const SubscriptionInfo(
        status: 'none',
        planName: '',
        planDisplayName: '',
        features: FeatureAccessMap.locked(),
      );
    }

    return SubscriptionInfo(
      status:            subJson['status'] as String? ?? 'none',
      planName:          subJson['plan']?['name'] as String? ?? '',
      planDisplayName:   subJson['plan']?['displayName'] as String? ?? '',
      features:          const FeatureAccessMap.locked(), // customers don't need feature map
      trialEndsAt:       _parseDate(subJson['trialEndsAt']),
      gracePeriodEndsAt: _parseDate(subJson['gracePeriodEndsAt']),
      currentPeriodEnd:  _parseDate(subJson['currentPeriodEnd']),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
