// Exit screens — what staff see and can press.
import 'package:dq_staff/src/domain/entity/exit_entity.dart';
import 'package:dq_staff/src/presentation/exit/exit_controller.dart';
import 'package:dq_staff/src/presentation/exit/exit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'fake_exit_api.dart';

void main() {
  late FakeExitApi api;
  var admin = false;

  Future<void> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(900, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(const GetMaterialApp(home: ExitPage()));
    await t.pump();
  }

  ElevatedButton completeButton(WidgetTester t) => t.widget<ElevatedButton>(find.byKey(const Key('exit-complete')));

  Future<void> typeCode(WidgetTester t, String code) async {
    await t.tap(find.byKey(const Key('exit-start-type')));
    await t.pump();
    await t.enterText(find.byKey(const Key('exit-code-field')), code);
    await t.tap(find.byKey(const Key('exit-code-submit')));
    await t.pump();
  }

  setUp(() {
    Get.testMode = true;
    Get.reset();
    admin = false;
    api = FakeExitApi()
      ..onVerify = ((_) => res(ExitOutcome.okToExit, ord: order()))
      ..onComplete = ((_, __, ___) => res(ExitOutcome.exited, ord: order()));
    Get.put(ExitController(api: api, isAdmin: () => admin));
  });
  tearDown(Get.reset);

  testWidgets('typed exit code → checklist with colour/size, price × qty and the typed-in line highlighted', (t) async {
    await pump(t);
    await typeCode(t, qr);
    expect(api.verifyCalls, [qr]);
    expect(find.text('Slim Fit Shirt'), findsOneWidget);
    expect(find.text('Navy · Size M'), findsOneWidget);
    expect(find.text('₹999 × 1'), findsOneWidget);
    expect(find.text('₹125 × 2'), findsOneWidget);
    expect(find.byKey(const Key('manual-badge-L1')), findsOneWidget);
    expect(find.byKey(const Key('manual-badge-L2')), findsNothing);
    expect(find.byKey(const Key('exit-manual-summary')), findsOneWidget);
  });

  testWidgets('a code typed with confused characters (o for 0, l for 1, lower case, spaces) is found', (t) async {
    await pump(t);
    await typeCode(t, 'dqx1: jctw b6ro xdpg z5mb vhfx ddlm');
    expect(api.verifyCalls, [qr]);
    expect(find.text('Slim Fit Shirt'), findsOneWidget);
  });

  testWidgets('an invalid typed code shows the reason and sends nothing', (t) async {
    await pump(t);
    await typeCode(t, 'not-a-code');
    expect(find.textContaining('starts with DQX1'), findsWidgets);
    expect(api.verifyCalls, isEmpty);
  });

  testWidgets('Complete exit is disabled until every line is ticked, then completes', (t) async {
    await pump(t);
    await typeCode(t, qr);
    expect(completeButton(t).onPressed, isNull);
    await t.tap(find.byKey(const Key('exit-line-L1')));
    await t.pump();
    expect(completeButton(t).onPressed, isNull);
    expect(find.text('1/2 checked'), findsOneWidget);
    await t.tap(find.byKey(const Key('exit-line-L2')));
    await t.pump();
    expect(completeButton(t).onPressed, isNotNull);
    await t.tap(find.byKey(const Key('exit-complete')));
    await t.pump();
    expect(api.completeCalls.single.$2, ['L1', 'L2']);
    expect(find.text('Exit complete'), findsOneWidget);
  });

  testWidgets('a second attempt shows ALREADY_EXITED with when and who', (t) async {
    api.onVerify = (_) => res(ExitOutcome.alreadyExited, ord: order(), at: '2026-10-03T05:23:58Z', by: 'UAT staff');
    await pump(t);
    await typeCode(t, qr);
    expect(find.byKey(const Key('exit-outcome-alreadyExited')), findsOneWidget);
    expect(find.text('Already exited'), findsOneWidget);
    final detail = t.widget<Text>(find.byKey(const Key('exit-outcome-detail'))).data!;
    expect(detail, contains('checked by UAT staff'));
    expect(detail, contains('2026'));
    expect(find.byKey(const Key('exit-complete')), findsNothing);
  });

  for (final (outcome, title) in [
    (ExitOutcome.cancelled, 'Order cancelled'),
    (ExitOutcome.notPaid, 'Not paid'),
    (ExitOutcome.ownOrder, 'Your own order'),
    (ExitOutcome.flagged, 'Open issue on this order'),
    (ExitOutcome.notFound, 'No paid order found'),
  ]) {
    testWidgets('outcome screen: ${outcome.name}', (t) async {
      api.onVerify = (_) => res(outcome, ord: outcome == ExitOutcome.notFound ? null : order(flagged: outcome == ExitOutcome.flagged));
      await pump(t);
      await typeCode(t, qr);
      expect(find.text(title), findsOneWidget);
      expect(find.text('server says ${outcome.name}'), findsOneWidget);
      expect(find.byKey(const Key('exit-complete')), findsNothing);
      await t.tap(find.byKey(const Key('exit-next')));
      await t.pump();
      expect(find.byKey(const Key('exit-start-scan')), findsOneWidget);
    });
  }

  testWidgets('flagged: staff never see "Clear flag"', (t) async {
    api.onVerify = (_) => res(ExitOutcome.flagged, ord: order(flagged: true));
    await pump(t);
    await typeCode(t, qr);
    expect(find.byKey(const Key('exit-flag-banner')), findsOneWidget);
    expect(find.byKey(const Key('exit-clear-flag')), findsNothing);
  });

  testWidgets('flagged: an admin clears it with a note, then gets the checklist', (t) async {
    admin = true;
    api.onVerify = (_) => res(ExitOutcome.flagged, ord: order(flagged: true));
    await pump(t);
    await typeCode(t, qr);
    await t.tap(find.byKey(const Key('exit-clear-flag')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('clear-flag-note')), 'Recounted, all correct');
    api.onVerify = (_) => res(ExitOutcome.okToExit, ord: order());
    await t.tap(find.byKey(const Key('clear-flag-confirm')));
    await t.pumpAndSettle();
    expect(api.clearCalls.single.$2, 'Recounted, all correct');
    expect(find.byKey(const Key('exit-complete')), findsOneWidget);
  });

  testWidgets('open paid orders: listed with age; manual exit needs a reason', (t) async {
    api
      ..open = [order(age: 135)]
      ..onCompleteManual = ((_, __, ___, ____) => res(ExitOutcome.exited, ord: order()));
    await pump(t);
    await t.tap(find.byKey(const Key('exit-tab-open')));
    await t.pumpAndSettle();
    expect(find.textContaining('paid 2 h 15 min ago'), findsOneWidget);
    expect(find.textContaining('1 typed in'), findsOneWidget);

    await t.tap(find.byKey(Key('open-order-${order().id}')));
    await t.pumpAndSettle();
    expect(find.text('Manual exit (no QR)'), findsOneWidget);
    await t.tap(find.byKey(const Key('exit-line-L1')));
    await t.tap(find.byKey(const Key('exit-line-L2')));
    await t.pump();
    expect(completeButton(t).onPressed, isNull, reason: 'reason still missing');
    await t.enterText(find.byKey(const Key('exit-manual-reason')), 'Phone dead, checked name and bag');
    await t.pump();
    expect(completeButton(t).onPressed, isNotNull);
    await t.tap(find.byKey(const Key('exit-complete')));
    await t.pumpAndSettle();
    expect(api.manualCalls.single.$2, 'Phone dead, checked name and bag');
    expect(find.text('Exit complete'), findsOneWidget);
  });
}
