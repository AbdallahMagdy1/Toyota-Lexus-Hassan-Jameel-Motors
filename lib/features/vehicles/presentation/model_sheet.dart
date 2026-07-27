import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../home/domain/home_models.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../bloc/model_sheet_cubit.dart';
import '../domain/vehicle_models.dart';
import 'widgets/color_arc_picker.dart';

/// Opens the model detail sheet — the website vehicle page as a bottom
/// sheet: Overview / Gallery / Specs / Features / Comparison.
Future<void> openModelSheet(BuildContext context, SliderVehicle vehicle) {
  return showHeroBottomSheet(
    context,
    builder: (_) => BlocProvider(
      create: (_) => ModelSheetCubit(sl(), vehicle),
      child: ModelSheet(vehicle: vehicle),
    ),
  );
}

final class ModelSheet extends StatelessWidget {
  const ModelSheet({super.key, required this.vehicle});

  final SliderVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ModelSheetCubit>();
    final state = context.watch<ModelSheetCubit>().state;
    final scheme = Theme.of(context).colorScheme;

    final tabs = [t.tabOverview, t.tabGallery, t.tabSpecs, t.tabFeatures, t.tabComparison];

    return Column(
      children: [
        const SheetHandle(),
        // Website-style pill tab bar (selected = filled primary).
        SizedBox(
          height: context.rs(44),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
                horizontal: context.rs(16), vertical: context.rs(5)),
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, _) => SizedBox(width: context.rs(8)),
            itemBuilder: (context, i) {
              final selected = i == state.tab;
              return GestureDetector(
                onTap: () => cubit.setTab(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: context.rf(12.5),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? scheme.onPrimary
                          : scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (state.tab) {
              0 => _OverviewTab(key: const ValueKey(0), vehicle: vehicle),
              1 => _GalleryTab(key: const ValueKey(1)),
              2 => _SpecsTab(key: const ValueKey(2), vehicle: vehicle),
              3 => _FeaturesTab(key: const ValueKey(3)),
              _ => _ComparisonTab(key: const ValueKey(4)),
            },
          ),
        ),
      ],
    );
  }
}

/* ───────────────────────────── Overview ───────────────────────────── */

final class _OverviewTab extends StatelessWidget {
  const _OverviewTab({super.key, required this.vehicle});

  final SliderVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ModelSheetCubit>();
    final state = context.watch<ModelSheetCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    final description =
        (state.detail ?? vehicle).description(lang);
    final image = state.imageFor(vehicle.image(lang));

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: context.rs(24)),
      children: [
        SizedBox(height: context.rs(10)),
        // Eyebrow: BRAND · YEAR — like the website "TOYOTA · 2026".
        Text(
          '${vehicle.brandEn.toUpperCase()} · ${vehicle.year ?? ''}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.rf(11),
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: scheme.primary,
          ),
        ),
        SizedBox(height: context.rs(6)),
        // Huge model name.
        Text(
          vehicle.name(lang),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.rf(40),
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        if (description.isNotEmpty) ...[
          SizedBox(height: context.rs(10)),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.rf(12.5),
              height: 1.6,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
        SizedBox(height: context.rs(10)),
        // Car image — swaps with the selected color.
        Hero(
          tag: 'model-${vehicle.slug}',
          child: SizedBox(
            height: context.rs(190),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOut,
              child: HomeImage(
                key: ValueKey(image),
                url: image,
                fit: BoxFit.contain,
                logicalWidth: MediaQuery.sizeOf(context).width,
              ),
            ),
          ),
        ),
        // The dashed-arc mover — cycles COLORS instead of rotating the car.
        if (state.colors.isNotEmpty) ...[
          SizedBox(height: context.rs(4)),
          ColorArcPicker(
            colors: state.colors,
            index: state.colorIndex,
            onSelect: cubit.setColorIndex,
          ),
          SizedBox(height: context.rs(6)),
          Text(
            state.color?.name(lang) ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.rf(11.5),
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ] else if (state.loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        // Price line.
        if (vehicle.minPrice != null) ...[
          SizedBox(height: context.rs(14)),
          Center(
            child: Column(
              children: [
                Text(
                  t.homeFrom,
                  style: TextStyle(
                    fontSize: context.rf(10.5),
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                PriceText(
                  price: vehicle.minPrice,
                  currency: t.currency,
                  contactForPrice: t.homeContactForPrice,
                  fontSize: context.rf(20),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: context.rs(30)),
      ],
    ).animate().fadeIn(duration: 240.ms);
  }
}

/* ───────────────────────────── Gallery ───────────────────────────── */

final class _GalleryTab extends StatelessWidget {
  const _GalleryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<ModelSheetCubit>().state;
    if (state.loading) return const Center(child: CircularProgressIndicator());
    final items =
        state.gallery.where((g) => (g.image ?? '').isNotEmpty).toList();
    if (items.isEmpty) return _Empty(text: t.modelsNoData);

    return GridView.builder(
      padding: EdgeInsets.all(context.rs(16)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: context.rs(10),
        crossAxisSpacing: context.rs(10),
        childAspectRatio: 1.25,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: HomeImage(url: items[i].image, logicalWidth: 300),
        ).animate(delay: (30 * (i % 8)).ms).fadeIn(duration: 250.ms),
      ),
    );
  }
}

/* ───────────────────────────── Specs ───────────────────────────── */

final class _SpecsTab extends StatelessWidget {
  const _SpecsTab({super.key, required this.vehicle});

  final SliderVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<ModelSheetCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    if (state.loading) return const Center(child: CircularProgressIndicator());

    final d = state.detail ?? vehicle;
    final stats = <(String, String)>[
      if (d.year != null) (t.specYear, d.year!),
      if (d.hp != null) (t.specHp, '${d.hp!.round()}'),
      if (d.cylinders != null) (t.specCylinders, '${d.cylinders}'),
      if (d.seatsNumber != null) (t.specSeats, '${d.seatsNumber}'),
      if (d.petrol != null && d.petrol!.isNotEmpty) (t.specFuel, d.petrol!),
    ];

    return ListView(
      padding: EdgeInsets.all(context.rs(20)),
      children: [
        // Stat tiles.
        Wrap(
          spacing: context.rs(10),
          runSpacing: context.rs(10),
          children: [
            for (final s in stats)
              Container(
                width: (MediaQuery.sizeOf(context).width - context.rs(60)) / 2,
                padding: EdgeInsets.all(context.rs(14)),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.$2,
                        style: TextStyle(
                            fontSize: context.rf(18),
                            fontWeight: FontWeight.w800)),
                    Text(
                      s.$1,
                      style: TextStyle(
                        fontSize: context.rf(10.5),
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (state.trims.isNotEmpty) ...[
          SizedBox(height: context.rs(22)),
          Text(t.modelsTrims,
              style:
                  TextStyle(fontSize: context.rf(16), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(10)),
          for (final trim in state.trims)
            Container(
              margin: EdgeInsets.only(bottom: context.rs(8)),
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(14), vertical: context.rs(12)),
              decoration: BoxDecoration(
                border:
                    Border.all(color: scheme.outline.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      trim.name(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.rf(12.5),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(width: context.rs(8)),
                  PriceText(
                    price: trim.minPrice,
                    currency: t.currency,
                    contactForPrice: t.homeContactForPrice,
                    fontSize: context.rf(13),
                  ),
                ],
              ),
            ),
        ],
        if (stats.isEmpty && state.trims.isEmpty) _Empty(text: t.modelsNoData),
      ],
    ).animate().fadeIn(duration: 240.ms);
  }
}

/* ───────────────────────────── Features ───────────────────────────── */

final class _FeaturesTab extends StatelessWidget {
  const _FeaturesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<ModelSheetCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.features.isEmpty) return _Empty(text: t.modelsNoData);

    return ListView.builder(
      padding: EdgeInsets.all(context.rs(16)),
      itemCount: state.features.length,
      itemBuilder: (context, i) {
        final f = state.features[i];
        return RepaintBoundary(
          child: Container(
            margin: EdgeInsets.only(bottom: context.rs(12)),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((f.image ?? '').isNotEmpty)
                  HomeImage(url: f.image, aspectRatio: 16 / 8, logicalWidth: 400),
                Padding(
                  padding: EdgeInsets.all(context.rs(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.title(lang),
                          style: TextStyle(
                              fontSize: context.rf(14),
                              fontWeight: FontWeight.w800)),
                      if (f.description(lang).isNotEmpty) ...[
                        SizedBox(height: context.rs(4)),
                        Text(
                          f.description(lang),
                          style: TextStyle(
                            fontSize: context.rf(12),
                            height: 1.5,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: (40 * (i % 6)).ms).fadeIn(duration: 260.ms).slideY(
              begin: 0.04, end: 0, duration: 260.ms, curve: Curves.easeOut),
        );
      },
    );
  }
}

/* ─────────────────────────── Comparison ─────────────────────────── */

final class _ComparisonTab extends StatelessWidget {
  const _ComparisonTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ModelSheetCubit>();
    final state = context.watch<ModelSheetCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.trims.length < 2 || state.equipments.isEmpty) {
      return _Empty(text: t.modelsNoData);
    }

    final a = state.trims[state.trimA.clamp(0, state.trims.length - 1)];
    final b = state.trims[state.trimB.clamp(0, state.trims.length - 1)];

    List<String> equipFor(VehicleTrim trim, String section) => state.equipments
        .where((e) => e.trimSlug == trim.slug && e.section(lang) == section)
        .map((e) => e.description(lang))
        .where((s) => s.isNotEmpty)
        .toList();

    final sections = <String>[];
    for (final e in state.equipments) {
      final s = e.section(lang);
      if (s.isNotEmpty && !sections.contains(s)) sections.add(s);
    }

    Widget trimPicker(int value, ValueChanged<int> onChanged) => Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: value.clamp(0, state.trims.length - 1),
            isExpanded: true,
            style: TextStyle(fontSize: context.rf(11.5), color: scheme.onSurface),
            items: [
              for (var i = 0; i < state.trims.length; i++)
                DropdownMenuItem(
                    value: i,
                    child: Text(state.trims[i].name(lang),
                        overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => onChanged(v ?? 0),
          ),
        );

    return ListView(
      padding: EdgeInsets.all(context.rs(16)),
      children: [
        Row(children: [
          trimPicker(state.trimA, cubit.setTrimA),
          SizedBox(width: context.rs(10)),
          trimPicker(state.trimB, cubit.setTrimB),
        ]),
        SizedBox(height: context.rs(8)),
        Row(children: [
          Expanded(
              child: PriceText(
                  price: a.minPrice,
                  currency: t.currency,
                  contactForPrice: t.homeContactForPrice,
                  fontSize: context.rf(13))),
          SizedBox(width: context.rs(10)),
          Expanded(
              child: PriceText(
                  price: b.minPrice,
                  currency: t.currency,
                  contactForPrice: t.homeContactForPrice,
                  fontSize: context.rf(13))),
        ]),
        SizedBox(height: context.rs(12)),
        for (final section in sections) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: context.rs(12), vertical: context.rs(8)),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              section,
              style: TextStyle(
                  fontSize: context.rf(11.5),
                  fontWeight: FontWeight.w800,
                  color: scheme.primary),
            ),
          ),
          SizedBox(height: context.rs(8)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _EquipList(items: equipFor(a, section))),
              SizedBox(width: context.rs(10)),
              Expanded(child: _EquipList(items: equipFor(b, section))),
            ],
          ),
          SizedBox(height: context.rs(14)),
        ],
      ],
    ).animate().fadeIn(duration: 240.ms);
  }
}

final class _EquipList extends StatelessWidget {
  const _EquipList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return Text('—',
          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.35)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in items)
          Padding(
            padding: EdgeInsets.only(bottom: context.rs(5)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_rounded, size: 12, color: scheme.primary),
                SizedBox(width: context.rs(5)),
                Expanded(
                  child: Text(s,
                      style:
                          TextStyle(fontSize: context.rf(10.5), height: 1.4)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

final class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
      ),
    );
  }
}
