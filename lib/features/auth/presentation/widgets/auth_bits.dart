import 'package:flutter/material.dart';

/// Small shared pieces for the auth flows (all render on the dark backdrop).

/// Brand-tinted success/info banner — the website's notice pill.
final class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

final class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE5484D).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5484D).withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFFF8A8E), fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// The website SignUpPanel's 2-step progress bar.
final class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.color, this.total = 2});

  final int step; // 1-based
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                color: i <= step
                    ? color
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < total) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

/// Big centered OTP entry — mirrors the website's tracking-[0.5em] input.
final class OtpField extends StatelessWidget {
  const OtpField({
    super.key,
    required this.controller,
    required this.focusColor,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final Color focusColor;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    // Reference style: circular per-digit boxes over a hidden field — the
    // controller/submit contract is unchanged, so all flows keep working.
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // The hidden input that actually captures the code.
        Opacity(
          opacity: 0,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            onSubmitted: onSubmitted,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(counterText: ''),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final code = controller.text;
              final boxes = code.length > 4 ? 6 : 4;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.ltr,
                children: [
                  for (var i = 0; i < boxes; i++)
                    Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.onSurface.withValues(alpha: 0.04),
                        border: Border.all(
                          color: i < code.length
                              ? focusColor
                              : scheme.onSurface.withValues(alpha: 0.35),
                          width: i < code.length ? 1.8 : 1.2,
                        ),
                      ),
                      child: Text(
                        i < code.length ? code[i] : '',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Dashboard-controlled OTP slide (placement = 'otp'): the reference's top
/// panel — brand-colored, big rounded bottom, slide title/subtitle + dots,
/// with the brand roundel overlapping the curve.
final class OtpSlidePanel extends StatelessWidget {
  const OtpSlidePanel({
    super.key,
    required this.slides,
    required this.lang,
    this.brandKey = 'toyota',
  });

  final List<dynamic> slides; // OnboardingSlide list (title/subtitle per lang)
  final String lang;
  final String brandKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (slides.isEmpty) return const SizedBox.shrink();
    final slide = slides.first;
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 44),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: const BorderRadius.vertical(
              bottom: Radius.elliptical(220, 90)),
        ),
        child: Column(children: [
          Icon(Icons.sms_outlined,
              size: 34, color: scheme.onPrimary.withValues(alpha: 0.9)),
          const SizedBox(height: 10),
          Text(
            slide.title(lang) as String,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            slide.subtitle(lang) as String,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: scheme.onPrimary.withValues(alpha: 0.8),
                fontSize: 11.5,
                height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < slides.length.clamp(1, 5); i++)
                Container(
                  width: i == 0 ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: scheme.onPrimary
                        .withValues(alpha: i == 0 ? 0.95 : 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ]),
      ),
      // Overlapping circular brand badge, like the reference.
      Transform.translate(
        offset: const Offset(0, -26),
        child: Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Image.asset(
            brandKey == 'lexus'
                ? 'assets/logos/lexus-ico.png'
                : 'assets/logos/toyota-ico.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    ]);
  }
}
