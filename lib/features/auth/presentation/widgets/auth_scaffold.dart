import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/responsive.dart';
import '../../../onboarding/data/onboarding_repository.dart';
import '../../../onboarding/domain/onboarding_slide.dart';
import '../../../settings/bloc/theme_cubit.dart';

/// Dashboard-controlled auth banner (placement = 'auth'): image OR video.
final class AuthBannerState extends Equatable {
  const AuthBannerState({this.slide, this.videoReady = false});

  final OnboardingSlide? slide;
  final bool videoReady;

  @override
  List<Object?> get props => [slide, videoReady];
}

final class AuthBannerCubit extends Cubit<AuthBannerState> {
  AuthBannerCubit(this._repo,
      {required String brandKey, String placement = 'auth'})
      : super(const AuthBannerState()) {
    _load(brandKey, placement);
  }

  final OnboardingRepository _repo;
  VideoPlayerController? video;

  Future<void> _load(String brandKey, String placement) async {
    // Per-screen background (sign_in / sign_up), 'auth' as the fallback.
    var slides = await _repo.fetch(brandKey, placement: placement);
    if (slides.isEmpty && placement != 'auth') {
      slides = await _repo.fetch(brandKey, placement: 'auth');
    }
    if (isClosed) return;
    final slide = slides.isEmpty ? null : slides.first;
    emit(AuthBannerState(slide: slide));

    // Video banners play muted + looped, like the website's hero videos.
    final url = cleanMediaUrl(slide?.mediaUrl);
    if (slide?.mediaType == 'video' && url != null) {
      try {
        video = VideoPlayerController.networkUrl(Uri.parse(url));
        await video!.initialize();
        if (isClosed) return;
        await video!.setLooping(true);
        await video!.setVolume(0);
        await video!.play();
        emit(AuthBannerState(slide: slide, videoReady: true));
      } catch (_) {
        // Fall back to the gradient banner.
      }
    }
  }

  @override
  Future<void> close() {
    video?.dispose();
    return super.close();
  }
}

/// The reference auth layout: media banner on top with the centered
/// underlined title, then a surface panel whose top edge sweeps up in a
/// wave — the form renders inside the panel.
final class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.placement = 'auth',
  });

  final String title;
  final Widget child;

  /// Dashboard placement controlling this screen's background.
  final String placement;

  @override
  Widget build(BuildContext context) {
    final brandKey = context.read<ThemeCubit>().state.brandKey;
    return BlocProvider(
      create: (_) =>
          AuthBannerCubit(sl(), brandKey: brandKey, placement: placement),
      child: _AuthScaffoldView(title: title, child: child),
    );
  }
}

final class _AuthScaffoldView extends StatelessWidget {
  const _AuthScaffoldView({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = context.watch<ThemeCubit>().state;
    final banner = context.watch<AuthBannerCubit>().state;
    final cubit = context.read<AuthBannerCubit>();
    final glow = theme.brand.colorFor(Brightness.dark);
    final height = MediaQuery.sizeOf(context).height;

    Widget media;
    if (banner.videoReady && cubit.video != null) {
      media = FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: cubit.video!.value.size.width,
          height: cubit.video!.value.size.height,
          child: VideoPlayer(cubit.video!),
        ),
      );
    } else {
      final url = optimizedImageUrl(
        banner.slide?.mediaType == 'image' ? banner.slide?.mediaUrl : null,
        width: (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round(),
      );
      media = url == null
          ? DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    glow.withValues(alpha: 0.85),
                    const Color(0xFF15171C),
                  ],
                ),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFF1A1C21)),
            );
    }

    // Reference style: the media fills the WHOLE screen; the form floats
    // over a bottom-heavy dark gradient in frosted dark fields.
    final dark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: scheme.primary,
        onPrimary: scheme.onPrimary,
        surface: const Color(0xFF15171C),
        onSurface: Colors.white,
        outline: Colors.white24,
        error: const Color(0xFFFF6B6B),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: glow, width: 1.6),
        ),
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        labelStyle: const TextStyle(color: Colors.white54),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: glow,
          foregroundColor: theme.brand.foregroundFor(Brightness.dark),
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.white70),
      ),
    );

    return Theme(
      data: dark,
      child: Stack(
        fit: StackFit.expand,
        children: [
          media,
          // Legibility gradient — light on top, near-black behind the form.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.38, 0.7],
                colors: [
                  Color(0x66000000),
                  Color(0x99000000),
                  Color(0xF20B0C0F),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: height * 0.10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.rs(26)),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.rf(28),
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                const Spacer(),
                // The form floats over the gradient (no panel).
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: height * 0.66),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        context.rs(26), 0, context.rs(26), context.rs(8)),
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(color: Colors.white),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
