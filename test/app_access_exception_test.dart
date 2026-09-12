// Login-side half of the staff registration bug.
//
// A customer-role account signing in to the staff app was told "Network
// error. Check your internet connection and try again." The request had in
// fact succeeded — the backend returned FORBIDDEN / CUSTOMER_NO_STAFF — so
// the message sent the user to debug their wifi instead of asking their admin
// for an invite.
//
// These tests assert the specific message IS produced and that the generic
// network copy is never reached for a role rejection.

import 'package:flutter_test/flutter_test.dart';
import 'package:dq_staff/src/service_core/networks/app_access_exception.dart';

// The exact copy the old code fell through to. No role rejection may produce
// anything resembling it.
const _networkCopy = 'Network error';

void main() {
  group('customer-role account signing in to the staff app', () {
    final e = const AppAccessException(
      'This account is registered as a customer on DQ App. '
      'Customer and staff accounts must be separate — '
      'please use a different account for staff access.',
      code: 'FORBIDDEN',
      hint: 'CUSTOMER_NO_STAFF',
    );

    test('is told it is not a staff account, and how to become one', () {
      final msg = roleMismatchMessage(e);
      expect(msg, contains("isn't registered as staff"));
      expect(msg, contains('invite'));
    });

    test('is never shown the generic network error', () {
      expect(roleMismatchMessage(e), isNot(contains(_networkCopy)));
      expect(roleMismatchMessage(e, isUat: true), isNot(contains(_networkCopy)));
    });

    test('is classified as a role mismatch, not a transport failure', () {
      expect(e.isRoleMismatch, isTrue);
    });
  });

  group('other role-mismatch codes', () {
    test('NO_ACCOUNT points the user at registration', () {
      final msg = roleMismatchMessage(const AppAccessException(
        'No staff account found for this ID.',
        code: 'FORBIDDEN',
        hint: 'NO_ACCOUNT',
      ));
      expect(msg, contains('No staff account found'));
      expect(msg, contains('invite code'));
      expect(msg, isNot(contains(_networkCopy)));
    });

    test('NOT_FOUND with no hint still resolves to the registration prompt', () {
      final msg = roleMismatchMessage(const AppAccessException(
        'No staff account found for this ID. Please register and accept your store invite.',
        code: 'NOT_FOUND',
      ));
      expect(msg, contains('No staff account found'));
      expect(msg, isNot(contains(_networkCopy)));
    });

    test('an unhinted FORBIDDEN falls back to the server message, not a placeholder', () {
      const serverMsg = 'Access denied. Contact your store admin to get staff access.';
      final msg = roleMismatchMessage(
        const AppAccessException(serverMsg, code: 'FORBIDDEN'),
      );
      expect(msg, serverMsg);
      expect(msg, isNot(contains(_networkCopy)));
    });
  });

  group('errors carrying no usable extensions', () {
    // Found in self-review: the UI renders the error box only when the message
    // is non-empty, so returning an empty string here shows the user nothing at
    // all — the spinner just stops. Silent failure is worse than a blunt message.
    test('an empty server message never produces empty UI copy', () {
      final msg = roleMismatchMessage(const AppAccessException(''));
      expect(msg, isNotEmpty);
      expect(msg, contains('admin'));
    });

    test('a whitespace-only server message is treated as empty', () {
      expect(roleMismatchMessage(const AppAccessException('   ')).trim(), isNotEmpty);
    });

    test('an error with no code and no hint is not presented as a role problem', () {
      final e = const AppAccessException('Cannot query field "foo" on type "Query".');
      expect(e.isRoleMismatch, isFalse);
    });

    test('a server fault is not classified as a role mismatch', () {
      const e = AppAccessException('Internal server error',
          code: 'INTERNAL_SERVER_ERROR');
      expect(e.isRoleMismatch, isFalse);
    });
  });

  group('regression guard — prose must not drive classification', () {
    test('a role rejection whose message mentions a connection is still a role rejection', () {
      // The old substring matcher keyed on "connection" and would have
      // mis-routed this to the network bucket.
      final msg = roleMismatchMessage(const AppAccessException(
        'Your account has no staff connection to this store.',
        code: 'FORBIDDEN',
        hint: 'CUSTOMER_NO_STAFF',
      ));
      expect(msg, contains("isn't registered as staff"));
      expect(msg, isNot(contains(_networkCopy)));
    });

    test('UAT surfaces the raw server detail for diagnosis', () {
      final msg = roleMismatchMessage(
        const AppAccessException('some unmapped backend refusal', code: 'FORBIDDEN'),
        isUat: true,
      );
      expect(msg, startsWith('[UAT]'));
      expect(msg, contains('some unmapped backend refusal'));
    });
  });
}
