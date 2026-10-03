import 'package:dq_staff/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../widgets/app_glass_card.dart';
import '../../../widgets/themed_background.dart';
import '../../domain/entity/exit_entity.dart';
import '../../theme/app_theme.dart';
import 'exit_controller.dart';

String _rupees(double v) {
  final paise = (v * 100).round();
  final whole = paise ~/ 100, cents = paise % 100;
  return cents == 0 ? '₹$whole' : '₹$whole.${cents.toString().padLeft(2, '0')}';
}

String _when(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)} on ${d.day}/${d.month}/${d.year}';
}

String _age(int minutes) => minutes < 60
    ? '$minutes min'
    : minutes < 60 * 24
        ? '${minutes ~/ 60} h ${minutes % 60} min'
        : '${minutes ~/ (60 * 24)} d ${(minutes % (60 * 24)) ~/ 60} h';

/// Exit tab: check paid items against the bag and let the customer out.
class ExitPage extends StatelessWidget {
  const ExitPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExitController>();
    return ThemedBackground(
      child: DefaultTabController(
        length: 2,
        child: Builder(builder: (context) {
          final tabs = DefaultTabController.of(context);
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Exit', style: TextStyle(color: AppTheme.textPrimary)),
              bottom: TabBar(
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                onTap: (i) {
                  if (i == 1) c.loadOpenOrders();
                },
                tabs: [
                  const Tab(key: Key('exit-tab-scan'), text: 'Scan'),
                  Obx(() => Tab(
                        key: const Key('exit-tab-open'),
                        text: c.openOrders.isEmpty ? 'Open paid orders' : 'Open paid orders (${c.openOrders.length})',
                      )),
                ],
              ),
            ),
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const _ScanTab(),
                _OpenOrdersTab(onPick: (o) {
                  c.startManual(o);
                  tabs.animateTo(0);
                }),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Scan tab ──────────────────────────────────────────────────────────────────

class _ScanTab extends StatelessWidget {
  const _ScanTab();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExitController>();
    return Obx(() => switch (c.stage.value) {
          ExitStage.start => const _StartView(),
          ExitStage.scanning => const _ScannerView(),
          ExitStage.typing => const _TypeCodeView(),
          ExitStage.loading => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          ExitStage.review => const _ReviewView(),
          ExitStage.outcome => const _OutcomeView(),
        });
  }
}

class _StartView extends StatelessWidget {
  const _StartView();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExitController>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner_rounded, color: AppColors.info, size: 56),
              const SizedBox(height: AppSpacing.lg),
              const Text('Customer exit',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Scan the customer\'s exit QR, check every item against the bag, then complete the exit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
              ),
              Obx(() => c.errorMessage.value.isEmpty
                  ? const SizedBox(height: AppSpacing.xxl)
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Text(c.errorMessage.value,
                          key: const Key('exit-error'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error)),
                    )),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('exit-start-scan'),
                  onPressed: c.startScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan exit QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('exit-start-type'),
                  onPressed: c.startTyping,
                  icon: const Icon(Icons.keyboard_rounded),
                  label: const Text('Type exit code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerView extends StatefulWidget {
  const _ScannerView();

  @override
  State<_ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<_ScannerView> {
  final MobileScannerController _cam = MobileScannerController();

  @override
  void dispose() {
    _cam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExitController>();
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _cam,
            onDetect: (capture) {
              final raw = capture.barcodes.firstOrNull?.rawValue;
              if (raw != null) c.onScanned(raw);
            },
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Camera permission was denied. Type the exit code instead.'
                      : 'The camera is not available here. Type the exit code instead.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ),
            ),
          ),
        ),
        Obx(() => c.errorMessage.value.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(c.errorMessage.value, style: const TextStyle(color: AppColors.warning)),
              )),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: c.backToStart,
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textPrimary)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('exit-scanner-type'),
                  onPressed: c.startTyping,
                  icon: const Icon(Icons.keyboard_rounded, color: AppTheme.textPrimary),
                  label: const Text('Type exit code', style: TextStyle(color: AppTheme.textPrimary)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeCodeView extends StatefulWidget {
  const _TypeCodeView();

  @override
  State<_TypeCodeView> createState() => _TypeCodeViewState();
}

class _TypeCodeViewState extends State<_TypeCodeView> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExitController>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Type exit code',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'The code printed under the customer\'s QR (starts with DQX1:), or the order id for older orders.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(() => TextField(
                    key: const Key('exit-code-field'),
                    controller: _field,
                    autofocus: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'DQX1:…',
                      errorText: c.typedError.value.isEmpty ? null : c.typedError.value,
                      errorMaxLines: 3,
                    ),
                    onChanged: (_) => c.typedError.value = '',
                    onSubmitted: c.submitTyped,
                  )),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: c.backToStart,
                      child: const Text('Back', style: TextStyle(color: AppTheme.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('exit-code-submit'),
                      onPressed: () => c.submitTyped(_field.text),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                      child: const Text('Check order'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Checklist ─────────────────────────────────────────────────────────────────

class _ReviewView extends StatefulWidget {
  const _ReviewView();

  @override
  State<_ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<_ReviewView> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExitController>();
    return Obx(() {
      final o = c.order!;
      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                AppGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.isManual ? 'Manual exit (no QR)' : 'Paid — check the bag',
                          style: TextStyle(
                              color: c.isManual ? AppColors.warning : AppColors.success,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_rupees(o.grandTotal)} · ${o.lines.length} line${o.lines.length == 1 ? '' : 's'} · ref ${o.shortRef}',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                      ),
                      if (o.manualLineCount > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${o.manualLineCount} item${o.manualLineCount == 1 ? ' was' : 's were'} typed in by the customer — check ${o.manualLineCount == 1 ? 'it' : 'them'} carefully.',
                          key: const Key('exit-manual-summary'),
                          style: const TextStyle(color: AppColors.warning, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                if (o.hasOpenFlag) ...[
                  const SizedBox(height: AppSpacing.md),
                  _FlagBanner(order: o),
                ],
                const SizedBox(height: AppSpacing.md),
                Text('${c.ticked.length}/${o.lines.length} checked',
                    key: const Key('exit-progress'), style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                for (final line in o.lines) _LineTile(line: line, checked: c.ticked.contains(line.id)),
                if (c.isManual) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    key: const Key('exit-manual-reason'),
                    controller: _reason,
                    maxLength: 500,
                    maxLines: 2,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Reason for exiting without the QR (required)',
                      hintText: 'e.g. phone battery dead — checked name and bag',
                    ),
                    onChanged: (v) => c.reason.value = v,
                  ),
                ],
                if (c.errorMessage.value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(c.errorMessage.value,
                        key: const Key('exit-error'), style: const TextStyle(color: AppColors.error)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: c.isSubmitting.value ? null : c.backToStart,
                    child: const Text('Cancel', style: TextStyle(color: AppTheme.textPrimary)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    key: const Key('exit-complete'),
                    onPressed: c.canComplete ? c.complete : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white12,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: c.isSubmitting.value
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(c.allTicked
                            ? (c.reasonOk ? 'Complete exit' : 'Give a reason to complete')
                            : 'Tick every item to complete'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _LineTile extends StatelessWidget {
  final ExitLine line;
  final bool checked;
  const _LineTile({required this.line, required this.checked});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExitController>();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: line.isManual ? AppColors.warningSubtle : AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: line.isManual ? AppColors.warning : AppTheme.cardBorder, width: line.isManual ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => c.toggle(line.id),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Checkbox(
                  key: Key('exit-line-${line.id}'),
                  value: checked,
                  onChanged: (_) => c.toggle(line.id),
                  activeColor: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.name,
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                      if (line.variant != null)
                        Text(line.variant!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      Text('${_rupees(line.price)} × ${line.quantity}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      if (line.isManual)
                        Container(
                          key: Key('manual-badge-${line.id}'),
                          margin: const EdgeInsets.only(top: AppSpacing.xs),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Typed in by customer — check the tag',
                              style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                Text('×${line.quantity}',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlagBanner extends StatelessWidget {
  final ExitOrder order;
  const _FlagBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExitController>();
    return Container(
      key: const Key('exit-flag-banner'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Open issue: ${order.flagReason ?? 'flagged'}${order.flaggedBy == null ? '' : ' (by ${order.flaggedBy})'}',
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          if (order.flagNote != null && order.flagNote!.isNotEmpty)
            Text(order.flagNote!, style: const TextStyle(color: AppTheme.textPrimary)),
          const Text('An admin must clear this before the customer can exit.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          if (c.isAdmin) ...[
            const SizedBox(height: AppSpacing.sm),
            const _ClearFlagButton(),
          ],
        ],
      ),
    );
  }
}

class _ClearFlagButton extends StatelessWidget {
  const _ClearFlagButton();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExitController>();
    return OutlinedButton.icon(
      key: const Key('exit-clear-flag'),
      icon: const Icon(Icons.flag_outlined, color: AppColors.error),
      label: const Text('Clear flag (admin)', style: TextStyle(color: AppColors.error)),
      onPressed: () {
        final note = TextEditingController();
        Get.dialog(AlertDialog(
          title: const Text('Clear flag'),
          content: TextField(
            key: const Key('clear-flag-note'),
            controller: note,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'How was the issue resolved? (required)'),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            ElevatedButton(
              key: const Key('clear-flag-confirm'),
              onPressed: () async {
                final ok = await c.clearFlag(note.text);
                if (ok) Get.back();
              },
              child: const Text('Clear flag'),
            ),
          ],
        ));
      },
    );
  }
}

// ── Outcome ───────────────────────────────────────────────────────────────────

class _OutcomeView extends StatelessWidget {
  const _OutcomeView();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExitController>();
    return Obx(() {
      final r = c.result.value!;
      final (color, icon, title, detail) = switch (r.outcome) {
        ExitOutcome.exited => (AppColors.success, Icons.check_circle_rounded, 'Exit complete', 'The customer may leave.'),
        ExitOutcome.alreadyExited => (
            AppColors.error,
            Icons.block_rounded,
            'Already exited',
            'This order left${r.exitedAt == null ? '' : ' at ${_when(r.exitedAt)}'}'
                '${r.exitedByName == null ? '' : ' (checked by ${r.exitedByName})'}. '
                'Do not let the items through on this QR.'
          ),
        ExitOutcome.cancelled => (AppColors.error, Icons.cancel_rounded, 'Order cancelled', r.message),
        ExitOutcome.notPaid => (AppColors.error, Icons.money_off_rounded, 'Not paid', r.message),
        ExitOutcome.ownOrder => (AppColors.warning, Icons.person_off_rounded, 'Your own order', r.message),
        ExitOutcome.flagged => (AppColors.warning, Icons.flag_rounded, 'Open issue on this order', r.message),
        ExitOutcome.linesNotVerified => (AppColors.warning, Icons.checklist_rounded, 'Items not checked', r.message),
        ExitOutcome.notFound => (AppColors.error, Icons.search_off_rounded, 'No paid order found', r.message),
        ExitOutcome.okToExit => (AppColors.info, Icons.info_rounded, 'Ready', r.message),
      };
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 72, key: Key('exit-outcome-${r.outcome.name}')),
                const SizedBox(height: AppSpacing.lg),
                Text(title,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                Text(detail,
                    key: const Key('exit-outcome-detail'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.4)),
                if (r.order != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('${_rupees(r.order!.grandTotal)} · ref ${r.order!.shortRef}',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                ],
                if (r.outcome == ExitOutcome.flagged && r.order != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _FlagBanner(order: r.order!),
                ],
                if (c.errorMessage.value.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(c.errorMessage.value, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('exit-next'),
                    onPressed: c.backToStart,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Next customer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ── Open paid orders ──────────────────────────────────────────────────────────

class _OpenOrdersTab extends StatelessWidget {
  final void Function(ExitOrder) onPick;
  const _OpenOrdersTab({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExitController>();
    return Obx(() {
      if (c.openLoading.value && c.openOrders.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
      }
      return RefreshIndicator(
        onRefresh: c.loadOpenOrders,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Text(
              'Paid orders that have not exited, oldest first. Use this only when the customer cannot show '
              'their exit QR; a reason is required and recorded.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.md),
            if (c.openError.value.isNotEmpty)
              Text(c.openError.value, style: const TextStyle(color: AppColors.error)),
            if (c.openOrders.isEmpty && c.openError.value.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Text('No open paid orders.',
                    key: Key('open-orders-empty'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            for (final o in c.openOrders)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppGlassCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    key: Key('open-order-${o.id}'),
                    onTap: () => onPick(o),
                    title: Text('${_rupees(o.grandTotal)} · ${o.lines.length} line${o.lines.length == 1 ? '' : 's'} · ref ${o.shortRef}',
                        style: const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(
                      [
                        'paid ${_age(o.ageMinutes)} ago',
                        if (o.manualLineCount > 0) '${o.manualLineCount} typed in',
                        if (o.hasOpenFlag) 'FLAGGED',
                      ].join(' · '),
                      style: TextStyle(color: o.hasOpenFlag ? AppColors.error : AppTheme.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
