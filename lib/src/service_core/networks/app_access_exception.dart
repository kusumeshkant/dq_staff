/// A GraphQL error that carries its structured `extensions` through to the UI.
///
/// Why this exists: the app used to throw `Exception(message)` and the login
/// controller then decided what to show by substring-matching the message text.
/// That is fragile in both directions — a role-mismatch message that happens to
/// contain "connection" gets reported as a network failure, and any re-wording
/// of a backend message silently changes which branch the UI takes.
///
/// `code` and `hint` come straight from the server's error extensions and are
/// part of the API contract, so the UI can switch on them without caring how
/// the prose is worded.
class AppAccessException implements Exception {
  final String message;

  /// GraphQL error code — e.g. `FORBIDDEN`, `NOT_FOUND`, `BAD_USER_INPUT`.
  final String? code;

  /// Role-mismatch discriminator — e.g. `CUSTOMER_NO_STAFF`.
  final String? hint;

  const AppAccessException(this.message, {this.code, this.hint});

  /// True when the backend rejected the account's ROLE, as opposed to failing
  /// to reach the backend. These must never be reported as network errors.
  bool get isRoleMismatch => code == 'FORBIDDEN' || code == 'NOT_FOUND';

  @override
  String toString() => message;
}

/// Maps a backend access rejection to copy that tells the user what to do.
///
/// Kept as a pure top-level function, separate from the controller, so the
/// mapping that was previously wrong can be unit-tested without Firebase, a
/// GraphQL client, or GetX bindings.
///
/// Switches on `hint`/`code` rather than message text: re-wording a server
/// message must not silently change which branch runs, and a role rejection
/// whose prose happens to contain "connection" must never be reported as a
/// network failure.
String roleMismatchMessage(AppAccessException e, {bool isUat = false}) {
  const needInvite = 'Register with the invite code your store admin sent you.';

  switch (e.hint) {
    case 'CUSTOMER_NO_STAFF':
      return "This account isn't registered as staff. "
          'Ask your store admin for an invite, then register with the code they send.';
    case 'NO_ACCOUNT':
      return 'No staff account found for this login. $needInvite';
  }

  // No hint: validateAppAccess returns NOT_FOUND when there is no account at
  // all, and a bare FORBIDDEN for an account holding neither staff nor
  // customer roles. Both are actionable the same way.
  if (e.code == 'NOT_FOUND') {
    return 'No staff account found for this login. $needInvite';
  }
  if (isUat) return '[UAT] ${e.message}';

  // Fall back to the server's own message — it is already user-readable, and
  // is a better thing to show than a generic placeholder.
  //
  // Unless it is blank. The login and register screens render the error box
  // only when the message is non-empty, so returning '' shows the user nothing
  // at all: the spinner stops and the screen sits there looking idle. A blunt
  // message beats a silent failure.
  if (e.message.trim().isEmpty) {
    return 'Could not sign you in to the staff app. '
        'Ask your store admin to confirm your access.';
  }
  return e.message;
}
