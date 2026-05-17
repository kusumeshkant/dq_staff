/// Generates per-request correlation IDs for distributed tracing.
///
/// Propagated as:
///   • x-correlation-id HTTP header on every network request
///   • Crashlytics custom key 'cid' on errors
///   • Analytics event parameter for cross-system correlation
///
/// Format: <13-hex epoch ms>-<4-hex monotonic sequence>
/// Example: 018e7b3c1a2f-001d
abstract final class CorrelationIdService {
  static int _seq = 0;

  /// Returns a new, time-ordered, process-unique correlation ID.
  static String generate() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    _seq = (_seq + 1) & 0xFFFF;
    return '${ms.toRadixString(16)}-${_seq.toRadixString(16).padLeft(4, '0')}';
  }
}
