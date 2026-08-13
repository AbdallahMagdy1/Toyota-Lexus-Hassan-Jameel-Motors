import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart' show SheetHandle;
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_states.dart';
import '../../account/data/account_repository.dart';
import '../../account/domain/account_models.dart';
import '../../account/presentation/garage_sheets.dart' show showAddCarSheet;
import '../../auth/bloc/auth_bloc.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/protection_cubit.dart';
import '../data/protection_repository.dart';
import '../domain/protection_models.dart';
import 'protection_detail_sheet.dart';

/// Protection & shading — the website's "Protection & polishing" with the
/// reference layout: selected-car card + my-cars pills, tier package rows
/// (popular badge, price, select CTA), the "why us" grid and a sticky
/// book-now bar.
final class ProtectionScreen extends StatelessWidget {
  const ProtectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    return BlocProvider(
      key: ValueKey('protection-$brandKey'),
      create: (_) => ProtectionCubit(
        ProtectionRepository(sl<ApiClient>()),
        brandDbId: brandKey == 'lexus' ? '2' : '1',
      ),
      child: const _ProtectionView(),
    );
  }
}

final class _ProtectionView extends StatelessWidget {
  const _ProtectionView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<ProtectionCubit>().state;
    final cubit = context.read<ProtectionCubit>();

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: switch (state.status) {
            ProtectionStatus.loading => SkeletonList(
                itemCount: 4,
                itemHeight: context.rs(120),
              ),
            ProtectionStatus.error => AppErrorState(
                title: t.stateErrorTitle,
                message: t.stateErrorBody,
                retryLabel: t.stateRetry,
                onRetry: cubit.load,
              ),
            ProtectionStatus.ready => const _Body(),
          },
        ),
      ],
    );
  }
}

final class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<ProtectionCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    final result = state.result;

    return Stack(children: [
      ListView(
        padding: EdgeInsets.only(bottom: context.rs(210)),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.rs(20), context.rs(18), context.rs(20), 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.protTitle,
                    style: TextStyle(
                        fontSize: context.rf(19),
                        fontWeight: FontWeight.w800)),
                SizedBox(height: context.rs(4)),
                Text(t.protSubtitle,
                    style: TextStyle(
                        fontSize: context.rf(12),
                        height: 1.5,
                        color: scheme.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          ),

          // ── Selected car card + my-cars / add-car pills (garage users);
          //    dropdown picker for everyone else. ──
          const _CarPicker(),

          // ── Packages ──
          if (state.servicesLoading)
            SkeletonList(itemCount: 3, itemHeight: context.rs(120))
          else if (result == null)
            Padding(
              padding: EdgeInsets.all(context.rs(36)),
              child: Column(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 42,
                      color: scheme.primary.withValues(alpha: 0.4)),
                  SizedBox(height: context.rs(10)),
                  Text(t.protPickToStart,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: context.rf(13),
                          fontWeight: FontWeight.w700)),
                ],
              ),
            )
          else if (result.services.isEmpty)
            Padding(
              padding: EdgeInsets.all(context.rs(36)),
              child: Center(child: Text(t.protNoPackages)),
            )
          else ...[
            SectionHeader(title: t.homeProtForCar),
            _PackagesList(
              // Key resets the selection when the catalog changes.
              key: ValueKey(
                  'pkgs-${result.services.length}-${result.services.firstOrNull?.id}'),
              services: result.services,
              lang: lang,
              onBook: (svc) => _book(context, svc),
            ),
          ],

          // ── "لماذا تختار خدماتنا؟" ──
          SizedBox(height: context.rs(8)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
            child: Text(t.protWhyTitle,
                style: TextStyle(
                    fontSize: context.rf(15), fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.rs(20), context.rs(14), context.rs(20), 0),
            child: Column(children: [
              for (final row in [
                [
                  (Icons.wb_sunny_outlined, t.protWhyUv, t.protWhyUvSub),
                  (Icons.water_drop_outlined, t.protWhyWater,
                      t.protWhyWaterSub),
                ],
                [
                  (Icons.construction_rounded, t.protWhyInstall,
                      t.protWhyInstallSub),
                  (Icons.workspace_premium_outlined, t.protWhyWarranty,
                      t.protWhyWarrantySub),
                ],
              ])
                Padding(
                  padding: EdgeInsets.only(bottom: context.rs(18)),
                  child: Row(children: [
                    for (final (icon, title, sub) in row)
                      Expanded(
                        child: Column(children: [
                          Icon(icon, size: 22, color: scheme.primary),
                          SizedBox(height: context.rs(7)),
                          Text(title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: context.rf(12.5),
                                  fontWeight: FontWeight.w800)),
                          SizedBox(height: context.rs(2)),
                          Text(sub,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: context.rf(10),
                                  height: 1.4,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.55))),
                        ]),
                      ),
                  ]),
                ),
            ]),
          ),
        ],
      ),

    ]);
  }

  static void _book(BuildContext context, ProtectionPackage svc) {
    final cubit = context.read<ProtectionCubit>();
    final lang = sl<LocaleCubit>().state.languageCode;
    final model = cubit.state.selectedModel;
    // Detail sheet (price breakdown + sections) → website payment cycle.
    showProtectionDetailSheet(
      context,
      package: svc,
      vehicleLabel: model == null
          ? null
          : '${model.name(lang)} ${model.year ?? ''}'.trim(),
    );
  }
}

/// Selected-car card (photo + red "selected" label + plate + swap) with the
/// "سياراتي (N)" and "إضافة سيارة" pills — falls back to the group/model
/// dropdowns for guests or when the user wants another model.
final class _CarPicker extends StatefulWidget {
  const _CarPicker();

  @override
  State<_CarPicker> createState() => _CarPickerState();
}

final class _CarPickerState extends State<_CarPicker> {
  Future<List<GarageCar>>? _future;
  bool _manualOpen = false;
  bool _autoSelected = false;

  void _reload(int userId) {
    _future = AccountRepository(sl<ApiClient>()).garage(userId);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = context.select((AuthBloc b) => b.state.user);
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<ProtectionCubit>();
    final selectedType =
        context.select((ProtectionCubit c) => c.state.modelId);

    if (user == null) return const _ManualPicker();
    final wantedDbId = brandKey == 'lexus' ? '2' : '1';
    _future ??= AccountRepository(sl<ApiClient>()).garage(user.userId);

    return FutureBuilder<List<GarageCar>>(
      future: _future,
      builder: (context, snap) {
        final cars = (snap.data ?? const <GarageCar>[])
            .where((c) =>
                c.brandDbId == wantedDbId && (c.type ?? '').isNotEmpty)
            .toList();
        if (snap.connectionState == ConnectionState.done && cars.isEmpty) {
          return const _ManualPicker();
        }
        if (cars.isEmpty) return const SizedBox.shrink();

        // Resolve the catalog for the first car automatically.
        if (!_autoSelected && selectedType == null) {
          _autoSelected = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) cubit.selectByProductType(cars.first.type!);
          });
        }
        final selected = cars
                .where((c) => c.type == selectedType)
                .firstOrNull ??
            cars.first;
        final plate = selected.plate(lang).isNotEmpty
            ? selected.plate(lang)
            : (selected.vin ?? '');

        return Padding(
          padding: EdgeInsets.fromLTRB(
              context.rs(16), context.rs(16), context.rs(16), 0),
          child: Column(children: [
            // Selected car card — label + name + plate | photo | swap.
            Container(
              padding: EdgeInsets.all(context.rs(14)),
              decoration: softCardDecoration(context, radius: 20),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 13, color: scheme.primary),
                        SizedBox(width: context.rs(4)),
                        Text(t.protSelectedCar,
                            style: TextStyle(
                                fontSize: context.rf(10),
                                fontWeight: FontWeight.w800,
                                color: scheme.primary)),
                      ]),
                      SizedBox(height: context.rs(5)),
                      Text(
                        '${selected.displayName(lang)} ${selected.year ?? ''}'
                            .trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: context.rf(14.5),
                            fontWeight: FontWeight.w800),
                      ),
                      if (plate.isNotEmpty) ...[
                        SizedBox(height: context.rs(2)),
                        Text('${t.protPlate}: $plate',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: context.rf(10.5),
                                color: scheme.onSurface
                                    .withValues(alpha: 0.55))),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: context.rs(96),
                  height: context.rs(58),
                  child: HomeImage(
                      url: selected.image,
                      fit: BoxFit.contain,
                      logicalWidth: 96),
                ),
                if (cars.length > 1)
                  IconButton(
                    onPressed: () => _pickCar(context, cars, selected, lang),
                    icon: Icon(Icons.swap_horiz_rounded,
                        size: 22, color: scheme.primary),
                  ),
              ]),
            ),
            SizedBox(height: context.rs(10)),

            // Pills: سياراتي (N) + إضافة سيارة.
            Row(children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _pickCar(context, cars, selected, lang),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.rs(14), vertical: context.rs(9)),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.directions_car_rounded,
                        size: 15, color: scheme.primary),
                    SizedBox(width: context.rs(6)),
                    Text('${t.protMyCars} (${cars.length})',
                        style: TextStyle(
                            fontSize: context.rf(11.5),
                            fontWeight: FontWeight.w800,
                            color: scheme.primary)),
                  ]),
                ),
              ),
              SizedBox(width: context.rs(8)),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => showAddCarSheet(context, onAdded: () {
                  setState(() => _reload(user.userId));
                }),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.rs(14), vertical: context.rs(9)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.6)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_circle_outline_rounded,
                        size: 15,
                        color: scheme.onSurface.withValues(alpha: 0.65)),
                    SizedBox(width: context.rs(6)),
                    Text(t.acAddCarShort,
                        style: TextStyle(
                            fontSize: context.rf(11.5),
                            fontWeight: FontWeight.w700,
                            color:
                                scheme.onSurface.withValues(alpha: 0.7))),
                  ]),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _manualOpen = !_manualOpen),
                child: Text(t.protOtherModel,
                    style: TextStyle(
                        fontSize: context.rf(10.5),
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            if (_manualOpen) ...[
              SizedBox(height: context.rs(6)),
              const _ManualPicker(padded: false),
            ],
          ]),
        );
      },
    );
  }

  void _pickCar(BuildContext context, List<GarageCar> cars,
      GarageCar selected, String lang) {
    final cubit = context.read<ProtectionCubit>();
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      // Root navigator so the sheet covers the shell's bottom-nav overlay.
      useRootNavigator: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            const SizedBox(height: 10),
            for (final c in cars)
              ListTile(
                onTap: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  cubit.selectByProductType(c.type!);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.directions_car_rounded,
                      size: 18, color: scheme.primary),
                ),
                title: Text(
                    '${c.displayName(lang)} ${c.year ?? ''}'.trim(),
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700)),
                trailing: c.type == selected.type
                    ? Icon(Icons.check_circle_rounded,
                        size: 20, color: scheme.primary)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

/// The group → model dropdown card (guest fallback / another model).
final class _ManualPicker extends StatelessWidget {
  const _ManualPicker({this.padded = true});

  final bool padded;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<ProtectionCubit>().state;
    final cubit = context.read<ProtectionCubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final models = state.modelOptions();

    return Padding(
      padding: padded
          ? EdgeInsets.fromLTRB(
              context.rs(16), context.rs(16), context.rs(16), 0)
          : EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.all(context.rs(14)),
        decoration: softCardDecoration(context),
        child: Column(
          children: [
            AppDropdown<String>(
              label: t.homeSelectCar,
              value: state.groupId,
              items: [
                for (final g in state.groups)
                  AppDropdownItem(value: g.id ?? '', label: g.name(lang)),
              ],
              onChanged: cubit.selectGroup,
            ),
            SizedBox(height: context.rs(12)),
            AppDropdown<String>(
              label: t.homeSelectModel,
              value: state.modelId,
              enabled: state.groupId != null,
              items: [
                for (final m in models)
                  AppDropdownItem(
                    value: m.id ?? '',
                    label: '${m.name(lang)} ${m.year ?? ''}'.trim(),
                  ),
              ],
              onChanged: cubit.selectModel,
            ),
          ],
        ),
      ),
    );
  }
}

/// Package row — the reference card: tinted icon square + name + popular
/// badge, description, then the select CTA and the big red price.
/// The selectable packages list: tap a card to SELECT it (brand ring +
/// check + expanded description); "اختيار" on the selected card proceeds
/// to the detail/booking sheet. Each card repaints independently.
final class _PackagesList extends StatefulWidget {
  const _PackagesList({
    super.key,
    required this.services,
    required this.lang,
    required this.onBook,
  });

  final List<ProtectionPackage> services;
  final String lang;
  final void Function(ProtectionPackage) onBook;

  @override
  State<_PackagesList> createState() => _PackagesListState();
}

final class _PackagesListState extends State<_PackagesList> {
  int _selected = 0; // the popular (first) package leads by default

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (final (i, svc) in widget.services.indexed)
        Padding(
          padding: EdgeInsets.fromLTRB(
              context.rs(16), 0, context.rs(16), context.rs(12)),
          child: RepaintBoundary(
            child: _PackageCard(
              package: svc,
              lang: widget.lang,
              index: i,
              popular: i == 0,
              selected: i == _selected,
              onSelect: () => setState(() => _selected = i),
              onBook: () => widget.onBook(svc),
            ),
          ).animate(delay: (35 * (i % 5)).ms).fadeIn(duration: 220.ms),
        ),
    ]);
  }
}

final class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.lang,
    required this.index,
    required this.popular,
    required this.selected,
    required this.onSelect,
    required this.onBook,
  });

  final ProtectionPackage package;
  final String lang;
  final int index;
  final bool popular;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Tier palette from the package NAME (gold/silver/bronze/diamond) —
    // the card wash, icon tile, badge and CTA all follow it.
    final tier = packageTierColors(package.name(lang), scheme);
    final accent = isDark ? tier.color : tier.deep;
    final (tileBg, tileFg) = (
      tier.color.withValues(alpha: isDark ? 0.28 : 0.16),
      accent,
    );
    final icon = switch (index % 3) {
      0 => Icons.layers_rounded,
      1 => Icons.shield_outlined,
      _ => Icons.auto_awesome_rounded,
    };

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(context.rs(15)),
          decoration: BoxDecoration(
            color: selected
                ? tier.color.withValues(alpha: isDark ? 0.12 : 0.07)
                : (isDark ? const Color(0xFF181B21) : scheme.surface),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? tier.color
                  : scheme.outline.withValues(alpha: isDark ? 0.5 : 0.45),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.rs(44),
                    height: context.rs(44),
                    decoration: BoxDecoration(
                      color: tileBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 20, color: tileFg),
                  ),
                  SizedBox(width: context.rs(12)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: context.rs(3)),
                      child: Text(package.name(lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: context.rf(13.5),
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              color: selected ? accent : scheme.onSurface)),
                    ),
                  ),
                  SizedBox(width: context.rs(8)),
                  // Selected check, or the popular badge on the lead card.
                  if (selected)
                    Container(
                      width: context.rs(22),
                      height: context.rs(22),
                      decoration: BoxDecoration(
                        color: tier.color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white),
                    )
                  else if (popular)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.rs(9),
                          vertical: context.rs(4)),
                      decoration: BoxDecoration(
                        color: tier.color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(t.protPopular,
                          style: TextStyle(
                              fontSize: context.rf(8.5),
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                ],
              ),
              if (package.description(lang).isNotEmpty) ...[
                SizedBox(height: context.rs(10)),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    package.description(lang),
                    maxLines: selected ? 6 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: context.rf(11.5),
                        height: 1.55,
                        color: scheme.onSurface.withValues(alpha: 0.65)),
                  ),
                ),
              ],
              SizedBox(height: context.rs(13)),
              Row(children: [
                selected
                    ? FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: tier.color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(
                              horizontal: context.rs(20),
                              vertical: context.rs(10)),
                          minimumSize: Size.zero,
                          textStyle: TextStyle(
                              fontSize: context.rf(12),
                              fontWeight: FontWeight.w800),
                        ),
                        onPressed: onBook,
                        icon: const Icon(Icons.arrow_forward_rounded,
                            size: 15),
                        label: Text(t.protChoose),
                      )
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(
                              horizontal: context.rs(22),
                              vertical: context.rs(10)),
                          minimumSize: Size.zero,
                          side: BorderSide(
                              color: tier.color.withValues(alpha: 0.7)),
                          foregroundColor: accent,
                          textStyle: TextStyle(
                              fontSize: context.rf(12),
                              fontWeight: FontWeight.w800),
                        ),
                        onPressed: onSelect,
                        child: Text(t.protChoose),
                      ),
                const Spacer(),
                PriceText(
                    price: package.price,
                    currency: '',
                    contactForPrice: t.homeContactForPrice,
                    fontSize: context.rf(17),
                    color: accent),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
