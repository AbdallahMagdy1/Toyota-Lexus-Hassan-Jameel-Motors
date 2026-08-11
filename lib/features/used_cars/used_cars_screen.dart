import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/injector.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/navigation/sheet_routes.dart' show SheetHandle;
import '../../shared/widgets/app_header.dart';
import '../auth/bloc/auth_bloc.dart';
import '../home/presentation/widgets/home_bits.dart';
import '../settings/bloc/locale_cubit.dart';
import '../settings/bloc/theme_cubit.dart';
import 'used_cars_models.dart';
import 'used_cars_repository.dart';

const _kGreen = Color(0xFF16A34A);

/// سيارات مستعملة موثوقة — the website's /used-cars cycle, mobile-native:
/// approved listings grid → full detail sheet (gallery, specs, features,
/// the full inspection, WhatsApp) + the "اعرض سيارتك" submission wizard.
final class UsedCarsScreen extends StatefulWidget {
  const UsedCarsScreen({super.key});

  @override
  State<UsedCarsScreen> createState() => _UsedCarsScreenState();
}

final class _UsedCarsScreenState extends State<UsedCarsScreen> {
  late Future<List<UsedCarItem>> _future;
  late String _lastBrand;

  /// Website behavior: the active brand theme scopes the feed.
  String get _brand => sl<ThemeCubit>().state.brandKey;

  @override
  void initState() {
    super.initState();
    _lastBrand = _brand;
    _future = UsedCarsRepository(sl<ApiClient>()).list(brand: _brand);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = sl<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    // Refetch when the brand switch flips while this screen is open.
    if (_brand != _lastBrand) {
      _lastBrand = _brand;
      _future = UsedCarsRepository(sl<ApiClient>()).list(brand: _brand);
    }

    return Column(children: [
      const AppHeader(),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _future =
                UsedCarsRepository(sl<ApiClient>()).list(brand: _brand));
            await _future;
          },
          child: FutureBuilder<List<UsedCarItem>>(
            future: _future,
            builder: (context, snap) {
              final cars = snap.data ?? const <UsedCarItem>[];
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(context.rs(16), context.rs(18),
                    context.rs(16), context.rs(140)),
                children: [
                  Text(t.ucTitle,
                      style: TextStyle(
                          fontSize: context.rf(24),
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: context.rs(4)),
                  Text(t.ucSubtitle,
                      style: TextStyle(
                          fontSize: context.rf(12),
                          height: 1.5,
                          color: scheme.onSurface.withValues(alpha: 0.55))),
                  SizedBox(height: context.rs(14)),
                  // "اعرض سيارتك" — the website's red CTA.
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: const StadiumBorder(),
                      textStyle: TextStyle(
                          fontSize: context.rf(13.5),
                          fontWeight: FontWeight.w800),
                    ),
                    onPressed: () => showSellCarWizard(context),
                    icon: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        size: 17),
                    label: Text(t.ucSellCta),
                  ),
                  SizedBox(height: context.rs(16)),
                  if (snap.connectionState != ConnectionState.done)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (cars.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(context.rs(36)),
                      child: Center(child: Text(t.ucEmpty)),
                    )
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: context.rs(12),
                      crossAxisSpacing: context.rs(12),
                      childAspectRatio: 0.74,
                      children: [
                        for (final (i, c) in cars.indexed)
                          _CarCard(car: c, lang: lang)
                              .animate(delay: (30 * (i % 6)).ms)
                              .fadeIn(duration: 220.ms),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ]);
  }
}

final class _CarCard extends StatelessWidget {
  const _CarCard({required this.car, required this.lang});

  final UsedCarItem car;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return HomeCard(
      onTap: () => _showUsedCarDetail(context, car.guid, lang),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(fit: StackFit.expand, children: [
                ColoredBox(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFEDF1F7),
                  child: HomeImage(
                      url: car.coverImage,
                      fit: BoxFit.cover,
                      logicalWidth: 220),
                ),
                if (car.carYear != null)
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: _pill(context, '${car.carYear}',
                        bg: Colors.black.withValues(alpha: 0.55),
                        fg: Colors.white),
                  ),
                if (car.hjInspected)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: _pill(context, t.ucInspected,
                        bg: _kGreen, fg: Colors.white, icon: true),
                  ),
              ]),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.rs(11)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car.title(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: context.rf(12.5),
                        fontWeight: FontWeight.w800)),
                SizedBox(height: context.rs(4)),
                Row(children: [
                  Expanded(
                    child: (car.price ?? 0) > 0
                        ? PriceText(
                            price: car.price,
                            currency: '',
                            contactForPrice: '',
                            fontSize: context.rf(12.5))
                        : Text(t.ucPriceOnContact,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: context.rf(10.5),
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.6))),
                  ),
                  if (car.mileage != null)
                    Text('${formatPrice(car.mileage!.toDouble())} ${t.ucKm}',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                            fontSize: context.rf(9.5),
                            color:
                                scheme.onSurface.withValues(alpha: 0.5))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String text,
      {required Color bg, required Color fg, bool icon = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.rs(7), vertical: context.rs(3)),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon) ...[
          Icon(Icons.verified_rounded, size: 10, color: fg),
          SizedBox(width: context.rs(3)),
        ],
        Text(text,
            style: TextStyle(
                fontSize: context.rf(8), fontWeight: FontWeight.w800, color: fg)),
      ]),
    );
  }
}

/* ─────────────────────────── Detail sheet ─────────────────────────── */

void _showUsedCarDetail(BuildContext context, String guid, String lang) {
  showModalBottomSheet<void>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scroll) =>
          _UsedCarDetailBody(guid: guid, lang: lang, scroll: scroll),
    ),
  );
}

final class _UsedCarDetailBody extends StatefulWidget {
  const _UsedCarDetailBody(
      {required this.guid, required this.lang, required this.scroll});

  final String guid;
  final String lang;
  final ScrollController scroll;

  @override
  State<_UsedCarDetailBody> createState() => _UsedCarDetailBodyState();
}

final class _UsedCarDetailBodyState extends State<_UsedCarDetailBody> {
  late Future<UsedCarDetail?> _future;
  int _img = 0;
  int _cat = 0;

  @override
  void initState() {
    super.initState();
    _future = UsedCarsRepository(sl<ApiClient>()).detail(widget.guid);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = widget.lang;

    return FutureBuilder<UsedCarDetail?>(
      future: _future,
      builder: (context, snap) {
        final d = snap.data;
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (d == null) return Center(child: Text(t.homeErrorRetry));

        Widget spec(String label, String? value) => value == null ||
                value.trim().isEmpty
            ? const SizedBox.shrink()
            : Container(
                padding: EdgeInsets.all(context.rs(11)),
                decoration: softCardDecoration(context, radius: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: context.rf(9.5),
                            color:
                                scheme.onSurface.withValues(alpha: 0.5))),
                    SizedBox(height: context.rs(2)),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.rf(12),
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              );

        final specs = <(String, String?)>[
          (t.ucYear, d.carYear?.toString()),
          (
            t.ucMileage,
            d.mileage == null
                ? null
                : '${formatPrice(d.mileage!.toDouble())} ${t.ucKm}'
          ),
          (t.ucFuel, d.fuelType),
          (t.ucGearbox, d.gearbox),
          (t.ucDrive, d.driveType),
          (t.ucCondition, d.condition),
          (t.ucSeats, d.seats?.toString()),
          (t.ucDoors, d.doors?.toString()),
        ].where((s) => (s.$2 ?? '').trim().isNotEmpty).toList();

        final featureGroups = <(String, List<UsedCarFeature>)>[
          (t.ucSafety, d.featuresSafety),
          (t.ucComfort, d.featuresComfort),
          (t.ucTech, d.featuresTech),
          (t.ucExterior, d.featuresExterior),
        ].where((g) => g.$2.isNotEmpty).toList();

        return ListView(
          controller: widget.scroll,
          padding: EdgeInsets.only(bottom: context.rs(30)),
          children: [
            // ── Gallery ──
            Stack(children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: context.rs(230),
                  child: d.images.isEmpty
                      ? ColoredBox(
                          color: scheme.onSurface.withValues(alpha: 0.05),
                          child: Icon(Icons.directions_car_outlined,
                              size: 48,
                              color:
                                  scheme.onSurface.withValues(alpha: 0.2)),
                        )
                      : PageView(
                          onPageChanged: (i) => setState(() => _img = i),
                          children: [
                            for (final u in d.images)
                              HomeImage(
                                  url: u,
                                  fit: BoxFit.cover,
                                  logicalWidth: 480),
                          ],
                        ),
                ),
              ),
              const Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(child: SheetHandle()),
              ),
              if (d.hjInspected)
                PositionedDirectional(
                  top: 16,
                  end: 14,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(10), vertical: context.rs(5)),
                    decoration: BoxDecoration(
                        color: _kGreen,
                        borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.verified_rounded,
                          size: 12, color: Colors.white),
                      SizedBox(width: context.rs(4)),
                      Text(t.ucInspected,
                          style: TextStyle(
                              fontSize: context.rf(9.5),
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ]),
                  ),
                ),
            ]),
            if (d.images.length > 1)
              Padding(
                padding: EdgeInsets.only(top: context.rs(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < d.images.length; i++)
                      Container(
                        width: i == _img ? 16 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i == _img
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                  ],
                ),
              ),

            Padding(
              padding: EdgeInsets.all(context.rs(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${d.title()} ${d.carYear ?? ''}'.trim(),
                      style: TextStyle(
                          fontSize: context.rf(19),
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: context.rs(4)),
                  (d.price ?? 0) > 0
                      ? PriceText(
                          price: d.price,
                          currency: '',
                          contactForPrice: '',
                          fontSize: context.rf(17))
                      : Text(t.ucPriceOnContact,
                          style: TextStyle(
                              fontSize: context.rf(14),
                              fontWeight: FontWeight.w800,
                              color:
                                  scheme.onSurface.withValues(alpha: 0.6))),
                  SizedBox(height: context.rs(14)),

                  // ── Specs tiles (the website's grid) ──
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: context.rs(8),
                    crossAxisSpacing: context.rs(8),
                    childAspectRatio: 3.1,
                    children: [for (final s in specs) spec(s.$1, s.$2)],
                  ),
                  SizedBox(height: context.rs(14)),

                  // ── WhatsApp CTA (green, like the website) ──
                  if ((d.ownerPhone ?? '').isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _kGreen,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: TextStyle(
                            fontSize: context.rf(13.5),
                            fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => _whatsapp(d.ownerPhone!),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: Text(t.ucWhatsapp),
                    ),
                  SizedBox(height: context.rs(16)),

                  // ── معلومات السيارة ──
                  Text(t.ucCarInfo,
                      style: TextStyle(
                          fontSize: context.rf(15),
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: context.rs(10)),
                  Container(
                    padding: EdgeInsets.all(context.rs(14)),
                    decoration: softCardDecoration(context, radius: 16),
                    child: Column(children: [
                      for (final (label, value) in <(String, String?)>[
                        (t.ucExtColor, d.exteriorColor),
                        (t.ucIntColor, d.interiorColor),
                        (t.ucOrigin, d.origin),
                        (t.ucLicenseDuration, d.licenseDuration),
                      ])
                        if ((value ?? '').trim().isNotEmpty)
                          Padding(
                            padding:
                                EdgeInsets.only(bottom: context.rs(8)),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(label,
                                    style: TextStyle(
                                        fontSize: context.rf(11.5),
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.55))),
                                Text(value!,
                                    style: TextStyle(
                                        fontSize: context.rf(12.5),
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                      if ((d.notes ?? '').trim().isNotEmpty)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(d.notes!,
                              style: TextStyle(
                                  fontSize: context.rf(11.5),
                                  height: 1.6,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.7))),
                        ),
                    ]),
                  ),

                  // ── Features (الأمان / الراحة / تقنيات / تجهيزات) ──
                  for (final (title, feats) in featureGroups) ...[
                    SizedBox(height: context.rs(14)),
                    Text(title,
                        style: TextStyle(
                            fontSize: context.rf(14),
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: context.rs(8)),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final f in feats)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: context.rs(10),
                              vertical: context.rs(5)),
                          decoration: BoxDecoration(
                            color:
                                scheme.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(f.name(lang),
                              style: TextStyle(
                                  fontSize: context.rf(10.5),
                                  fontWeight: FontWeight.w600)),
                        ),
                    ]),
                  ],

                  // ── فحص السيارة الشامل ──
                  if (d.inspection.isNotEmpty) ...[
                    SizedBox(height: context.rs(18)),
                    Container(
                      padding: EdgeInsets.all(context.rs(16)),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.verified_user_rounded,
                                size: 18, color: scheme.primary),
                            SizedBox(width: context.rs(7)),
                            Text(t.ucInspectionTitle,
                                style: TextStyle(
                                    fontSize: context.rf(15),
                                    fontWeight: FontWeight.w800)),
                          ]),
                          SizedBox(height: context.rs(3)),
                          Text(t.ucInspectionSub,
                              style: TextStyle(
                                  fontSize: context.rf(11),
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.55))),
                          SizedBox(height: context.rs(12)),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: [
                              for (final (i, c) in d.inspection.indexed)
                                Padding(
                                  padding: EdgeInsetsDirectional.only(
                                      end: context.rs(6)),
                                  child: ChoiceChip(
                                    label: Text(c.name(lang),
                                        style: TextStyle(
                                            fontSize: context.rf(10.5))),
                                    selected: i == _cat,
                                    onSelected: (_) =>
                                        setState(() => _cat = i),
                                  ),
                                ),
                            ]),
                          ),
                          SizedBox(height: context.rs(10)),
                          for (final item in (d.inspection
                                      .elementAtOrNull(_cat)
                                      ?.items ??
                                  const <UsedCarInspItem>[]))
                            Padding(
                              padding:
                                  EdgeInsets.only(bottom: context.rs(8)),
                              child: Row(children: [
                                Icon(
                                  item.ok
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  size: 16,
                                  color:
                                      item.ok ? _kGreen : scheme.error,
                                ),
                                SizedBox(width: context.rs(8)),
                                Expanded(
                                  child: Text(
                                    [
                                      item.name(lang),
                                      if ((item.note ?? '')
                                          .trim()
                                          .isNotEmpty)
                                        '(${item.note})',
                                    ].join(' '),
                                    style: TextStyle(
                                        fontSize: context.rf(11.5),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _whatsapp(String phone) {
    var d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0')) d = d.substring(1);
    if (d.startsWith('5')) d = '966$d';
    launchUrl(Uri.parse('https://wa.me/$d'),
        mode: LaunchMode.externalApplication);
  }
}

/* ─────────────────────── "اعرض سيارتك" wizard ─────────────────────── */

void showSellCarWizard(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    // Root navigator so the sheet covers the shell's bottom-nav overlay.
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const FractionallySizedBox(
        heightFactor: 0.92, child: _SellCarWizard()),
  );
}

final class _SellCarWizard extends StatefulWidget {
  const _SellCarWizard();

  @override
  State<_SellCarWizard> createState() => _SellCarWizardState();
}

final class _SellCarWizardState extends State<_SellCarWizard> {
  int _step = 0; // 0..5
  bool _busy = false;
  bool _done = false;
  bool _error = false;
  bool _reqInspection = true;

  final _fields = <String, TextEditingController>{};
  final List<XFile> _photos = [];

  TextEditingController _c(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    final user = sl<AuthBloc>().state.user;
    final lang = sl<LocaleCubit>().state.languageCode;
    _c('ownerName').text = user?.displayName(lang) ?? '';
    _c('ownerPhone').text = user?.phone ?? '';
    _c('ownerEmail').text = user?.email ?? '';
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _stepValid => switch (_step) {
        0 => _c('ownerName').text.trim().isNotEmpty &&
            _c('ownerPhone').text.trim().isNotEmpty,
        1 => _c('carName').text.trim().isNotEmpty &&
            _c('carYear').text.trim().isNotEmpty,
        _ => true,
      };

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker()
        .pickMultiImage(imageQuality: 70, maxWidth: 1600);
    if (picked.isEmpty || !mounted) return;
    setState(() => _photos.addAll(picked));
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = false;
    });
    String? s(String key) {
      final v = _c(key).text.trim();
      return v.isEmpty ? null : v;
    }

    int? n(String key) => int.tryParse(_c(key).text.trim());

    final images = <Map<String, dynamic>>[];
    for (final (i, x) in _photos.indexed) {
      final bytes = await x.readAsBytes();
      final name = x.name.isEmpty ? 'photo_$i.jpg' : x.name;
      images.add({
        'slot': 'photo_$i',
        'fileName': name,
        'type': name.contains('.') ? name.split('.').last : 'jpg',
        'base64': base64Encode(bytes),
      });
    }

    final (ok, _) = await UsedCarsRepository(sl<ApiClient>()).submit({
      'ownerName': s('ownerName'),
      'ownerPhone': s('ownerPhone'),
      'ownerEmail': s('ownerEmail'),
      'brand': s('brand'),
      'bodyType': s('bodyType'),
      'carName': s('carName'),
      'modelName': s('modelName'),
      'carYear': n('carYear'),
      'fuelType': s('fuelType'),
      'condition': s('condition'),
      'driveType': s('driveType'),
      'seats': n('seats'),
      'doors': n('doors'),
      'exteriorColor': s('extColor'),
      'interiorColor': s('intColor'),
      'origin': s('origin'),
      'gearbox': s('gearbox'),
      'mileage': n('mileage'),
      'price': double.tryParse(_c('price').text.trim()),
      'chassisNumber': s('chassis'),
      'licenseNumber': s('licenseNo'),
      'licenseDuration': s('licenseDuration'),
      'licenseExpiry': s('licenseExpiry'),
      'notes': s('notes'),
      'selfInspected': false,
      'requestHjInspection': _reqInspection,
      'images': images,
      'inspection': const [],
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = ok;
      _error = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (_done) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_rounded, size: 54, color: scheme.primary),
            const SizedBox(height: 14),
            Text(t.ucSubmitted,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14.5, height: 1.6, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder()),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.commonDone),
            ),
          ],
        ),
      );
    }

    final titles = [
      t.ucStepOwner,
      t.ucStepCar,
      t.ucStepSpecs,
      t.ucStepLicense,
      t.ucStepPhotos,
      t.ucStepReview,
    ];

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );

    Widget field(String key, String label,
            {TextInputType? type, int lines = 1}) =>
        Padding(
          padding: EdgeInsets.only(bottom: context.rs(11)),
          child: TextField(
            controller: _c(key),
            keyboardType: type,
            maxLines: lines,
            onChanged: (_) => setState(() {}),
            decoration: deco(label),
          ),
        );

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.rs(20), context.rs(10), context.rs(20), 0),
            child: Column(children: [
              const SheetHandle(),
              SizedBox(height: context.rs(12)),
              Text(t.ucAddTitle,
                  style: TextStyle(
                      fontSize: context.rf(18), fontWeight: FontWeight.w800)),
              SizedBox(height: context.rs(12)),
              // Numbered 1..6 progress, like the website's stepper.
              Row(children: [
                for (var i = 0; i < 6; i++) ...[
                  Container(
                    width: context.rs(24),
                    height: context.rs(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= _step
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.08),
                    ),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: context.rf(10),
                            fontWeight: FontWeight.w800,
                            color: i <= _step
                                ? scheme.onPrimary
                                : scheme.onSurface
                                    .withValues(alpha: 0.5))),
                  ),
                  if (i < 5)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i < _step
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.12),
                      ),
                    ),
                ],
              ]),
              SizedBox(height: context.rs(6)),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(titles[_step],
                    style: TextStyle(
                        fontSize: context.rf(12),
                        fontWeight: FontWeight.w800,
                        color: scheme.primary)),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  context.rs(20), context.rs(12), context.rs(20), context.rs(10)),
              children: switch (_step) {
                0 => [
                    field('ownerName', '${t.formFullName} *'),
                    field('ownerPhone', '${t.formPhone} *',
                        type: TextInputType.phone),
                    field('ownerEmail', t.formEmailOptional,
                        type: TextInputType.emailAddress),
                  ],
                1 => [
                    field('brand', t.ucBrand),
                    field('carName', '${t.ucCarName} *'),
                    field('modelName', t.ucModelName),
                    field('carYear', '${t.ucYear} *',
                        type: TextInputType.number),
                    field('bodyType', t.ucBodyType),
                    field('mileage', t.ucMileage,
                        type: TextInputType.number),
                    field('price', t.ucPrice,
                        type: TextInputType.number),
                  ],
                2 => [
                    field('fuelType', t.ucFuel),
                    field('gearbox', t.ucGearbox),
                    field('driveType', t.ucDrive),
                    field('condition', t.ucCondition),
                    field('seats', t.ucSeats, type: TextInputType.number),
                    field('doors', t.ucDoors, type: TextInputType.number),
                    field('extColor', t.ucExtColor),
                    field('intColor', t.ucIntColor),
                    field('origin', t.ucOrigin),
                  ],
                3 => [
                    field('chassis', t.ucChassis),
                    field('licenseNo', t.ucLicenseNo),
                    field('licenseDuration', t.ucLicenseDuration),
                    field('licenseExpiry', t.ucLicenseExpiry),
                    field('notes', t.ucNotes, lines: 3),
                    SwitchListTile(
                      value: _reqInspection,
                      onChanged: (v) => setState(() => _reqInspection = v),
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.ucReqInspection,
                          style: TextStyle(
                              fontSize: context.rf(12.5),
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                4 => [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(
                            color: scheme.primary.withValues(alpha: 0.7)),
                        foregroundColor: scheme.primary,
                      ),
                      onPressed: _pickPhotos,
                      icon: const Icon(Icons.add_photo_alternate_outlined,
                          size: 19),
                      label: Text(t.ucAddPhotos),
                    ),
                    SizedBox(height: context.rs(12)),
                    if (_photos.isNotEmpty)
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final (i, x) in _photos.indexed)
                          Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(x.path),
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 84,
                                  height: 84,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.06),
                                  child: const Icon(Icons.image_outlined),
                                ),
                              ),
                            ),
                            PositionedDirectional(
                              top: 2,
                              end: 2,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _photos.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                      color: Colors.black
                                          .withValues(alpha: 0.55),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ]),
                      ]),
                  ],
                _ => [
                    Container(
                      padding: EdgeInsets.all(context.rs(14)),
                      decoration: softCardDecoration(context, radius: 16),
                      child: Column(children: [
                        for (final (label, key) in <(String, String)>[
                          (t.formFullName, 'ownerName'),
                          (t.formPhone, 'ownerPhone'),
                          (t.ucCarName, 'carName'),
                          (t.ucYear, 'carYear'),
                          (t.ucMileage, 'mileage'),
                          (t.ucPrice, 'price'),
                        ])
                          if (_c(key).text.trim().isNotEmpty)
                            Padding(
                              padding:
                                  EdgeInsets.only(bottom: context.rs(7)),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(label,
                                      style: TextStyle(
                                          fontSize: context.rf(11),
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.55))),
                                  Text(_c(key).text.trim(),
                                      style: TextStyle(
                                          fontSize: context.rf(12),
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(t.ucStepPhotos,
                                style: TextStyle(
                                    fontSize: context.rf(11),
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.55))),
                            Text('${_photos.length}',
                                style: TextStyle(
                                    fontSize: context.rf(12),
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ]),
                    ),
                    if (_error)
                      Padding(
                        padding: EdgeInsets.only(top: context.rs(10)),
                        child: Text(t.offersSubmitFailed,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: scheme.error,
                                fontSize: context.rf(12))),
                      ),
                  ],
              },
            ),
          ),
          // Nav bar — big red CTA + back link, like the booking sheet.
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.rs(20), context.rs(6), context.rs(20), context.rs(12)),
            child: Row(children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 52),
                    shape: const StadiumBorder(),
                    textStyle: TextStyle(
                        fontSize: context.rf(14), fontWeight: FontWeight.w800),
                  ),
                  onPressed: _busy || !_stepValid
                      ? null
                      : _step < 5
                          ? () => setState(() => _step++)
                          : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4))
                      : Text(_step < 5 ? t.mbNext : t.ucSubmit),
                ),
              ),
              if (_step > 0) ...[
                SizedBox(width: context.rs(14)),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _step--),
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onSurface.withValues(alpha: 0.75),
                    textStyle: TextStyle(
                        fontSize: context.rf(13.5),
                        fontWeight: FontWeight.w800),
                  ),
                  child: Text(t.mbBack),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
