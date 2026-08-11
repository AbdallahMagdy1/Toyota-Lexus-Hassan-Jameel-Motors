import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di/injector.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/navigation/sheet_routes.dart';
import '../../shared/widgets/app_dropdown.dart';
import '../auth/bloc/auth_bloc.dart';
import '../settings/bloc/locale_cubit.dart';
import 'complaint_tracker_sheet.dart';
import 'complaints_models.dart';
import 'complaints_repository.dart';

/// Opens the "تقديم شكوى" sheet; when the success view's follow-up button
/// is tapped the sheet pops with 'track' and the tracker opens in place.
Future<void> showComplaintSubmitSheet(BuildContext context) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (_) => const FractionallySizedBox(
        heightFactor: 0.92, child: _SubmitSheetBody()),
  );
  if (result == 'track' && context.mounted) {
    await showComplaintTrackerSheet(context);
  }
}

enum _Phase { idle, busy, done, failed }

/// Client-side complaint types — same constant as the website's form.
const _complaintTypes = ['Sales', 'SpareParts', 'Maintenance', 'Other'];

const int _maxPhotos = 6;
const int _maxBytes = 4 * 1024 * 1024; // 4 MB per photo

final class _SubmitSheetBody extends StatefulWidget {
  const _SubmitSheetBody();

  @override
  State<_SubmitSheetBody> createState() => _SubmitSheetBodyState();
}

final class _SubmitSheetBodyState extends State<_SubmitSheetBody> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();

  String? _type;
  final List<ComplaintAttachmentDraft> _photos = [];
  bool _consent = false;
  bool _fieldError = false;
  _Phase _phase = _Phase.idle;
  String _reference = '';

  @override
  void initState() {
    super.initState();
    final user = sl<AuthBloc>().state.user;
    final lang = sl<LocaleCubit>().state.languageCode;
    _name.text = user?.displayName(lang) ?? '';
    _phone.text = user?.phone ?? '';
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _subject, _body]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _mimeFor(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' || 'heif' => 'image/heic',
      'bmp' => 'image/bmp',
      _ => 'image/jpeg',
    };
  }

  Future<void> _pickPhotos() async {
    final t = AppLocalizations.of(context);
    final picked =
        await ImagePicker().pickMultiImage(imageQuality: 70, maxWidth: 1600);
    if (picked.isEmpty || !mounted) return;
    var oversize = false;
    for (final x in picked) {
      if (_photos.length >= _maxPhotos) break;
      final bytes = await x.readAsBytes();
      if (bytes.length > _maxBytes) {
        oversize = true;
        continue;
      }
      final name = x.name.isEmpty ? 'photo_${_photos.length}.jpg' : x.name;
      _photos.add(ComplaintAttachmentDraft(
          fileName: name, mime: _mimeFor(name), bytes: bytes));
    }
    if (!mounted) return;
    setState(() {});
    if (oversize) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.cmpAttachHint)));
    }
  }

  Future<void> _submit() async {
    final phone = ComplaintsRepository.normalizePhone(_phone.text);
    final valid = _type != null &&
        _name.text.trim().isNotEmpty &&
        phone.length == 9 &&
        _body.text.trim().isNotEmpty;
    if (!valid) {
      setState(() => _fieldError = true);
      return;
    }
    setState(() {
      _phase = _Phase.busy;
      _fieldError = false;
    });
    final user = sl<AuthBloc>().state.user;
    final (ok, reference) = await ComplaintsRepository(sl<ApiClient>()).submit(
      webUserId: user?.userId,
      customerName: _name.text.trim(),
      phone: phone,
      email: _email.text.trim(),
      complaintType: _type!,
      subject: _subject.text.trim(),
      body: _body.text.trim(),
      attachments: _photos,
    );
    if (!mounted) return;
    setState(() {
      _phase = ok ? _Phase.done : _Phase.failed;
      _reference = reference ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(children: [
        const SheetHandle(),
        Padding(
          padding: EdgeInsets.fromLTRB(
              context.rs(20), context.rs(6), context.rs(20), 0),
          child: Row(children: [
            Expanded(
              child: Text(t.cmpSubmit,
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
        Expanded(
          child: _phase == _Phase.done ? _successView(t) : _formView(t),
        ),
      ]),
    );
  }

  Widget _successView(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(24), context.rs(30), context.rs(24), context.rs(24)),
      children: [
        Center(
          child: Container(
            width: context.rs(88),
            height: context.rs(88),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded,
                size: context.rs(52), color: scheme.primary),
          ).animate().scale(
              duration: 380.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.6, 0.6)),
        ),
        SizedBox(height: context.rs(18)),
        Text(t.cmpSent,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: context.rf(18), fontWeight: FontWeight.w800)),
        if (_reference.isNotEmpty) ...[
          SizedBox(height: context.rs(12)),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(16), vertical: context.rs(9)),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: scheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${t.cmpRef}: ',
                    style: TextStyle(
                        fontSize: context.rf(12),
                        color: scheme.onSurface.withValues(alpha: 0.6))),
                Text(_reference,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        fontSize: context.rf(14),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: scheme.primary)),
              ]),
            ),
          ),
        ],
        SizedBox(height: context.rs(26)),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: const StadiumBorder(),
            textStyle: TextStyle(
                fontSize: context.rf(14), fontWeight: FontWeight.w800),
          ),
          onPressed: () => Navigator.of(context).pop('track'),
          icon: const Icon(Icons.fact_check_outlined, size: 18),
          label: Text(t.cmpTrack),
        ),
      ],
    ).animate().fadeIn(duration: 240.ms);
  }

  Widget _formView(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    final busy = _phase == _Phase.busy;
    final typeLabels = {
      'Sales': t.cmpTypeSales,
      'SpareParts': t.cmpTypeParts,
      'Maintenance': t.cmpTypeMaintenance,
      'Other': t.cmpTypeOther,
    };
    const typeIcons = {
      'Sales': Icons.directions_car_filled_outlined,
      'SpareParts': Icons.settings_suggest_outlined,
      'Maintenance': Icons.build_outlined,
      'Other': Icons.more_horiz_rounded,
    };

    InputDecoration deco(String label, {String? hint}) => InputDecoration(
          labelText: label,
          hintText: hint,
          counterText: '',
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        );

    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.rs(20), context.rs(8), context.rs(20), context.rs(24)),
      children: [
        Text(t.cmpSubmitSub,
            style: TextStyle(
                fontSize: context.rf(11.5),
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.55))),
        SizedBox(height: context.rs(16)),
        AppDropdown<String>(
          label: t.cmpType,
          value: _type,
          hint: t.cmpType,
          items: [
            for (final v in _complaintTypes)
              AppDropdownItem(
                  value: v, label: typeLabels[v]!, icon: typeIcons[v]),
          ],
          onChanged: (v) => setState(() => _type = v),
        ),
        SizedBox(height: context.rs(12)),
        TextField(controller: _name, decoration: deco(t.cmpName)),
        SizedBox(height: context.rs(12)),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          decoration: deco(t.cmpPhone).copyWith(prefixText: '+966 '),
        ),
        SizedBox(height: context.rs(12)),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: deco(t.cmpEmail),
        ),
        SizedBox(height: context.rs(12)),
        TextField(controller: _subject, decoration: deco(t.cmpSubject)),
        SizedBox(height: context.rs(12)),
        TextField(
          controller: _body,
          maxLines: 5,
          maxLength: 4000,
          decoration: deco(t.cmpBody, hint: t.cmpBodyHint),
        ),
        SizedBox(height: context.rs(16)),

        // ── Photo attachments — grid of thumbnails + an add tile ──
        Text(t.cmpAttach,
            style: TextStyle(
                fontSize: context.rf(12),
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.65))),
        SizedBox(height: context.rs(8)),
        Wrap(
          spacing: context.rs(8),
          runSpacing: context.rs(8),
          children: [
            for (final (i, p) in _photos.indexed)
              SizedBox(
                width: context.rs(72),
                height: context.rs(72),
                child: Stack(children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(p.bytes, fit: BoxFit.cover),
                    ),
                  ),
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: busy
                          ? null
                          : () => setState(() => _photos.removeAt(i)),
                      // Generous hit area around the small visual badge.
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            if (_photos.length < _maxPhotos)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: busy ? null : _pickPhotos,
                  child: Ink(
                    width: context.rs(72),
                    height: context.rs(72),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.35)),
                    ),
                    child: Icon(Icons.add_photo_alternate_outlined,
                        size: 22, color: scheme.primary),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: context.rs(6)),
        Text(t.cmpAttachHint,
            style: TextStyle(
                fontSize: context.rf(10),
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.45))),
        SizedBox(height: context.rs(14)),

        // ── Consent gate ──
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: busy ? null : () => setState(() => _consent = !_consent),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.rs(6)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Checkbox(
                value: _consent,
                visualDensity: VisualDensity.compact,
                onChanged: busy
                    ? null
                    : (v) => setState(() => _consent = v ?? false),
              ),
              Expanded(
                child: Text(t.cmpConsent,
                    style: TextStyle(
                        fontSize: context.rf(11.5),
                        height: 1.5,
                        color: scheme.onSurface.withValues(alpha: 0.75))),
              ),
            ]),
          ),
        ),
        SizedBox(height: context.rs(10)),
        if (_fieldError || _phase == _Phase.failed)
          Padding(
            padding: EdgeInsets.only(bottom: context.rs(10)),
            child: Text(
              _fieldError ? t.formCheckFields : t.offersSubmitFailed,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: scheme.error, fontSize: context.rf(12)),
            ),
          ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: const StadiumBorder(),
            textStyle: TextStyle(
                fontSize: context.rf(14), fontWeight: FontWeight.w800),
          ),
          onPressed: !_consent || busy ? null : _submit,
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4))
              : Text(t.cmpSend),
        ),
      ],
    ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.02, duration: 240.ms);
  }
}
