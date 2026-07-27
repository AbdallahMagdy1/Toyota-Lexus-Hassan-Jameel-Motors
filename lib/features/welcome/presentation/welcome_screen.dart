import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/page_dots.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../onboarding/domain/onboarding_slide.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';

/// Loads the dashboard-controlled welcome slides (placement = 'welcome').
final class WelcomeState extends Equatable {
  const WelcomeState({required this.slides, this.index = 0});

  final List<OnboardingSlide> slides;
  final int index;

  @override
  List<Object?> get props => [slides, index];
}

final class WelcomeCubit extends Cubit<WelcomeState> {
  WelcomeCubit(this._repo, {required String brandKey})
      : super(const WelcomeState(slides: kWelcomeFallback)) {
    _load(brandKey);
  }

  final OnboardingRepository _repo;
  final pageController = PageController();

  Future<void> _load(String brandKey) async {
    final slides = await _repo.fetch(brandKey, placement: 'welcome');
    if (!isClosed && slides.isNotEmpty) {
      emit(WelcomeState(slides: slides, index: 0));
    }
  }

  void onPage(int i) => emit(WelcomeState(slides: state.slides, index: i));

  @override
  Future<void> close() {
    pageController.dispose();
    return super.close();
  }
}

/// Pre-sign-in screen, reference style: media on top, white sheet below with
/// dots + title + subtitle, "Get Started" (= continue as guest) and Login.
/// Every slide (media/title/subtitle) is dashboard-controlled.
final class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandKey = context.read<ThemeCubit>().state.brandKey;
    return BlocProvider(
      create: (_) => WelcomeCubit(sl(), brandKey: brandKey),
      child: const _WelcomeView(),
    );
  }
}

final class _WelcomeView extends StatelessWidget {
  const _WelcomeView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cubit = context.read<WelcomeCubit>();
    final state = context.watch<WelcomeCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed swipeable media (reference style).
        PageView.builder(
            controller: cubit.pageController,
            itemCount: state.slides.length,
            onPageChanged: cubit.onPage,
            itemBuilder: (context, i) {
              final slide = state.slides[i];
              final url = optimizedImageUrl(
                slide.mediaType == 'image' ? slide.mediaUrl : null,
                width: (MediaQuery.sizeOf(context).width *
                        MediaQuery.devicePixelRatioOf(context))
                    .round(),
              );
              return url == null
                  ? const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF23252B), Color(0xFF101116)],
                        ),
                      ),
                    )
                  : Image.network(url,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFF1A1C21)));
            },
          ),
        // Bottom-heavy dark gradient behind the content.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.3, 0.78],
              colors: [Colors.transparent, Color(0xF00B0C0F)],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(context.rs(28), 0, context.rs(28), 0),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PageDots(
                    count: state.slides.length,
                    index: state.index,
                    activeColor: scheme.primary,
                  ),
                  SizedBox(height: context.rs(16)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Column(
                      key: ValueKey(state.index),
                      children: [
                        Text(
                          state.slides[state.index].title(lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.rf(23),
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: context.rs(8)),
                        Text(
                          state.slides[state.index].subtitle(lang),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.rf(12),
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.rs(18)),
                  // Get Started = continue as guest — brand pill.
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () => context
                        .read<AuthBloc>()
                        .add(const AuthGuestRequested()),
                    child: Text(t.onboardingGetStarted),
                  ),
                  TextButton(
                    onPressed: () => context.go(Routes.signIn),
                    child: Text(
                      t.authSignIn,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  SizedBox(height: context.rs(4)),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}
