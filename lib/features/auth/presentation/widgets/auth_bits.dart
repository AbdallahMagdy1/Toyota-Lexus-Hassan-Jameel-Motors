import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:otp_animated_fields/otp_animated_fields.dart';

import '../../../../shared/widgets/slide_media.dart';

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

/// Big centered OTP entry — `otp_animated_fields` under the hood (animated
/// per-digit boxes, built-in verifying/success/error choreography + haptics).
/// The typed code is mirrored into [controller] on every keystroke, so all
/// the existing cubits keep reading `cubit.otp.text` unchanged; [onVerify]
/// runs the flow's EXISTING verification and its bool drives the package's
/// success / error animations (auto-fired when the last digit lands).
final class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.controller,
    required this.focusColor,
    required this.onVerify,
    this.onVerified,
    this.length = 4,
  });

  final TextEditingController controller;
  final Color focusColor;

  /// The flow's real verification (cubit call). true → success animation,
  /// false → error animation (code kept for a quick correction).
  final Future<bool> Function(String code) onVerify;

  /// Fired after the success animation completes.
  final VoidCallback? onVerified;

  final int length;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

final class _OtpFieldState extends State<OtpField> {
  final OtpAnimatedController _otp = OtpAnimatedController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? OtpAnimatedTheme.dark(accentColor: widget.focusColor)
        : OtpAnimatedTheme.light(accentColor: widget.focusColor);
    // Digits always read left-to-right, also in the Arabic UI. Centered:
    // the field lives inside stretched auth columns, so it must not hug
    // the start edge. The verifying orbit is tuned tight and quick — a
    // small, fast whirl instead of the default big slow scatter — and no
    // orbit height is reserved, so the idle row sits compact.
    return Center(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: OtpAnimatedField(
          length: widget.length,
          autofocus: true,
          controller: _otp,
          keyboardType: TextInputType.number,
          hapticFeedback: true,
          reserveOrbitSpace: false,
          minimumVerifyingDuration: const Duration(milliseconds: 500),
          theme: base.copyWith(
            boxSize: 54,
            gap: 10,
            borderRadius: 16,
            glowBlurRadius: 10,
            orbitRadius: 40,
            orbitBoxScale: 0.5,
            morphDuration: const Duration(milliseconds: 340),
            orbitPeriod: const Duration(milliseconds: 1100),
            errorDuration: const Duration(milliseconds: 700),
            successDuration: const Duration(milliseconds: 800),
          ),
          // Mirror every keystroke into the flow's controller so the cubits
          // keep reading cubit.otp.text exactly as before.
          onChanged: (code) => widget.controller.text = code,
          onVerify: (code) {
            widget.controller.text = code;
            return widget.onVerify(code);
          },
          onVerified: (_) => widget.onVerified?.call(),
        ),
      ),
    );
  }
}

/// OTP validity countdown (+ optional resend that restarts it). Pure UI —
/// the resend tap calls the screen's EXISTING cubit method; the timer is
/// only a visual indicator of the code's validity window.
final class OtpTimerResend extends StatefulWidget {
  const OtpTimerResend({
    super.key,
    required this.validForLabel,
    required this.expiredLabel,
    this.duration = const Duration(minutes: 2),
    this.onResend,
    this.resendLabel,
    this.busy = false,
  });

  /// Builds "الرمز صالح لمدة {mm:ss}" from the remaining time.
  final String Function(String time) validForLabel;
  final String expiredLabel;
  final Duration duration;

  /// The EXISTING resend action (e.g. cubit.resendOtp); tapping it also
  /// restarts the countdown. Null hides the button (timer only).
  final VoidCallback? onResend;
  final String? resendLabel;
  final bool busy;

  @override
  State<OtpTimerResend> createState() => _OtpTimerResendState();
}

final class _OtpTimerResendState extends State<OtpTimerResend> {
  Timer? _tick;
  late int _left = widget.duration.inSeconds;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _tick?.cancel();
    _left = widget.duration.inSeconds;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left = (_left - 1).clamp(0, 1 << 20));
      if (_left == 0) _tick?.cancel();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final expired = _left == 0;
    final mm = (_left ~/ 60).toString().padLeft(2, '0');
    final ss = (_left % 60).toString().padLeft(2, '0');

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            expired ? Icons.timer_off_outlined : Icons.timer_outlined,
            size: 14,
            color: expired
                ? scheme.error
                : scheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 5),
          Text(
            expired ? widget.expiredLabel : widget.validForLabel('$mm:$ss'),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: expired
                  ? scheme.error
                  : scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
      if (widget.onResend != null)
        TextButton(
          onPressed: widget.busy
              ? null
              : () {
                  widget.onResend!();
                  _start();
                },
          child: Text(widget.resendLabel ?? ''),
        ),
    ]);
  }
}

/// Dashboard-controlled OTP slides (placement = 'otp'): the reference's top
/// panel — a REAL swipeable PageView now: each slide renders its dashboard
/// media (image or auto-playing video via [SlideMedia]) behind a brand
/// scrim, dots track the page, and it auto-advances every 6s.
final class OtpSlidePanel extends StatefulWidget {
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
  State<OtpSlidePanel> createState() => _OtpSlidePanelState();
}

final class _OtpSlidePanelState extends State<OtpSlidePanel> {
  final PageController _controller = PageController();
  Timer? _auto;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  void _startAuto() {
    _auto?.cancel();
    if (widget.slides.length < 2) return;
    _auto = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % widget.slides.length,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slides = widget.slides;
    if (slides.isEmpty) return const SizedBox.shrink();

    return Column(children: [
      ClipRRect(
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.elliptical(220, 90)),
        child: SizedBox(
          height: 190,
          width: double.infinity,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final slide = slides[i];
              final mediaUrl = (slide.mediaUrl ?? '') as String;
              final mediaType = (slide.mediaType ?? '') as String;
              return Stack(fit: StackFit.expand, children: [
                // Dashboard media (image or auto-playing muted video);
                // solid brand panel when the slide has none.
                if (mediaUrl.isNotEmpty)
                  SlideMedia(
                    mediaType: mediaType,
                    mediaUrl: mediaUrl,
                    fit: BoxFit.cover,
                  )
                else
                  ColoredBox(color: scheme.primary),
                // Brand scrim keeps the copy legible over any artwork.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary
                        .withValues(alpha: mediaUrl.isEmpty ? 0 : 0.55),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
                  child: Column(children: [
                    Icon(Icons.sms_outlined,
                        size: 30,
                        color: scheme.onPrimary.withValues(alpha: 0.9)),
                    const SizedBox(height: 8),
                    Text(
                      slide.title(widget.lang) as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slide.subtitle(widget.lang) as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: scheme.onPrimary.withValues(alpha: 0.85),
                          fontSize: 11.5,
                          height: 1.4),
                    ),
                    const Spacer(),
                    // Live dots — follow the swipe.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i2 = 0; i2 < slides.length.clamp(1, 5); i2++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: i2 == _page ? 16 : 6,
                            height: 6,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 2.5),
                            decoration: BoxDecoration(
                              color: scheme.onPrimary.withValues(
                                  alpha: i2 == _page ? 0.95 : 0.4),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                      ],
                    ),
                  ]),
                ),
              ]);
            },
          ),
        ),
      ),
      // Overlapping circular brand badge, like the reference.
      Transform.translate(
        offset: const Offset(0, -26),
        child: Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            widget.brandKey == 'lexus'
                ? 'assets/logos/lexus-ico.png'
                : 'assets/logos/toyota-ico.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    ]);
  }
}
