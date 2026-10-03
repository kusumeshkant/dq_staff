// ExitController — the screen logic of the exit flow, against a fake API.
import 'package:dq_staff/src/domain/entity/exit_entity.dart';
import 'package:dq_staff/src/domain/entity/order_entity.dart';
import 'package:dq_staff/src/presentation/exit/exit_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'fake_exit_api.dart';

void main() {
  late FakeExitApi api;
  late ExitController c;
  var admin = false;

  setUp(() {
    Get.testMode = true;
    admin = false;
    api = FakeExitApi()..onVerify = (_) => res(ExitOutcome.okToExit, ord: order());
    c = ExitController(api: api, isAdmin: () => admin);
  });

  group('exit code input', () {
    test('accepts DQX1 codes and legacy 24-hex ids, trimmed', () {
      expect(normaliseExitCode('  $qr '), qr);
      expect(normaliseExitCode('6AC02873EF56A98EA03E3764'), '6ac02873ef56a98ea03e3764');
    });

    test('accepts the code as the customer app prints it: grouped, any-case prefix, or no prefix', () {
      expect(normaliseExitCode('DQX1: AbCd EfGh IjKl MnOp QrSt Uv'), qr);
      expect(normaliseExitCode(' dqx1:AbCdEfGhIjKlMnOpQrStUv '), qr);
      expect(normaliseExitCode('AbCd EfGh IjKl MnOp QrSt Uv'), qr);
      expect(normaliseExitCode('abcdefghijklmnopqrstuv'), 'DQX1:abcdefghijklmnopqrstuv', reason: 'the code itself stays case-sensitive');
    });

    test('rejects anything else', () {
      for (final bad in ['', 'DQX1:', 'DQX1:short', 'DQX2:AbCdEfGhIjKlMnOpQrStUv', 'hello', '6ac02873ef56a98ea03e376', '$qr x']) {
        expect(normaliseExitCode(bad), isNull, reason: bad);
      }
    });

    test('an invalid typed code shows an error and never calls the server', () async {
      c.startTyping();
      await c.submitTyped('12345');
      expect(c.typedError.value, contains('DQX1'));
      expect(api.verifyCalls, isEmpty);
      expect(c.stage.value, ExitStage.typing);
    });

    test('a valid typed code is verified', () async {
      c.startTyping();
      await c.submitTyped(' $qr ');
      expect(api.verifyCalls, [qr]);
      expect(c.stage.value, ExitStage.review);
    });

    test('the camera is ignored unless scanning, and non-exit QRs are not sent', () async {
      await c.onScanned(qr); // not scanning
      expect(api.verifyCalls, isEmpty);
      c.startScan();
      await c.onScanned('https://example.com');
      expect(api.verifyCalls, isEmpty);
      expect(c.errorMessage.value, contains('not a DQ exit QR'));
      await c.onScanned(qr);
      await c.onScanned(qr); // same frame fired again after the stage changed
      expect(api.verifyCalls, [qr]);
    });
  });

  group('checklist and complete', () {
    setUp(() async {
      api.onComplete = (_, __, ___) => res(ExitOutcome.exited, ord: order());
      c.startScan();
      await c.onScanned(qr);
    });

    test('complete is unavailable until every line is ticked', () async {
      expect(c.canComplete, isFalse);
      c.toggle('L1');
      expect(c.canComplete, isFalse);
      await c.complete();
      expect(api.completeCalls, isEmpty);
      c.toggle('L2');
      expect(c.canComplete, isTrue);
      c.toggle('L2'); // untick
      expect(c.canComplete, isFalse);
    });

    test('completing sends every line id and a requestId, then shows the outcome', () async {
      c..toggle('L1')..toggle('L2');
      await c.complete();
      expect(api.completeCalls.single.$1, qr);
      expect(api.completeCalls.single.$2, ['L1', 'L2']);
      expect(api.completeCalls.single.$3, matches(RegExp(r'^[A-Za-z0-9_-]{24}$')));
      expect(c.stage.value, ExitStage.outcome);
      expect(c.result.value!.outcome, ExitOutcome.exited);
    });

    test('a network failure keeps the checklist; retrying reuses the same requestId', () async {
      c..toggle('L1')..toggle('L2');
      api.throwOnComplete = Exception('Network error — check your connection');
      await c.complete();
      expect(c.stage.value, ExitStage.review);
      expect(c.errorMessage.value, contains('Press Complete exit again'));
      await c.complete();
      expect(api.completeCalls, hasLength(2));
      expect(api.completeCalls[0].$3, api.completeCalls[1].$3);
      expect(c.result.value!.outcome, ExitOutcome.exited);
    });

    test('each new order review gets a fresh requestId', () async {
      final first = c.requestId;
      c.backToStart();
      c.startScan();
      await c.onScanned(qr);
      expect(c.requestId, isNot(first));
    });

    test('a second exit of the same QR shows ALREADY_EXITED with when and who', () async {
      api.onComplete = (_, __, ___) =>
          res(ExitOutcome.alreadyExited, ord: order(), at: '2026-10-03T05:23:58Z', by: 'UAT staff');
      c..toggle('L1')..toggle('L2');
      await c.complete();
      expect(c.result.value!.outcome, ExitOutcome.alreadyExited);
      expect(c.result.value!.exitedByName, 'UAT staff');
    });
  });

  group('blocked outcomes go straight to the outcome screen', () {
    for (final o in [
      ExitOutcome.alreadyExited, ExitOutcome.cancelled, ExitOutcome.notPaid,
      ExitOutcome.ownOrder, ExitOutcome.flagged, ExitOutcome.notFound,
    ]) {
      test(o.name, () async {
        api.onVerify = (_) => res(o, ord: o == ExitOutcome.notFound ? null : order());
        c.startScan();
        await c.onScanned(qr);
        expect(c.stage.value, ExitStage.outcome);
        expect(c.result.value!.outcome, o);
        expect(c.canComplete, isFalse);
      });
    }
  });

  group('manual exit from the open paid orders list', () {
    setUp(() {
      api.onCompleteManual = (_, __, ___, ____) => res(ExitOutcome.exited, ord: order());
      api.open = [order()];
    });

    test('loads the list', () async {
      await c.loadOpenOrders();
      expect(c.openOrders.single.ageMinutes, 12);
    });

    test('needs every line ticked AND a reason of at least 5 characters', () async {
      c.startManual(order());
      c..toggle('L1')..toggle('L2');
      expect(c.canComplete, isFalse);
      c.reason.value = 'ok';
      expect(c.canComplete, isFalse);
      c.reason.value = 'Phone dead, checked name';
      expect(c.canComplete, isTrue);
      await c.complete();
      expect(api.manualCalls.single.$1, order().id);
      expect(api.manualCalls.single.$2, 'Phone dead, checked name');
      expect(api.manualCalls.single.$3, ['L1', 'L2']);
      expect(api.completeCalls, isEmpty);
      expect(api.openCalls, 1, reason: 'the list refreshes after a manual exit');
    });
  });

  group('clearing a flag', () {
    setUp(() async {
      api.onVerify = (_) => res(ExitOutcome.flagged, ord: order(flagged: true));
      c.startScan();
      await c.onScanned(qr);
    });

    test('staff cannot: nothing is sent', () async {
      expect(await c.clearFlag('Recounted, all fine'), isFalse);
      expect(api.clearCalls, isEmpty);
    });

    test('an admin can, with a note, and the order is checked again', () async {
      admin = true;
      expect(await c.clearFlag('ok'), isFalse); // note too short
      api.onVerify = (_) => res(ExitOutcome.okToExit, ord: order());
      expect(await c.clearFlag('Recounted, all fine'), isTrue);
      expect(api.clearCalls.single, (order().id, 'Recounted, all fine'));
      expect(api.verifyCalls, [qr, qr]);
      expect(c.stage.value, ExitStage.review);
    });
  });

  group('old status flow', () {
    OrderEntity o(String status) =>
        OrderEntity(id: 'x', total: 1, tax: 0, grandTotal: 1, status: status, createdAt: '', items: const []);

    test('there is no "Complete Order" step any more; ready orders await the exit', () {
      expect(o('pending').nextStatus, 'preparing');
      expect(o('preparing').nextStatus, 'ready');
      expect(o('ready').nextStatus, isNull);
      expect(o('ready').nextStatusLabel, isNull);
      expect(o('ready').awaitsExit, isTrue);
      for (final s in ['pending', 'preparing', 'ready', 'completed', 'cancelled']) {
        expect(o(s).nextStatusLabel, isNot('Complete Order'));
        expect(o(s).nextStatus, isNot('completed'));
      }
    });
  });
}
