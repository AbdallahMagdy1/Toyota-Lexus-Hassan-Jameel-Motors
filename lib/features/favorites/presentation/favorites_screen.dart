import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../online_store/bloc/collections_cubits.dart';
import '../../online_store/bloc/online_store_cubit.dart';
import '../../online_store/presentation/online_store_screen.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';

/// Favorited cars — the hearted online-store cards in a grid.
final class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandKey = context.select((ThemeCubit c) => c.state.brandKey);
    return BlocProvider(
      key: ValueKey('favs-$brandKey'),
      create: (_) => OnlineStoreCubit(sl(), brandKey: brandKey),
      child: const _FavoritesView(),
    );
  }
}

final class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final store = context.watch<OnlineStoreCubit>().state;
    final favorites = context.watch<FavoritesCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    final cars =
        store.vehicles.where((v) => favorites.contains(v.slug ?? '')).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.rs(8), context.rs(6), context.rs(8), 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => appBack(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                Expanded(
                  child: Text(
                    t.favTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: context.rf(17), fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: store.status == StoreStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : cars.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite_border_rounded,
                                size: 44,
                                color: scheme.onSurface.withValues(alpha: 0.3)),
                            SizedBox(height: context.rs(12)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: context.rs(40)),
                              child: Text(t.favEmpty,
                                  textAlign: TextAlign.center),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push(Routes.onlineStore),
                              child: Text(t.cartBrowse),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.fromLTRB(context.rs(16),
                            context.rs(10), context.rs(16), context.rs(100)),
                        cacheExtent: 800,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: context.isTablet ? 3 : 2,
                          mainAxisSpacing: context.rs(12),
                          crossAxisSpacing: context.rs(12),
                          childAspectRatio: 0.58,
                        ),
                        itemCount: cars.length,
                        itemBuilder: (context, i) => RepaintBoundary(
                          child: StoreCarCard(vehicle: cars[i], lang: lang)
                              .animate(delay: (30 * (i % 8)).ms)
                              .fadeIn(duration: 260.ms),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
