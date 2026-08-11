import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/injector.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/navigation/sheet_routes.dart';
import '../../shared/widgets/app_dropdown.dart';
import '../../shared/widgets/app_header.dart';
import '../auth/bloc/auth_bloc.dart';
import '../complaints/complaints_section.dart';
import '../home/presentation/widgets/home_bits.dart';
import '../settings/bloc/locale_cubit.dart';
import 'content_models.dart';
import 'content_repository.dart';

/// Contact — the website's /contact: branch picker (فرع الخبر / فرع الدمام
/// from InvSites), open-in-maps, per-branch info tiles and the message form.
final class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _ContactCubit(ContentRepository(sl<ApiClient>())),
      child: const _ContactView(),
    );
  }
}

enum _SendPhase { idle, busy, done, failed }

final class _ContactState extends Equatable {
  const _ContactState({
    this.loading = true,
    this.page = const ContactPage(),
    this.branchIndex = 0,
    this.subjectId,
    this.phase = _SendPhase.idle,
    this.error = false,
  });

  final bool loading;
  final ContactPage page;
  final int branchIndex;
  final int? subjectId;
  final _SendPhase phase;
  final bool error;

  ContactBranch? get branch => page.branches.elementAtOrNull(branchIndex);

  _ContactState copyWith({
    bool? loading,
    ContactPage? page,
    int? branchIndex,
    int? Function()? subjectId,
    _SendPhase? phase,
    bool? error,
  }) =>
      _ContactState(
        loading: loading ?? this.loading,
        page: page ?? this.page,
        branchIndex: branchIndex ?? this.branchIndex,
        subjectId: subjectId == null ? this.subjectId : subjectId(),
        phase: phase ?? this.phase,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [loading, page, branchIndex, subjectId, phase, error];
}

final class _ContactCubit extends Cubit<_ContactState> {
  _ContactCubit(this._repo) : super(const _ContactState()) {
    final user = sl<AuthBloc>().state.user;
    name.text = user?.displayName('ar') ?? '';
    phone.text = user?.phone ?? '';
    email.text = user?.email ?? '';
    load();
  }

  final ContentRepository _repo;
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final message = TextEditingController();

  Future<void> load() async {
    final page = await _repo.contact();
    if (isClosed) return;
    emit(state.copyWith(
      loading: false,
      page: page,
      subjectId: () => page.subjects.firstOrNull?.id,
    ));
  }

  void selectBranch(int i) => emit(state.copyWith(branchIndex: i));
  void selectSubject(int? id) => emit(state.copyWith(subjectId: () => id));

  /// The website forces a Saudi mobile: strip 966/leading 0, force leading
  /// 5, 9 digits.
  static String normalizePhone(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('966')) d = d.substring(3);
    if (d.startsWith('0')) d = d.substring(1);
    if (!d.startsWith('5')) d = '5$d';
    return d.length > 9 ? d.substring(0, 9) : d;
  }

  Future<void> send() async {
    final p = normalizePhone(phone.text);
    final ok = name.text.trim().isNotEmpty &&
        p.length == 9 &&
        message.text.trim().isNotEmpty &&
        state.subjectId != null;
    if (!ok) {
      emit(state.copyWith(error: true));
      return;
    }
    emit(state.copyWith(phase: _SendPhase.busy, error: false));
    final sent = await _repo.sendMessage(
      name: name.text.trim(),
      email: email.text.trim(),
      phone: p,
      subject: state.subjectId!,
      message: message.text.trim(),
    );
    if (isClosed) return;
    emit(state.copyWith(phase: sent ? _SendPhase.done : _SendPhase.failed));
  }

  @override
  Future<void> close() {
    for (final c in [name, phone, email, message]) {
      c.dispose();
    }
    return super.close();
  }
}

final class _ContactView extends StatelessWidget {
  const _ContactView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.watch<_ContactCubit>();
    final state = cubit.state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.fromLTRB(context.rs(16), context.rs(18),
                      context.rs(16), context.rs(110)),
                  children: [
                    // Centered header, like the reference.
                    Text(t.contactTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: context.rf(24),
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: context.rs(4)),
                    Text(t.contactSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: context.rf(12),
                            height: 1.5,
                            color: scheme.onSurface.withValues(alpha: 0.55))),
                    SizedBox(height: context.rs(16)),

                    // Branch pills — red filled selected, bordered rest.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final (i, b) in state.page.branches.indexed)
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: context.rs(4)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => cubit.selectBranch(i),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(
                                    horizontal: context.rs(18),
                                    vertical: context.rs(9)),
                                decoration: BoxDecoration(
                                  color: i == state.branchIndex
                                      ? scheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: i == state.branchIndex
                                        ? scheme.primary
                                        : scheme.outline
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Text(
                                  b.name(lang),
                                  style: TextStyle(
                                    fontSize: context.rf(11.5),
                                    fontWeight: FontWeight.w800,
                                    color: i == state.branchIndex
                                        ? scheme.onPrimary
                                        : scheme.onSurface
                                            .withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: context.rs(16)),

                    // Branch visual card — brand gradient teaser that opens
                    // the branch in Google Maps.
                    if (state.branch != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => launchUrl(
                                state.branch!.mapsUri(),
                                mode: LaunchMode.externalApplication),
                            child: Ink(
                              height: context.rs(150),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: AlignmentDirectional.topStart,
                                  end: AlignmentDirectional.bottomEnd,
                                  colors: [
                                    Color.lerp(scheme.primary,
                                        Colors.black, 0.35)!,
                                    scheme.primary,
                                  ],
                                ),
                              ),
                              child: Stack(children: [
                                PositionedDirectional(
                                  end: context.rs(-18),
                                  bottom: context.rs(-22),
                                  child: Icon(Icons.location_on_rounded,
                                      size: 130,
                                      color: Colors.white
                                          .withValues(alpha: 0.1)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(context.rs(18)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      Icon(Icons.storefront_rounded,
                                          size: 24, color: Colors.white),
                                      SizedBox(height: context.rs(8)),
                                      Text(
                                        state.branch!.name(lang),
                                        style: TextStyle(
                                            fontSize: context.rf(17),
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white),
                                      ),
                                      SizedBox(height: context.rs(2)),
                                      Text(
                                        'Hassan Jameel • Toyota & Lexus',
                                        style: TextStyle(
                                            fontSize: context.rf(10),
                                            letterSpacing: 0.6,
                                            color: Colors.white
                                                .withValues(alpha: 0.75)),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.rs(14)),
                      // "افتح في خرائط Google" — outlined red, arrow at end.
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(
                              color:
                                  scheme.primary.withValues(alpha: 0.7)),
                          foregroundColor: scheme.primary,
                          textStyle: TextStyle(
                              fontSize: context.rf(13),
                              fontWeight: FontWeight.w800),
                        ),
                        onPressed: () => launchUrl(state.branch!.mapsUri(),
                            mode: LaunchMode.externalApplication),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map_outlined, size: 18),
                            SizedBox(width: context.rs(8)),
                            Text(t.contactOpenMaps),
                            SizedBox(width: context.rs(8)),
                            Icon(
                              Directionality.of(context) ==
                                      TextDirection.rtl
                                  ? Icons.arrow_back_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: context.rs(16)),

                    // Info cards — soft white rows: texts + action + tinted
                    // icon circle on the end, like the reference.
                    for (final row
                        in state.page.infoFor(state.branch?.branchId))
                      if (row.value(lang).isNotEmpty)
                        Builder(builder: (context) {
                          final icon = _iconFor(row.title('en'));
                          final isPhone = icon == Icons.phone_outlined;
                          final isMail = icon == Icons.mail_outline_rounded;
                          final value = row.value(lang);
                          void act() {
                            if (isPhone) {
                              launchUrl(Uri.parse(
                                  'tel:${value.replaceAll(RegExp(r'[^0-9+]'), '')}'));
                            } else if (isMail) {
                              launchUrl(Uri.parse('mailto:$value'));
                            } else if (state.branch != null) {
                              launchUrl(state.branch!.mapsUri(),
                                  mode: LaunchMode.externalApplication);
                            }
                          }

                          return Padding(
                            padding:
                                EdgeInsets.only(bottom: context.rs(10)),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: act,
                                child: Ink(
                                  padding: EdgeInsets.all(context.rs(14)),
                                  decoration: softCardDecoration(context,
                                      radius: 18),
                                  child: Row(children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(row.title(lang),
                                              style: TextStyle(
                                                  fontSize:
                                                      context.rf(10),
                                                  color: scheme.onSurface
                                                      .withValues(
                                                          alpha: 0.5))),
                                          SizedBox(
                                              height: context.rs(3)),
                                          Text(value,
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              textDirection: value
                                                          .startsWith(
                                                              '+') ||
                                                      value.startsWith(
                                                          'http') ||
                                                      isPhone ||
                                                      isMail
                                                  ? TextDirection.ltr
                                                  : null,
                                              style: TextStyle(
                                                  fontSize:
                                                      context.rf(13.5),
                                                  fontWeight:
                                                      FontWeight.w800)),
                                        ],
                                      ),
                                    ),
                                    if (isPhone) ...[
                                      SizedBox(width: context.rs(8)),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      11)),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: context.rs(14),
                                              vertical: context.rs(8)),
                                          minimumSize: Size.zero,
                                          textStyle: TextStyle(
                                              fontSize: context.rf(10.5),
                                              fontWeight:
                                                  FontWeight.w800),
                                        ),
                                        onPressed: act,
                                        child: Text(t.contactCallNow),
                                      ),
                                    ],
                                    SizedBox(width: context.rs(11)),
                                    Container(
                                      width: context.rs(42),
                                      height: context.rs(42),
                                      decoration: BoxDecoration(
                                        color: scheme.primary
                                            .withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(icon,
                                          size: 18,
                                          color: scheme.primary),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                          );
                        }),

                    // ── الشكاوى — submit + tracker sheets (website's
                    // contact-page complaints cycle). ──
                    SizedBox(height: context.rs(8)),
                    const ComplaintsSection(),

                    SizedBox(height: context.rs(18)),
                    Text(t.contactFormTitle,
                        style: TextStyle(
                            fontSize: context.rf(16),
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: context.rs(12)),

                    if (state.phase == _SendPhase.done)
                      Container(
                        padding: EdgeInsets.all(context.rs(16)),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          Icon(Icons.check_circle_rounded,
                              color: scheme.primary),
                          SizedBox(width: context.rs(10)),
                          Expanded(child: Text(t.contactSent)),
                        ]),
                      )
                    else ...[
                      if (state.page.subjects.isNotEmpty) ...[
                        AppDropdown<int>(
                          label: t.contactSubject,
                          value: state.subjectId,
                          items: [
                            for (final s in state.page.subjects)
                              AppDropdownItem(
                                  value: s.id, label: s.name(lang)),
                          ],
                          onChanged: cubit.selectSubject,
                        ),
                        SizedBox(height: context.rs(12)),
                      ],
                      TextField(
                        controller: cubit.name,
                        decoration: InputDecoration(
                          labelText: t.formFullName,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      SizedBox(height: context.rs(12)),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: cubit.phone,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: t.formPhone,
                              prefixText: '+966 ',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ]),
                      SizedBox(height: context.rs(12)),
                      TextField(
                        controller: cubit.email,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: t.formEmailOptional,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      SizedBox(height: context.rs(12)),
                      TextField(
                        controller: cubit.message,
                        maxLines: 4,
                        maxLength: 4000,
                        decoration: InputDecoration(
                          labelText: t.contactMessage,
                          counterText: '',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      SizedBox(height: context.rs(14)),
                      if (state.phase == _SendPhase.failed || state.error)
                        Padding(
                          padding: EdgeInsets.only(bottom: context.rs(10)),
                          child: Text(
                            state.error
                                ? t.formCheckFields
                                : t.offersSubmitFailed,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: scheme.error,
                                fontSize: context.rf(12)),
                          ),
                        ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: const StadiumBorder(),
                            textStyle: TextStyle(
                                fontSize: context.rf(14),
                                fontWeight: FontWeight.w800)),
                        onPressed: state.phase == _SendPhase.busy
                            ? null
                            : cubit.send,
                        child: state.phase == _SendPhase.busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4))
                            : Text(t.commonSubmit),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  static IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('mail')) return Icons.mail_outline_rounded;
    if (l.contains('whats')) return Icons.chat_outlined;
    if (l.contains('phone') || l.contains('mobile') || l.contains('رقم')) {
      return Icons.phone_outlined;
    }
    if (l.contains('address') || l.contains('location') || l.contains('showroom')) {
      return Icons.location_on_outlined;
    }
    if (l.contains('fax')) return Icons.print_outlined;
    return Icons.info_outline_rounded;
  }
}

/* ─────────── Header location icon → branches quick sheet ─────────── */

/// The header's location pin: lists the branches (from the contact cycle) —
/// tap one to open it in Google Maps.
void showBranchesSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => FutureBuilder<ContactPage>(
      future: ContentRepository(sl<ApiClient>()).contact(),
      builder: (context, snap) {
        final t = AppLocalizations.of(context);
        final scheme = Theme.of(context).colorScheme;
        final lang = sl<LocaleCubit>().state.languageCode;
        final branches = snap.data?.branches ?? const <ContactBranch>[];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: SheetHandle()),
              const SizedBox(height: 12),
              Text(t.contactBranches,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (snap.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (branches.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(child: Text(t.homeErrorRetry)),
                )
              else
                for (final b in branches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => launchUrl(b.mapsUri(),
                            mode: LaunchMode.externalApplication),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    scheme.outline.withValues(alpha: 0.6)),
                          ),
                          child: Row(children: [
                            Icon(Icons.location_on_rounded,
                                color: scheme.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(b.name(lang),
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700)),
                            ),
                            Icon(Icons.open_in_new_rounded,
                                size: 16,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.4)),
                          ]),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    ),
  );
}
