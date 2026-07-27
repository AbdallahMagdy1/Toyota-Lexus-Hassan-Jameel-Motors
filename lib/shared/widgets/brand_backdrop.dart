import 'package:flutter/material.dart';

import '../../core/theme/app_brand.dart';
import '../../core/utils/media_url.dart';

/// Full-bleed dark backdrop: optional dashboard image/video poster with a
/// legibility gradient, else a premium dark gradient with a soft brand glow.
/// RepaintBoundary + const gradients keep it cheap.
final class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({
    super.key,
    required this.brand,
    this.imageUrl,
    this.overlay = true,
  });

  final AppBrand brand;
  final String? imageUrl;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final glow = brand.colorFor(Brightness.dark);
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF15171C), Color(0xFF0A0B0D)],
              ),
            ),
          ),
          // Soft brand-tinted glow, top-right — gives each brand its identity
          // even before any dashboard media loads.
          Positioned(
            top: -120,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [glow.withValues(alpha: 0.28), glow.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ),
          ),
          if (optimizedImageUrl(imageUrl) != null)
            Image.network(
              optimizedImageUrl(
                imageUrl,
                width: (MediaQuery.sizeOf(context).width *
                        MediaQuery.devicePixelRatioOf(context))
                    .round(),
              )!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
              frameBuilder: (context, child, frame, wasSync) => AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: child,
              ),
            ),
          if (overlay)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                  colors: [Color(0x66000000), Color(0x33000000), Color(0xE6000000)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
