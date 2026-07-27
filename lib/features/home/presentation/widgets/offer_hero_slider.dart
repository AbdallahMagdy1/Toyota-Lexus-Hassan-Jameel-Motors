import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/page_dots.dart';
import '../../../settings/bloc/theme_cubit.dart';
import '../../domain/home_models.dart';
import 'home_bits.dart';

/// Top-of-page offers slider — the "25% Off Weekly Specials!" reference
/// style: a rounded brand-primary panel with the copy on the start side and
/// the offer artwork on the end side, dots underneath.
final class OfferHeroSlider extends StatelessWidget {
  const OfferHeroSlider({
    super.key,
    required this.offers,
    required this.controller,
    required this.index,
    required this.onChanged,
    required this.lang,
  });

  final List<HomeOffer> offers;
  final PageController controller;
  final int index;
  final ValueChanged<int> onChanged;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: context.rs(170),
          child: PageView.builder(
            controller: controller,
            itemCount: offers.length,
            onPageChanged: onChanged,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
              child: _HeroCard(offer: offers[i], lang: lang),
            ),
          ),
        ),
        SizedBox(height: context.rs(10)),
        PageDots(
          count: offers.length,
          index: index,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}

final class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.offer, required this.lang});

  final HomeOffer offer;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final brand = context.watch<ThemeCubit>().state.brand;
    final brandColor = brand.colorFor(Theme.of(context).brightness);
    final days = offer.daysLeft;

    return RepaintBoundary(
      child: Material(
        color: const Color(0xFF17181C),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The offer artwork fills the whole card.
              HomeImage(
                url: offer.image(lang),
                fit: BoxFit.cover,
                logicalWidth: MediaQuery.sizeOf(context).width,
              ),
              // Transparent legibility overlay so titles read over the art.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.45, 1.0],
                    colors: [
                      Color(0x59000000),
                      Color(0x26000000),
                      Color(0xCC000000),
                    ],
                  ),
                ),
              ),
              // Top badges.
              PositionedDirectional(
                top: context.rs(12),
                start: context.rs(14),
                child: offer.typeName(lang).isEmpty
                    ? const SizedBox.shrink()
                    : Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rs(9), vertical: context.rs(4)),
                        decoration: BoxDecoration(
                          color: brandColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          offer.typeName(lang),
                          style: TextStyle(
                            color: brand.foregroundFor(Theme.of(context).brightness),
                            fontSize: context.rf(9.5),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
              ),
              if (days != null)
                PositionedDirectional(
                  top: context.rs(12),
                  end: context.rs(14),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(9), vertical: context.rs(4)),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      t.homeDaysLeft(days),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.rf(9.5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              // Bottom copy + CTA — anchored, never overflows.
              PositionedDirectional(
                start: context.rs(14),
                end: context.rs(14),
                bottom: context.rs(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      offer.title(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.rf(16),
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (offer.excerpt(lang).isNotEmpty) ...[
                      SizedBox(height: context.rs(3)),
                      Text(
                        offer.excerpt(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: context.rf(10.5),
                          height: 1.35,
                        ),
                      ),
                    ],
                    SizedBox(height: context.rs(8)),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.rs(14), vertical: context.rs(8)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        t.homeReserveNow,
                        style: TextStyle(
                          color: const Color(0xFF141519),
                          fontSize: context.rf(11),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
