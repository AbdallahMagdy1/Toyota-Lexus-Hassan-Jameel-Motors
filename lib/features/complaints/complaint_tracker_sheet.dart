import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/di/injector.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/navigation/sheet_routes.dart';
import '../account/presentation/registered_home_view.dart' show StageBar;
import '../auth/bloc/auth_bloc.dart';
import '../home/presentation/widgets/home_bits.dart';
import '../settings/bloc/locale_cubit.dart';
import 'complaints_models.dart';
import 'complaints_repository.dart';

/// Opens the "متابعة الشكاوى" sheet — the website's complaint tracker
/// (status, stage timeline, conversation and customer replies) on mobile.
Future<void> showComplaintTrackerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (_) => const FractionallySizedBox(
        heightFactor: 0.92, child: _TrackerSheetBody()),
  );
}

const _kSolvedGreen = Color(0xFF1E9E5A);

final class _TrackerSheetBody extends StatefulWidget {
  const _TrackerSheetBody();

  @override
  State<_TrackerSheetBody> createState() => _TrackerSheetBodyState();
}

final class _TrackerSheetBodyState extends State<_TrackerSheetBody> {
  List<Complaint>? _items;
  bool _loading = true;
  bool _failed = false;

  final Map<String, TextEditingController> _replies = {};
  String? _replyBusyGuid;

  int? _userId;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _replies.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _replyCtrl(String guid) =>
      _replies.putIfAbsent(guid, TextEditingController.new);

  /// Signed-in users track by userId; guests track by the phone remembered
  /// at submit time (the app's counterpart of the website cookie).
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    final user = sl<AuthBloc>().state.user;
    _userId = user?.userId;
    _phone = (user?.phone ?? '').isNotEmpty
        ? ComplaintsRepository.normalizePhone(user!.phone!)
        : await ComplaintsRepository.storedPhone();
    final list = await ComplaintsRepository(sl<ApiClient>())
        .myComplaints(userId: _userId, phone: _phone);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = list == null;
      if (list != null) _items = list;
    });
  }

  Future<void> _sendReply(Complaint c) async {
    final t = AppLocalizations.of(context);
    final ctrl = _replyCtrl(c.guid);
    final message = ctrl.text.trim();
    if (message.isEmpty || _replyBusyGuid != null) return;
    setState(() => _replyBusyGuid = c.guid);
    final ok = await ComplaintsRepository(sl<ApiClient>()).reply(
      guid: c.guid,
      webUserId: _userId,
      phone: _phone,
      message: message,
    );
    if (!mounted) return;
    setState(() => _replyBusyGuid = null);
    if (ok) {
      ctrl.clear();
      await _load(silent: true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.offersSubmitFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<LocaleCubit>().state.languageCode;

    return Column(children: [
      const SheetHandle(),
      Padding(
        padding: EdgeInsets.fromLTRB(
            context.rs(20), context.rs(6), context.rs(20), 0),
        child: Row(children: [
          Expanded(
            child: Text(t.cmpTrack,
                style: TextStyle(
                    fontSize: context.rf(17), fontWeight: FontWeight.w800)),
          ),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 16),
            ),
          ),
        ]),
      ),
      SizedBox(height: context.rs(6)),
      Expanded(child: _body(t, scheme, lang)),
    ]);
  }

  Widget _body(AppLocalizations t, ColorScheme scheme, String lang) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_failed && (_items == null || _items!.isEmpty)) {
      // Error + retry — tappable, comfortably above the 44pt target.
      return Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _load,
          child: Padding(
            padding: EdgeInsets.all(context.rs(24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh_rounded,
                  size: 34, color: scheme.onSurface.withValues(alpha: 0.35)),
              SizedBox(height: context.rs(10)),
              Text(t.homeErrorRetry,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: context.rf(12.5),
                      color: scheme.onSurface.withValues(alpha: 0.55))),
            ]),
          ),
        ),
      );
    }

    final items = _items ?? const <Complaint>[];
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inbox_outlined,
              size: 44, color: scheme.onSurface.withValues(alpha: 0.25)),
          SizedBox(height: context.rs(10)),
          Text(t.cmpEmpty,
              style: TextStyle(
                  fontSize: context.rf(13),
                  color: scheme.onSurface.withValues(alpha: 0.55))),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            context.rs(16),
            context.rs(8),
            context.rs(16),
            context.rs(24) + MediaQuery.of(context).viewInsets.bottom),
        itemCount: items.length,
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.only(bottom: context.rs(14)),
          child: _ComplaintCard(
            complaint: items[i],
            lang: lang,
            replyController: _replyCtrl(items[i].guid),
            replyBusy: _replyBusyGuid == items[i].guid,
            onReply: () => _sendReply(items[i]),
          ),
        ).animate(delay: (35 * (i % 5)).ms).fadeIn(duration: 240.ms),
      ),
    );
  }
}

final class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({
    required this.complaint,
    required this.lang,
    required this.replyController,
    required this.replyBusy,
    required this.onReply,
  });

  final Complaint complaint;
  final String lang;
  final TextEditingController replyController;
  final bool replyBusy;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final c = complaint;

    final statusLabel = switch (c.status) {
      'Solved' => t.cmpStatusSolved,
      'Updated' => t.cmpStatusUpdated,
      _ => t.cmpStatusNew,
    };
    // New = neutral, Updated = brand/progress, Solved = green.
    final statusColor = switch (c.status) {
      'Solved' => _kSolvedGreen,
      'Updated' => scheme.primary,
      _ => scheme.onSurface.withValues(alpha: 0.6),
    };
    final typeIcon = switch (c.complaintType) {
      'Sales' => Icons.directions_car_filled_outlined,
      'SpareParts' => Icons.settings_suggest_outlined,
      'Maintenance' => Icons.build_outlined,
      _ => Icons.support_agent_rounded,
    };
    final created = c.createdDate == null
        ? ''
        : DateFormat('d MMM yyyy', lang).format(c.createdDate!.toLocal());

    // Belt and braces with the backend dedupe: hide the customer's first
    // event when it just repeats the complaint body.
    final events = <ComplaintEvent>[];
    var skippedEcho = false;
    for (final e in c.events) {
      if (!skippedEcho &&
          !e.isStaff &&
          (e.note ?? '').trim() == c.body.trim()) {
        skippedEcho = true;
        continue;
      }
      events.add(e);
    }

    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: softCardDecoration(context, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: type icon, ticket + department • date, status chip ──
          Row(children: [
            Container(
              width: context.rs(34),
              height: context.rs(34),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(typeIcon, size: 16, color: scheme.primary),
            ),
            SizedBox(width: context.rs(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.ticketNo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          fontSize: context.rf(12.5),
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: context.rs(2)),
                  Text(
                    [c.department, created]
                        .where((s) => s.isNotEmpty)
                        .join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: context.rf(9.5),
                        color: scheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.rs(8)),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(9), vertical: context.rs(4)),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      fontSize: context.rf(9),
                      fontWeight: FontWeight.w800,
                      color: statusColor)),
            ),
          ]),
          SizedBox(height: context.rs(14)),

          // ── 3-step stage timeline (same visual as service tracking) ──
          StageBar(
            labels: [t.cmpStageReceived, t.cmpStageUpdated, t.cmpStageSolved],
            activeIndex: c.stageIndex,
          ),
          SizedBox(height: context.rs(14)),

          // ── Complaint text ──
          if ((c.subject ?? '').isNotEmpty) ...[
            Text(c.subject!,
                style: TextStyle(
                    fontSize: context.rf(12.5), fontWeight: FontWeight.w800)),
            SizedBox(height: context.rs(4)),
          ],
          Text(t.cmpBodyText,
              style: TextStyle(
                  fontSize: context.rf(10),
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.5))),
          SizedBox(height: context.rs(3)),
          Text(c.body,
              style: TextStyle(fontSize: context.rf(12), height: 1.55)),

          // ── Complaint attachments ──
          if (c.attachments.isNotEmpty) ...[
            SizedBox(height: context.rs(10)),
            _ThumbRow(urls: c.attachments, size: 56),
          ],

          // ── Conversation thread ──
          if (events.isNotEmpty) ...[
            SizedBox(height: context.rs(14)),
            Text(t.cmpConversation,
                style: TextStyle(
                    fontSize: context.rf(12.5), fontWeight: FontWeight.w800)),
            SizedBox(height: context.rs(8)),
            for (final e in events)
              Padding(
                padding: EdgeInsets.only(bottom: context.rs(8)),
                child: _EventBubble(event: e, lang: lang),
              ),
          ],

          // ── Reply — only while the staff asked for customer input ──
          if (c.canReply) ...[
            SizedBox(height: context.rs(10)),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: TextField(
                  controller: replyController,
                  minLines: 1,
                  maxLines: 3,
                  enabled: !replyBusy,
                  decoration: InputDecoration(
                    hintText: t.cmpReplyHint,
                    isDense: true,
                    filled: true,
                    fillColor: scheme.onSurface.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: context.rs(8)),
              SizedBox(
                width: 44,
                height: 44,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  onPressed: replyBusy ? null : onReply,
                  child: replyBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2))
                      : Tooltip(
                          message: t.cmpReplySend,
                          // The send glyph points "forward" — mirror it in RTL.
                          child: Transform.flip(
                            flipX: Directionality.of(context) ==
                                TextDirection.rtl,
                            child:
                                const Icon(Icons.send_rounded, size: 18),
                          ),
                        ),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

final class _EventBubble extends StatelessWidget {
  const _EventBubble({required this.event, required this.lang});

  final ComplaintEvent event;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final e = event;
    final staff = e.isStaff;
    final when = e.createdAt == null
        ? ''
        : DateFormat('d MMM yyyy • HH:mm', lang).format(e.createdAt!.toLocal());

    return Align(
      // Staff start-aligned, customer end-aligned — RTL flips naturally.
      alignment:
          staff ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.72),
        child: Container(
          padding: EdgeInsets.all(context.rs(10)),
          decoration: BoxDecoration(
            color: staff
                ? scheme.onSurface.withValues(alpha: 0.05)
                : scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(14),
              topEnd: const Radius.circular(14),
              bottomStart: Radius.circular(staff ? 4 : 14),
              bottomEnd: Radius.circular(staff ? 14 : 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  staff ? Icons.headset_mic_rounded : Icons.person_rounded,
                  size: 13,
                  color: staff
                      ? scheme.onSurface.withValues(alpha: 0.55)
                      : scheme.primary,
                ),
                SizedBox(width: context.rs(5)),
                Text(
                  staff ? t.cmpStaff : t.cmpYou,
                  style: TextStyle(
                      fontSize: context.rf(9.5),
                      fontWeight: FontWeight.w800,
                      color: staff
                          ? scheme.onSurface.withValues(alpha: 0.65)
                          : scheme.primary),
                ),
                if (when.isNotEmpty) ...[
                  SizedBox(width: context.rs(7)),
                  Text(when,
                      style: TextStyle(
                          fontSize: context.rf(8.5),
                          color: scheme.onSurface.withValues(alpha: 0.4))),
                ],
              ]),
              if ((e.note ?? '').trim().isNotEmpty) ...[
                SizedBox(height: context.rs(5)),
                Text(e.note!.trim(),
                    style:
                        TextStyle(fontSize: context.rf(11.5), height: 1.5)),
              ],
              if (e.attachments.isNotEmpty) ...[
                SizedBox(height: context.rs(7)),
                _ThumbRow(urls: e.attachments, size: 44),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A wrap of tappable image thumbnails; tap opens a full-screen viewer.
final class _ThumbRow extends StatelessWidget {
  const _ThumbRow({required this.urls, required this.size});

  final List<String> urls;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: context.rs(7),
      runSpacing: context.rs(7),
      children: [
        for (final url in urls)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openViewer(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                width: context.rs(size),
                height: context.rs(size),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: context.rs(size),
                  height: context.rs(size),
                  color: scheme.onSurface.withValues(alpha: 0.06),
                  child: Icon(Icons.broken_image_outlined,
                      size: 16,
                      color: scheme.onSurface.withValues(alpha: 0.35)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static void _openViewer(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.94),
      builder: (context) => Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 0,
          end: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.white.withValues(alpha: 0.14),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.close_rounded,
                        size: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
