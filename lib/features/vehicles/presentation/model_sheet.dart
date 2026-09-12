import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/navigation/sheet_routes.dart';
import '../../home/domain/home_models.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/slope_hero.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../online_store/bloc/method_form_cubits.dart'
    show ContactFormCubit;
import '../../online_store/data/online_store_repository.dart';
import '../../online_store/presentation/widgets/method_forms.dart'
    show ContactForm;
import '../../settings/bloc/locale_cubit.dart';
import '../bloc/model_sheet_cubit.dart';
import '../domain/specs_matrix.dart';
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

/// Callback-request form for models NOT sold in the online store — hosts
/// the store's existing ContactForm (same cubit, same submit cycle) over a
/// vehicle record built from the catalog model.
Future<void> _openModelCallbackForm(
    BuildContext context, SliderVehicle v) async {
  final repo = sl<OnlineStoreRepository>();
  final settings = await repo.formSettings();
  if (!context.mounted) return;
  final lang = sl<LocaleCubit>().state.languageCode;
  final vehicle = OnlineVehicle(
    slug: v.slug,
    year: v.year,
    brandEn: v.brandEn,
    groupEn: v.groupEn,
    groupAr: v.groupAr,
    minPrice: v.minPrice,
    image: v.image(lang),
    brandId: v.brandId,
    carGroupId: v.carGroupId,
    type: v.type,
    showPrice: v.showPrice,
  );
  if (!context.mounted) return;
  final t = AppLocalizations.of(context);
  await showAppModalSheet<void>(
    context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetCtx) => BlocProvider(
      create: (_) => ContactFormCubit(repo, vehicle, settings,
          lang: lang, user: sl<AuthBloc>().state.user),
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetCtx).height * 0.82,
        child: Column(children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Column(children: [
              Text(t.methodContactTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                '${v.name(lang)} ${v.year ?? ''}'.trim(),
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(sheetCtx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ]),
          ),
          Expanded(
            child: ContactForm(
              onSuccess: (reference) {
                Navigator.of(sheetCtx, rootNavigator: true).pop();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                      SnackBar(content: Text(t.offersSubmitted)));
              },
            ),
          ),
        ]),
      ),
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
        // Website-style pill tab bar — equal-width pills that always fit the
        // sheet, so the last tab (المقارنة) is never cut off the edge.
        Padding(
          padding: EdgeInsets.fromLTRB(
              context.rs(12), context.rs(5), context.rs(12), context.rs(5)),
          child: SizedBox(
            height: context.rs(36),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++) ...[
                  if (i > 0) SizedBox(width: context.rs(4)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => cubit.setTab(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == state.tab
                              ? scheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: context.rs(6)),
                            child: Text(
                              tabs[i],
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: context.rf(12),
                                fontWeight: i == state.tab
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: i == state.tab
                                    ? scheme.onPrimary
                                    : scheme.onSurface
                                        .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
      padding: EdgeInsets.zero,
      children: [
        // ── Reference-mock header: curved slope blob (car_bg match → model
        // shared Background → brand gradient) with the eyebrow + model name
        // on it; the color-following car image overlaps its bottom curve. ──
        SlopeHero(
          eyebrow: '${vehicle.brandEn.toUpperCase()} · ${vehicle.year ?? ''}',
          title: vehicle.name(lang),
          modelKey: vehicle.groupEn,
          year: vehicle.year,
          background: (state.detail ?? vehicle).background(lang) ??
              vehicle.background(lang),
          slopeHeight: 230,
          // Car image — KEEPS the color-swap wiring (state.imageFor).
          car: Hero(
            tag: 'model-${vehicle.slug}',
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
        SizedBox(height: context.rs(8)),
        _overviewBody(context, t, cubit, state, lang, scheme, description),
      ],
    ).animate().fadeIn(duration: 240.ms);
  }

  /// Everything under the overlapping car — unchanged content, reflowed.
  Widget _overviewBody(
    BuildContext context,
    AppLocalizations t,
    ModelSheetCubit cubit,
    ModelSheetState state,
    String lang,
    ColorScheme scheme,
    String description,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rs(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
        if (description.isNotEmpty) ...[
          SizedBox(height: context.rs(12)),
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
        // الفئات المتوفرة — selecting a trim reloads its color palette.
        if (state.trims.isNotEmpty) ...[
          SizedBox(height: context.rs(22)),
          Padding(
            padding: EdgeInsetsDirectional.only(start: context.rs(2)),
            child: Text(
              t.modelsAvailableTrims,
              style: TextStyle(
                  fontSize: context.rf(16), fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(height: context.rs(10)),
          SizedBox(
            height: context.rs(148),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: state.trims.length,
              separatorBuilder: (_, _) => SizedBox(width: context.rs(10)),
              itemBuilder: (context, i) {
                final trim = state.trims[i];
                final selected = i == state.trimIndex;
                return GestureDetector(
                  onTap: () => cubit.selectTrim(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: context.rs(172),
                    padding: EdgeInsets.all(context.rs(13)),
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.07)
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? scheme.primary
                            : scheme.outline.withValues(alpha: 0.4),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                trim.name(lang),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.rf(12.5),
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? scheme.primary
                                      : scheme.onSurface,
                                ),
                              ),
                            ),
                            if (selected)
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    size: 13, color: Colors.white),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          t.homeFrom,
                          style: TextStyle(
                            fontSize: context.rf(9.5),
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        PriceText(
                          price: trim.minPrice,
                          currency: t.currency,
                          contactForPrice: t.homeContactForPrice,
                          fontSize: context.rf(15),
                        ),
                        SizedBox(height: context.rs(8)),
                        Container(
                          width: double.infinity,
                          padding:
                              EdgeInsets.symmetric(vertical: context.rs(6)),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? scheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? scheme.primary
                                  : scheme.outline.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Text(
                            selected ? t.modelsChosen : t.modelsChooseTrim,
                            style: TextStyle(
                              fontSize: context.rf(10.5),
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? scheme.onPrimary
                                  : scheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        // Models NOT sold in the online store: the callback request is
        // their purchase path — prominent CTA opening the store's form.
        if (!vehicle.buyOnline) ...[
          SizedBox(height: context.rs(20)),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: const StadiumBorder(),
            ),
            onPressed: () => _openModelCallbackForm(context, vehicle),
            icon: const Icon(Icons.support_agent_rounded, size: 18),
            label: Text(t.methodContactTitle),
          ),
        ],
        SizedBox(height: context.rs(30)),
        ],
      ),
    );
  }
}

/* ───────────────────────────── Gallery ───────────────────────────── */

final class _GalleryTab extends StatelessWidget {
  const _GalleryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<ModelSheetCubit>().state;
    if (state.loading) {
      return const SkeletonGrid(itemCount: 4, aspectRatio: 1.25);
    }
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
    final scheme = Theme.of(context).colorScheme;
    if (state.loading) {
      return SkeletonList(itemCount: 4, itemHeight: context.rs(64));
    }

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
        // Per-trim specification matrix (website buildSpecsMatrix).
        if (state.equipments.isNotEmpty && state.trims.isNotEmpty) ...[
          SizedBox(height: context.rs(22)),
          Text(t.modelsSpecsFor,
              style: TextStyle(
                  fontSize: context.rf(16), fontWeight: FontWeight.w800)),
          SizedBox(height: context.rs(10)),
          const _SpecsMatrixView(),
        ],
        if (stats.isEmpty && state.trims.isEmpty) _Empty(text: t.modelsNoData),
      ],
    ).animate().fadeIn(duration: 240.ms);
  }
}

/// Trim chips + one-trim spec sections, from the shared matrix transform.
final class _SpecsMatrixView extends StatefulWidget {
  const _SpecsMatrixView();

  @override
  State<_SpecsMatrixView> createState() => _SpecsMatrixViewState();
}

final class _SpecsMatrixViewState extends State<_SpecsMatrixView> {
  int _trim = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ModelSheetCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    final trims = trimsInMatrix(state.trims, state.equipments);
    if (trims.isEmpty) return const SizedBox.shrink();
    final trim = trims[_trim.clamp(0, trims.length - 1)];
    final sections = buildSpecsMatrix(
        state.equipments.where((e) => e.trimSlug == trim.slug).toList(), lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: context.rs(36),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: trims.length,
            separatorBuilder: (_, _) => SizedBox(width: context.rs(7)),
            itemBuilder: (context, i) {
              final selected = i == _trim;
              return GestureDetector(
                onTap: () => setState(() => _trim = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      EdgeInsets.symmetric(horizontal: context.rs(14)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? scheme.primary
                          : scheme.outline.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Text(
                    trims[i].name(lang),
                    style: TextStyle(
                      fontSize: context.rf(11),
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? scheme.onPrimary
                          : scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: context.rs(12)),
        for (final section in sections) ...[
          _SectionHeader(title: section.title),
          SizedBox(height: context.rs(6)),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (var i = 0; i < section.rows.length; i++)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(13),
                        vertical: context.rs(9)),
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : Border(
                              top: BorderSide(
                                  color: scheme.outline
                                      .withValues(alpha: 0.25))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            section.rows[i].label,
                            style: TextStyle(
                                fontSize: context.rf(11.5), height: 1.4),
                          ),
                        ),
                        SizedBox(width: context.rs(10)),
                        _SpecValue(
                            value:
                                section.rows[i].values[trim.slug] ?? '—'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.rs(12)),
        ],
      ],
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 15,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: context.rs(7)),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
                fontSize: context.rf(12.5), fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

/// '✓' renders as a round brand check chip; '—' muted; text otherwise.
final class _SpecValue extends StatelessWidget {
  const _SpecValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = value.trim();
    final lower = v.toLowerCase();
    if (v == '✓' || lower == 'yes' || lower == 'check') {
      return Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, size: 13, color: scheme.primary),
      );
    }
    if (v.isEmpty || v == '—') {
      return Text('—',
          style:
              TextStyle(color: scheme.onSurface.withValues(alpha: 0.3)));
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.4),
      child: Text(
        v,
        textAlign: TextAlign.end,
        style: TextStyle(
            fontSize: context.rf(11.5),
            fontWeight: FontWeight.w700,
            height: 1.35),
      ),
    );
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
    if (state.loading) {
      return SkeletonList(itemCount: 4, itemHeight: context.rs(72));
    }
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

final class _ComparisonTab extends StatefulWidget {
  const _ComparisonTab({super.key});

  @override
  State<_ComparisonTab> createState() => _ComparisonTabState();
}

final class _ComparisonTabState extends State<_ComparisonTab> {
  bool _diffsOnly = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ModelSheetCubit>();
    final state = context.watch<ModelSheetCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    if (state.loading) {
      return SkeletonList(itemCount: 5, itemHeight: context.rs(56));
    }

    final trims = trimsInMatrix(state.trims, state.equipments);
    if (trims.length < 2 || state.equipments.isEmpty) {
      return _Empty(text: t.modelsNoData);
    }

    final ia = state.trimA.clamp(0, trims.length - 1);
    var ib = state.trimB.clamp(0, trims.length - 1);
    if (ib == ia) ib = (ia + 1) % trims.length;
    final a = trims[ia];
    final b = trims[ib];
    final slugs = [a.slug ?? '', b.slug ?? ''];

    final matrix = buildSpecsMatrix(state.equipments, lang);
    final sections = _diffsOnly
        ? [
            for (final s in matrix)
              if (s.rows.any((r) => r.differsAcross(slugs)))
                SpecSection(
                  title: s.title,
                  rows: s.rows.where((r) => r.differsAcross(slugs)).toList(),
                ),
          ]
        : matrix;

    List<AppDropdownItem<int>> trimItems() => [
          for (var i = 0; i < trims.length; i++)
            AppDropdownItem(
              value: i,
              label: trims[i].name(lang),
              icon: Icons.directions_car_filled_rounded,
            ),
        ];

    return ListView(
      padding: EdgeInsets.all(context.rs(16)),
      children: [
        Text(
          t.modelsCompareHint,
          style: TextStyle(
            fontSize: context.rf(11.5),
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        SizedBox(height: context.rs(12)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppDropdown<int>(
                label: '${t.modelsChooseTrim} 1',
                value: ia,
                items: trimItems(),
                onChanged: cubit.setTrimA,
              ),
            ),
            SizedBox(width: context.rs(10)),
            Expanded(
              child: AppDropdown<int>(
                label: '${t.modelsChooseTrim} 2',
                value: ib,
                items: trimItems(),
                onChanged: cubit.setTrimB,
              ),
            ),
          ],
        ),
        SizedBox(height: context.rs(6)),
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
        SizedBox(height: context.rs(10)),
        // إظهار الاختلافات فقط
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _diffsOnly = !_diffsOnly),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.rs(6)),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    color: _diffsOnly ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: _diffsOnly
                          ? scheme.primary
                          : scheme.outline.withValues(alpha: 0.9),
                      width: 1.4,
                    ),
                  ),
                  child: _diffsOnly
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
                SizedBox(width: context.rs(8)),
                Text(
                  t.modelsDiffsOnly,
                  style: TextStyle(
                      fontSize: context.rf(12),
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: context.rs(8)),
        // ── Website "Compare side by side" tables: numbered section title,
        // then a bordered 3-column table — spec label | trim A | trim B —
        // with a sticky-style header row and diff rows softly tinted. ──
        for (final (si, section) in sections.indexed) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.rs(2), context.rs(10), context.rs(2), context.rs(8)),
            child: Row(children: [
              Text(
                '0${si + 1}',
                style: TextStyle(
                  fontSize: context.rf(10),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: scheme.primary,
                ),
              ),
              SizedBox(width: context.rs(8)),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                      fontSize: context.rf(14.5),
                      fontWeight: FontWeight.w800),
                ),
              ),
            ]),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF181B21)
                  : scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                // Header row: SPEC | trim A | trim B.
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.rs(12),
                      vertical: context.rs(9)),
                  color: scheme.surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  child: Row(children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        t.tabSpecs.toUpperCase(),
                        style: TextStyle(
                          fontSize: context.rf(9),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color:
                              scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    for (final trim in [a, b])
                      Expanded(
                        flex: 4,
                        child: Text(
                          trim.name(lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: context.rf(10.5),
                              height: 1.25,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                  ]),
                ),
                for (var i = 0; i < section.rows.length; i++)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(12),
                        vertical: context.rs(9)),
                    decoration: BoxDecoration(
                      color: section.rows[i].differsAcross(slugs)
                          ? scheme.primary.withValues(alpha: 0.05)
                          : null,
                      border: Border(
                          top: BorderSide(
                              color: scheme.outline
                                  .withValues(alpha: 0.3))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            section.rows[i].label,
                            style: TextStyle(
                              fontSize: context.rf(10.5),
                              height: 1.35,
                              color: scheme.onSurface
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                        for (final trim in [a, b])
                          Expanded(
                            flex: 4,
                            child: Align(
                              alignment:
                                  AlignmentDirectional.centerStart,
                              child: _SpecValue(
                                  value: section.rows[i]
                                          .values[trim.slug] ??
                                      '—'),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.rs(8)),
        ],
      ],
    ).animate().fadeIn(duration: 240.ms);
  }
}

final class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.directions_car_outlined,
      title: text,
      compact: true,
    );
  }
}
