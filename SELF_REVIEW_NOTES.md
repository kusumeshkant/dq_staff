# Self-review — `feature/staff-invite-registration` (dq_staff)

Local scratch file for the human reviewer. Not committed.

Base: `main` · Commits: `b70b6d1` (fix), `56f9b7e` (self-review fix)
`flutter analyze`: clean · `flutter test`: **12 passed / 12** (+1 pre-existing smoke test)

---

## What I checked, and how

### 1. Errors with no `extensions.code` / `hint`

This was the sharpest question and it found a real defect, fixed in `56f9b7e`.

Two distinct cases, and they behave differently:

**A raw 500 / network timeout does not reach `AppAccessException` at all.**
`validateAppAccess` only constructs it when `graphqlErrors.isNotEmpty`. A
transport failure leaves `graphqlErrors` empty and populates `linkException`, so
it falls to the pre-existing `Exception(_errorMessage(...))` → `_friendlyError`
path, unchanged by this branch. Verified by reading `auth_remote_ds.dart:189-203`.

**A GraphQL error with a blank message rendered nothing at all.** Both
`login_page.dart:112` and the register page gate the error box on
`errorMessage.value.isNotEmpty`, so returning `''` showed the user *no error* —
the spinner stopped and the screen sat there looking idle. Silent failure.
Confirmed by writing the test first and watching it fail
(`Expected: non-empty / Actual: ''`), then fixing.

**A server fault was being dressed up as a role problem.** The original commit
sent every `AppAccessException` through `roleMismatchMessage`, whose fallback is
the server's own message. An `INTERNAL_SERVER_ERROR` or a malformed query would
therefore surface under role-mismatch handling. Now gated on `isRoleMismatch`
(`FORBIDDEN`/`NOT_FOUND`); everything else falls through to `_friendlyError`.

`e.message` is non-nullable `String` in Dart, so `null` was never possible —
empty was, and is now handled.

**Confident.**

### 2. Did my edits disturb the carried-over routing refactor?

The pre-existing uncommitted work (named-route migration) lived in two of the
files I edited. Checked the three routing call sites in `HEAD`:

| File | Line | Value |
|---|---|---|
| `login_controller.dart` | 58 | `Get.offAllNamed(AppRoutes.invite)` |
| `login_controller.dart` | 79 | `Get.offAllNamed(AppRoutes.home)` |
| `register_controller.dart` | 99 | `Get.offAllNamed(AppRoutes.login)` |

All three match what `git diff` showed in the working tree *before* I edited
anything (captured at the start of the previous session: the `AppRoutes` import
added, the four direct page/binding imports removed, and `Get.offAll(() =>
const XPage(), binding: XBinding())` replaced in each spot). No direct
`HomePage`/`InviteCodePage`/`LoginPage` imports remain. Unmodified by me.

**Confident** — though note this is reconstruction from the recorded diff, not
from a stash, so it can't be proven by `git` alone. If you want certainty,
compare against whatever that refactor's own branch/stash holds.

### 3. Signature change fan-out

`registerInBackend(String name)` → `registerInBackend(String name, String inviteCode)`.
Grepped every reference: interface (`auth_repository.dart`), impl
(`auth_repository_impl.dart`), datasource, and the single caller in
`register_controller.dart`. All updated; `flutter analyze` clean across the whole
app, which would catch any missed implementer of the abstract class.

`registerAsCustomer` now appears in `dq_staff` only inside a comment. It remains
live and untouched in `dq_app`, which legitimately needs it.

**Confident.**

---

## Things I want a second pair of eyes on

1. **The invite-code field is required client-side before Firebase account
   creation.** That is deliberate — it avoids creating a Firebase user we would
   then have to roll back — but it means a staff member who has been invited and
   mistypes the code gets a client-side rejection with no server round trip. Fine
   behaviour, just confirm it matches what you want the UX to be.

2. **`InviteCodePage` is now a second, older route to the staff role.** Login
   with a null `storeId` still sends the user there, and it calls `acceptInvite`
   — which has no email binding (F-12). My registration path is bound; that one
   is not. Worth deciding whether that screen should survive at all now that
   registration takes the code directly.

3. **Copy.** I wrote the user-facing strings ("This account isn't registered as
   staff. Ask your store admin for an invite…"). Someone who owns product voice
   should sign those off — they are in
   `lib/src/service_core/networks/app_access_exception.dart`.

4. **`roleMismatchMessage` lives next to the exception class**, not in the
   controller, purely so it is testable without Firebase/GraphQL/GetX. If the
   codebase has a convention for where UI copy mapping belongs, move it.

## Not checked

- **No widget or integration test** drives `LoginController.login()` end to end.
  `login()` calls `GraphQLClientProvider.reinitWithToken()`, which needs a real
  Firebase instance, so the controller path is not unit-testable as written. I
  tested the extracted pure function instead. The wiring between the two — that
  `login()` actually routes an `AppAccessException` into `roleMismatchMessage` —
  is verified only by reading, and by the UAT run.
- The register screen's own error path has no unit test for the same reason.
