import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/slide_media.dart';
import '../../../shared/widgets/brand_backdrop.dart';
import '../../../shared/widgets/swipe_action.dart';
import '../../../shared/widgets/page_dots.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/onboarding_cubit.dart';
import '../domain/onboarding_slide.dart';

/// Dashboard-driven onboarding: full-bleed media, bottom-anchored copy,
/// badge chip, page dots, Get Started / Sign In — the structure of the
/// reference design with the HJ brand system.
final class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandKey = context.read<ThemeCubit>().state.brandKey;
    return BlocProvider(
      create: (_) => OnboardingCubit(sl(), sl(), brandKey: brandKey),
      child: const _OnboardingView(),
    );
  }
}

final class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final state = context.watch<OnboardingCubit>().state;
    final theme = context.watch<ThemeCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final t = AppLocalizations.of(context);
    final slide = state.slides[state.index.clamp(0, state.slides.length - 1)];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Backdrop crossfades between slides' dashboard media — video slides
        // auto-play muted behind the brand overlay.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: slide.mediaType == 'video' &&
                  (slide.mediaUrl ?? '').isNotEmpty
              ? Stack(
                  key: ValueKey('v${slide.id}'),
                  fit: StackFit.expand,
                  children: [
                    SlideMedia(
                        mediaType: slide.mediaType,
                        mediaUrl: slide.mediaUrl),
                    if (slide.overlay)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                  ],
                )
              : BrandBackdrop(
                  key: ValueKey(slide.id),
                  brand: theme.brand,
                  imageUrl:
                      slide.mediaType == 'image' ? slide.mediaUrl : null,
                  overlay: slide.overlay,
                ),
        ),
        SafeArea(
          child: Column(
            children: [
              // Top bar: brand switch + language toggle.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
                    TextButton(
                      onPressed: () => context.read<LocaleCubit>().toggle(),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: Text(t.settingsLanguage,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              // Swipeable copy — the PageView carries the text so the swipe
              // gesture works anywhere on screen.
              Expanded(
                child: PageView.builder(
                  controller: cubit.pageController,
                  itemCount: state.slides.length,
                  onPageChanged: cubit.onPageChanged,
                  itemBuilder: (context, i) =>
                      _SlideCopy(slide: state.slides[i], lang: lang),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    context.rs(24), 0, context.rs(24), context.rs(14)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: context.maxContentWidth),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PageDots(count: state.slides.length, index: state.index),
                    SizedBox(height: context.rs(20)),
                    // The reference swipe CTA — greets a signed-in user by
                    // name and routes by auth state.
                    Builder(builder: (context) {
                      final user = context.watch<AuthBloc>().state.user;
                      final first = (user?.displayName(lang) ?? '')
                              .split(' ')
                              .firstOrNull ??
                          '';
                      final label = user != null && first.isNotEmpty
                          ? '${t.onboardingHello} $first — ${t.onboardingGetStarted}'
                          : t.onboardingGetStarted;
                      return SwipeAction(
                        label: label,
                        onConfirm: () async {
                          cubit.complete();
                          context.go(
                              user != null ? Routes.home : Routes.welcome);
                          return true;
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                    if (context.watch<AuthBloc>().state.user == null)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.25)),
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                        ),
                        onPressed: () {
                          cubit.complete();
                          context.go(Routes.signIn);
                        },
                        child: Text(t.onboardingSignIn),
                      ),
                    SizedBox(height: context.rs(12)),
                    Text(
                      t.onboardingTerms,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.rf(11.5),
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _SlideCopy extends StatelessWidget {
  const _SlideCopy({required this.slide, required this.lang});

  final OnboardingSlide slide;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final badge = slide.badge(lang);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rs(26)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            slide.title(lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: context.rf(27),
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: context.rs(12)),
          Text(
            slide.subtitle(lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: context.rf(14.5),
              height: 1.5,
            ),
          ),
          SizedBox(height: context.rs(18)),
          if (badge.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      badge,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 26),
        ],
      )
          .animate(key: ValueKey(slide.id))
          .fadeIn(duration: 450.ms, curve: Curves.easeOut)
          .slideY(begin: 0.06, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),
    );
  }
}

/// Toyota / Lexus pill switcher — swaps the whole app palette live
/// (same effect as visiting toyotahj.com vs lexushj.com).
