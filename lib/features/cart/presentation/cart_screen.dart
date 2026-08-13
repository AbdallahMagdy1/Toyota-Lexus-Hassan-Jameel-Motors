import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/back_header.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../online_store/data/online_store_repository.dart';
import '../../online_store/presentation/car_sheet.dart';
import '../../parts/bloc/parts_cart_cubit.dart';
import '../../parts/presentation/parts_cart_screen.dart'
    show PartsCartBody, PartsCoupon;
import '../../settings/bloc/locale_cubit.dart';
import '../../../core/di/injector.dart';
import '../bloc/cart_cubit.dart';
import '../domain/cart_item.dart';

/// "My Cart" — two tabs under the header: the vehicles cart (the reference's
/// stacked rows with Make Payment pinned at the bottom) and the spare-parts
/// cart (the /parts/cart body, embedded). Cart handling mirrors the website:
/// local truth + account sync.
final class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

final class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vehicleItems = context.watch<CartCubit>().state;
    final partsItems = context.watch<PartsCartCubit>().state;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          BackHeader(
            title: t.cartTitle,
            // Clears whichever cart the active tab shows.
            trailing: ListenableBuilder(
              listenable: _tab,
              builder: (context, _) {
                final vehiclesTab = _tab.index == 0;
                final hasItems = vehiclesTab
                    ? vehicleItems.isNotEmpty
                    : partsItems.isNotEmpty;
                if (!hasItems) return const SizedBox(width: 48);
                return IconButton(
                  tooltip: t.storeClearFilters,
                  onPressed: () {
                    if (vehiclesTab) {
                      context.read<CartCubit>().clear();
                    } else {
                      context.read<PartsCartCubit>().clear();
                      PartsCoupon.current.value = null;
                    }
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, size: 22),
                );
              },
            ),
          ),
          // ── Brand-styled tabs: vehicles cart / spare-parts cart ──
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.rs(16), context.rs(6), context.rs(16), 0),
            child: TabBar(
              controller: _tab,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.55),
              indicatorColor: scheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: scheme.outline.withValues(alpha: 0.35),
              labelStyle: TextStyle(
                  fontSize: context.rf(12.5), fontWeight: FontWeight.w800),
              unselectedLabelStyle: TextStyle(
                  fontSize: context.rf(12.5), fontWeight: FontWeight.w700),
              tabs: [
                Tab(height: context.rs(40), text: t.cartTabVehicles),
                Tab(height: context.rs(40), text: t.cartTabParts),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _VehiclesCartTab(),
                PartsCartBody(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The original vehicles cart — stacked rows + Make Payment at the bottom.
final class _VehiclesCartTab extends StatelessWidget {
  const _VehiclesCartTab();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final items = context.watch<CartCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    return Column(
      children: [
          Expanded(
            child: items.isEmpty
                ? AppEmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: t.pcEmpty,
                    message: t.cartEmpty,
                    actionLabel: t.cartBrowse,
                    onAction: () => context.push(Routes.onlineStore),
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
