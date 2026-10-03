/// Exit flow (backend: verifyExit / completeExit / completeManualExit).
enum ExitOutcome {
  okToExit,
  exited,
  alreadyExited,
  cancelled,
  notPaid,
  ownOrder,
  flagged,
  linesNotVerified,
  notFound;

  static ExitOutcome parse(String? raw) => switch (raw) {
        'OK_TO_EXIT' => okToExit,
        'EXITED' => exited,
        'ALREADY_EXITED' => alreadyExited,
        'CANCELLED' => cancelled,
        'NOT_PAID' => notPaid,
        'OWN_ORDER' => ownOrder,
        'FLAGGED' => flagged,
        'LINES_NOT_VERIFIED' => linesNotVerified,
        _ => notFound,
      };
}

/// One paid line the staff member checks against the bag.
class ExitLine {
  final String id;
  final String barcode;
  final String name;
  final String? color;
  final String? size;
  final double price;
  final int quantity;

  /// The customer typed the barcode instead of scanning it: check it carefully.
  final bool isManual;

  const ExitLine({
    required this.id,
    required this.barcode,
    required this.name,
    this.color,
    this.size,
    required this.price,
    required this.quantity,
    this.isManual = false,
  });

  String? get variant {
    final parts = [
      if (color != null && color!.isNotEmpty) color!,
      if (size != null && size!.isNotEmpty) 'Size $size',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  factory ExitLine.fromJson(Map<String, dynamic> j) => ExitLine(
        id: (j['id'] ?? '') as String,
        barcode: j['barcode'] as String,
        name: j['name'] as String,
        color: j['color'] as String?,
        size: j['size'] as String?,
        price: (j['price'] as num).toDouble(),
        quantity: (j['quantity'] as num).toInt(),
        isManual: j['entryMethod'] == 'MANUAL',
      );
}

class ExitOrder {
  final String id;
  final String? storeName;
  final double grandTotal;
  final String createdAt;
  final int ageMinutes;
  final bool hasOpenFlag;
  final String? flagReason;
  final String? flagNote;
  final String? flaggedBy;
  final List<ExitLine> lines;

  const ExitOrder({
    required this.id,
    this.storeName,
    required this.grandTotal,
    required this.createdAt,
    this.ageMinutes = 0,
    this.hasOpenFlag = false,
    this.flagReason,
    this.flagNote,
    this.flaggedBy,
    required this.lines,
  });

  int get manualLineCount => lines.where((l) => l.isManual).length;

  /// Short reference staff can read out: last 6 characters of the order id.
  String get shortRef => id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();

  factory ExitOrder.fromJson(Map<String, dynamic> j) {
    final flag = j['flaggedIssue'] as Map<String, dynamic>?;
    return ExitOrder(
      id: j['id'] as String,
      storeName: j['storeName'] as String?,
      grandTotal: (j['grandTotal'] as num).toDouble(),
      createdAt: j['createdAt'] as String,
      ageMinutes: (j['ageMinutes'] as num?)?.toInt() ?? 0,
      hasOpenFlag: j['hasOpenFlag'] as bool? ?? false,
      flagReason: flag?['reason'] as String?,
      flagNote: flag?['note'] as String?,
      flaggedBy: flag?['staffName'] as String?,
      lines: ((j['items'] as List?) ?? const [])
          .map((i) => ExitLine.fromJson((i as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class ExitResult {
  final ExitOutcome outcome;
  final String message;
  final ExitOrder? order;
  final String? exitedAt;
  final String? exitedByName;

  const ExitResult({
    required this.outcome,
    required this.message,
    this.order,
    this.exitedAt,
    this.exitedByName,
  });

  factory ExitResult.fromJson(Map<String, dynamic> j) => ExitResult(
        outcome: ExitOutcome.parse(j['outcome'] as String?),
        message: (j['message'] as String?) ?? '',
        order: j['order'] == null ? null : ExitOrder.fromJson((j['order'] as Map).cast<String, dynamic>()),
        exitedAt: j['exitedAt'] as String?,
        exitedByName: j['exitedByName'] as String?,
      );
}

/// What the scanner or the typed-code box accepts — the same rules as the
/// server (exitService.filterForScannedCode):
///
/// - The customer's exit code: 24 Crockford characters (0-9, A-Z without
///   I L O U), printed as "DQX1: XXXX XXXX XXXX XXXX XXXX XXXX". Spaces and
///   hyphens are ignored, the "DQX1:" prefix is optional and any case, the
///   code is upper-cased and the characters people confuse are mapped
///   (O → 0, I and L → 1). Returns "DQX1:<code>".
/// - For orders placed before exit codes, the raw 24-hex order id, sent as
///   typed; a bare hex string is also a valid code, and the server tries both.
///
/// Returns null for anything else, so it never reaches the server.
String? normaliseExitCode(String raw) {
  var body = raw.replaceAll(RegExp(r'[\s-]+'), '');
  final prefixed = RegExp(r'^dqx1:', caseSensitive: false).hasMatch(body);
  if (prefixed) body = body.substring(5);
  if (!prefixed && RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(body)) return body.toLowerCase();
  final code = body.toUpperCase().replaceAll('O', '0').replaceAll(RegExp('[IL]'), '1');
  if (RegExp(r'^[0-9A-HJKMNP-TV-Z]{24}$').hasMatch(code)) return 'DQX1:$code';
  return null;
}
