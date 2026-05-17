import 'package:get/get.dart' hide Response;
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/observability/observability.dart';

/// Wraps every GraphQL operation with:
///   - CrashlyticsService breadcrumbs (operation start/end)
///   - PerformanceService trace (latency per operation)
///   - CrashlyticsService error recording (GQL errors + network errors)
///
/// Place this as the first link in the chain so it measures total wall time
/// including auth token fetch and retry logic.
class GraphQLObservabilityLink extends Link {
  @override
  Stream<Response> request(Request req, [NextLink? forward]) async* {
    final operation = req.operation.operationName ?? 'unknown';
    final traceName = 'gql_${operation.toLowerCase()}';
    final correlationId = CorrelationIdService.generate();

    final requestWithCid = req.updateContextEntry<HttpLinkHeaders>(
      (existing) => HttpLinkHeaders(
        headers: <String, String>{
          ...?existing?.headers,
          'x-correlation-id': correlationId,
        },
      ),
    );

    _log('gql_start: $operation cid=$correlationId');

    PerfTrace? trace;
    if (Get.isRegistered<PerformanceService>()) {
      trace = await Get.find<PerformanceService>().startTrace(traceName);
    }

    try {
      await for (final response in forward!(requestWithCid)) {
        if (response.errors != null && response.errors!.isNotEmpty) {
          final msgs = response.errors!.map((e) => e.message).join('; ');
          _log('gql_error: $operation — $msgs');
          await _recordError(
            'GraphQL error [$operation]: $msgs',
            null,
            category: CrashCategory.api,
          );
          await trace?.putAttribute('error', 'true');
        } else {
          _log('gql_ok: $operation');
        }
        yield response;
      }
      await trace?.stop();
    } catch (e, st) {
      await trace?.putAttribute('error', 'true');
      await trace?.stop();
      _log('gql_network_error: $operation — $e');
      await _recordError(e, st,
          category: CrashCategory.network, reason: 'gql_network: $operation');
      rethrow;
    }
  }

  void _log(String message) {
    if (!Get.isRegistered<CrashlyticsService>()) return;
    Get.find<CrashlyticsService>().log(message);
  }

  Future<void> _recordError(
    dynamic exception,
    StackTrace? stack, {
    required CrashCategory category,
    String? reason,
  }) async {
    if (!Get.isRegistered<CrashlyticsService>()) return;
    await Get.find<CrashlyticsService>().recordError(
      exception, stack,
      category: category,
      reason: reason,
    );
  }
}

/// Logs every GraphQL operation name and errors to the debug console via
/// [AppLogger]. No-ops in prod (AppLogger suppresses verbose logs in prod).
class GraphQLLoggingLink extends Link {
  @override
  Stream<Response> request(Request req, [NextLink? forward]) async* {
    final operation = req.operation.operationName ?? 'unknown';
    final vars = req.variables.isNotEmpty ? req.variables : null;
    AppLogger.request(operation, variables: vars);

    try {
      await for (final response in forward!(req)) {
        if (response.errors != null && response.errors!.isNotEmpty) {
          AppLogger.graphqlError(operation, response.errors!);
        } else {
          AppLogger.response(operation, response.data);
        }
        yield response;
      }
    } catch (e, st) {
      AppLogger.networkError(operation, e);
      AppLogger.error(operation, e, st);
      rethrow;
    }
  }
}
