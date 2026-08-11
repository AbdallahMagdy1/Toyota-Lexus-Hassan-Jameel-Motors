import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../home/presentation/widgets/home_bits.dart';
import '../../bloc/online_store_cubit.dart';

/// The website /online sidebar (search, price up to, categories, color) as a
/// trailing drawer.
final class StoreFilterDrawer extends StatelessWidget {
  const StoreFilterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<OnlineStoreCubit>().state;
    final cubit = context.read<OnlineStoreCubit>();
    final scheme = Theme.of(context).colorScheme;

    Widget label(String s) => Padding(
          padding: EdgeInsets.only(top: context.rs(20), bottom: context.rs(8)),
          child: Text(
            s.toUpperCase(),
            style: TextStyle(
              fontSize: context.rf(11),
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        );

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.rs(16), context.rs(8), context.rs(8), 0),
          child: Row(
            children: [
              Text(t.storeFilters,
                  style: TextStyle(
                      fontSize: context.rf(17), fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
            children: [
              label(t.storeSearch),
              TextFormField(
                initialValue: state.query,
                onChanged: cubit.setQuery,
                decoration: InputDecoration(
                  hintText: t.storeSearch,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                ),
              ),
              label(t.storePriceUpTo),
              if (state.priceCeiling > 0) ...[
                Slider(
                  value: state.maxPrice.clamp(0, state.priceCeiling),
                  min: 0,
                  max: state.priceCeiling,
                  onChanged: cubit.setMaxPrice,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: PriceText(
                    price: state.maxPrice,
                    currency: t.currency,
                    contactForPrice: '',
                    fontSize: context.rf(13),
                    color: scheme.primary,
                  ),
                ),
              ],
              label(t.storeCategories),
              for (final c in state.availableCategories)
                CheckboxListTile(
                  value: state.categories.contains(c),
                  onChanged: (_) => cubit.toggleCategory(c),
                  title: Text(c, style: TextStyle(fontSize: context.rf(13.5))),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              SizedBox(height: context.rs(20)),
              AppDropdown<String>(
                label: t.storeColor,
                value: state.colorName ?? '',
                hint: t.storeAllColors,
                items: [
                  AppDropdownItem(value: '', label: t.storeAllColors),
                  for (final name in state.availableColors)
                    AppDropdownItem(value: name, label: name),
                ],
                onChanged: (v) => cubit.setColor(v.isEmpty ? null : v),
              ),
              SizedBox(height: context.rs(16)),
              OutlinedButton.icon(
                onPressed: cubit.clearFilters,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(t.storeClearFilters),
              ),
              SizedBox(height: context.rs(30)),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(context.rs(16)),
          child: FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text('${t.storeApplyFilters} (${state.filtered.length})'),
          ),
        ),
      ],
    );
  }
}
