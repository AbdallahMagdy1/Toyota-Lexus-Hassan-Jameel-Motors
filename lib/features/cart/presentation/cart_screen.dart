import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../online_store/data/online_store_repository.dart';
import '../../online_store/presentation/car_sheet.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../../core/di/injector.dart';
import '../bloc/cart_cubit.dart';
import '../domain/cart_item.dart';

/// "My Cart" — the reference's stacked rows: image, name, price, trailing
/// action; first (selected) row rendered as a high-contrast pill with a
/// trash button, others with an arrow; Make Payment pinned at the bottom.
/// Cart handling mirrors the website: local truth + account sync.
final class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final items = context.watch<CartCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.rs(8), context.rs(6), context.rs(8), 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go(Routes.home),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                Expanded(
                  child: Text(
                    t.cartTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: context.rf(17), fontWeight: FontWeight.w800),
                  ),
                ),
                if (items.isNotEmpty)
                  IconButton(
                    tooltip: t.storeClearFilters,
                    onPressed: () => context.read<CartCubit>().clear(),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 22),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 44,
                            color: scheme.onSurface.withValues(alpha: 0.3)),
                        SizedBox(height: context.rs(12)),
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: context.rs(40)),
                          child:
                              Text(t.cartEmpty, textAlign: TextAlign.center),
                        ),
                        TextButton(
                          onPressed: () => context.push(Routes.onlineStore),
                          child: Text(t.cartBrowse),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(context.rs(20), context.rs(10),
                        context.rs(20), context.rs(110)),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _CartRow(
                      item: items[i],
                      highlighted: i == 0,
                      lang: lang,
                    )
                        .animate(delay: (40 * (i % 8)).ms)
                        .fadeIn(duration: 250.ms)
                        .slideY(begin: 0.05, end: 0, duration: 250.ms),
                  ),
          ),
          if (items.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  context.rs(20), 0, context.rs(20), context.rs(86)),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF141519),
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF141519)
                          : Colors.white,
                ),
                onPressed: () => openCartItemInStore(context, items.first),
                child: Text(t.cartMakePayment),
              ),
            ),
        ],
      ),
    );
  }
}

/// Resolve the live catalog row for a cart item and open its purchase sheet.
Future<void> openCartItemInStore(BuildContext context, CartItem item) async {
  final vehicles = await sl<OnlineStoreRepository>().vehicles();
  if (!context.mounted) return;
  final match = vehicles.where((v) => v.slug == item.slug).firstOrNull;
  if (match != null) await openCarSheet(context, match);
}

final class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.highlighted,
    required this.lang,
  });

  final CartItem item;
  final bool highlighted;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = highlighted
        ? (isDark ? Colors.white : const Color(0xFF141519))
        : scheme.surface;
    final fg = highlighted
        ? (isDark ? const Color(0xFF141519) : Colors.white)
        : scheme.onSurface;

    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(12)),
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openCartItemInStore(context, item),
          child: Container(
            padding: EdgeInsets.all(context.rs(10)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: highlighted
                  ? null
                  : Border.all(color: scheme.outline.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                // Car thumb on a light pad, like the reference.
                Container(
                  width: context.rs(74),
                  height: context.rs(52),
                  padding: EdgeInsets.all(context.rs(4)),
                  decoration: BoxDecoration(
                    color: highlighted
                        ? fg.withValues(alpha: 0.08)
                        : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: HomeImage(
                      url: item.image, fit: BoxFit.contain, logicalWidth: 90),
                ),
                SizedBox(width: context.rs(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.rf(14),
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
                      SizedBox(height: context.rs(2)),
                      PriceText(
                        price: item.price,
                        currency: t.currency,
                        contactForPrice: t.homeContactForPrice,
                        fontSize: context.rf(12),
                        color: fg.withValues(alpha: 0.75),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: highlighted
                      ? () => context.read<CartCubit>().remove(item)
                      : () => openCartItemInStore(context, item),
                  icon: Icon(
                    highlighted
                        ? Icons.delete_outline_rounded
                        : (Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded),
                    size: 20,
                    color: fg.withValues(alpha: highlighted ? 1 : 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
