import 'dart:async' show Timer;
import 'dart:math' show sin, pi;

import 'package:flutter/material.dart';

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

/// Verification result rendered by [OtpField] — always derived from the
/// EXISTING cubit/bloc state by the caller, never inferred from digit count.
enum OtpStatus { idle, success, error }

/// Big centered OTP entry — per-digit boxes over a hidden field (the
/// controller/submit contract is unchanged, so all flows keep working) —
/// with the premium result morph: on success/error the digit boxes slide
/// together, their spacing collapses, and they fuse into ONE rounded status
/// pill (✓ verified / ✕ incorrect + shake). Tapping the error pill clears
/// the code and morphs smoothly back to empty boxes for a retry.
final class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.controller,
    required this.focusColor,
    this.onSubmitted,
    this.status = OtpStatus.idle,
    this.successLabel,
    this.errorLabel,
    this.errorHint,
  });

  final TextEditingController controller;
  final Color focusColor;
  final ValueChanged<String>? onSubmitted;

  /// Drives the morph — pass the existing verification state.
  final OtpStatus status;
  final String? successLabel;
  final String? errorLabel;
  final String? errorHint;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

final class _OtpFieldState extends State<OtpField>
    with TickerProviderStateMixin {
  static const _kSuccess = Color(0xFF1F9D55);

  /// 0 → separate boxes … 1 → fused status pill.
  late final AnimationController _merge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
    reverseDuration: const Duration(milliseconds: 340),
  );

  /// Quick horizontal shake fired once the error pill has formed.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  final FocusNode _focus = FocusNode();

  /// User tapped the error pill — visually back to boxes for a retry while
  /// the parent's error state stays untouched.
  bool _dismissed = false;

  OtpStatus get _shown =>
      _dismissed ? OtpStatus.idle : widget.status;

  void _play() {
    _shake.reset();
    _merge.forward().whenComplete(() {
      if (mounted && widget.status == OtpStatus.error && !_dismissed) {
        _shake.forward();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // If the element was (re)created with a result already set, still PLAY
    // the morph rather than snapping — covers any parent rebuild pattern.
    if (widget.status != OtpStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.status != OtpStatus.idle && !_dismissed) {
          _play();
        }
      });
    }
  }

  @override
  void didUpdateWidget(OtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status == widget.status) return;
    _dismissed = false;
    if (widget.status == OtpStatus.idle) {
      _merge.reverse();
    } else {
      _play();
    }
  }

  void _retry() {
    if (widget.status != OtpStatus.error || _dismissed) return;
    setState(() => _dismissed = true);
    _merge.reverse();
    widget.controller.clear();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _merge.dispose();
    _shake.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final error = _shown == OtpStatus.error;
    final accent = error ? scheme.error : _kSuccess;

    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _merge, _shake]),
      builder: (context, _) {
        final code = widget.controller.text;
        final boxes = code.length > 4 ? 6 : 4;
        final m = Curves.easeInOutCubic.transform(_merge.value);
        // Boxes keep sliding until 0.65, then the pill crossfades in on top.
        final boxOpacity = m < 0.55 ? 1.0 : (1 - (m - 0.55) / 0.3).clamp(0.0, 1.0);
        final pillT = ((m - 0.6) / 0.4).clamp(0.0, 1.0);
        // Quick decaying sine — subtle side-to-side, never the whole screen.
        final shakeDx =
            sin(_shake.value * pi * 4) * 7 * (1 - _shake.value);

        return Stack(
          alignment: Alignment.center,
          children: [
            // The hidden input that actually captures the code.
            Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                onSubmitted: widget.onSubmitted,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
            // ── Digit boxes: spacing + circle-shape melt away as they merge ──
            if (boxOpacity > 0)
              IgnorePointer(
                child: Opacity(
                  opacity: boxOpacity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: TextDirection.ltr,
                    children: [
                      for (var i = 0; i < boxes; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          width: 50,
                          height: 50,
                          margin: EdgeInsets.symmetric(
                              horizontal: 5 * (1 - m)),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            // Active (next-digit) box glows softly so the
                            // field visibly tracks typing.
                            color: i == code.length && m == 0
                                ? widget.focusColor.withValues(alpha: 0.10)
                                : scheme.onSurface.withValues(alpha: 0.04),
                            borderRadius:
                                BorderRadius.circular(25 - 11 * m),
                            border: Border.all(
                              color: i < code.length
                                  ? widget.focusColor
                                  : i == code.length && m == 0
                                      ? widget.focusColor
                                          .withValues(alpha: 0.7)
                                      : scheme.onSurface
                                          .withValues(alpha: 0.35),
                              width: i <= code.length ? 1.8 : 1.2,
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
                  ),
                ),
              ),
            // ── The fused status pill (✓ / ✕) ──
            if (pillT > 0)
              GestureDetector(
                onTap: _retry,
                child: Transform.translate(
                  offset: Offset(shakeDx, 0),
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * Curves.easeOutBack.transform(pillT),
                    child: Opacity(
                      opacity: pillT,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: boxes * 50.0,
                            height: 50,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: accent.withValues(alpha: 0.6),
                                  width: 1.4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon pops in slightly after the pill.
                                Transform.scale(
                                  scale: Curves.easeOutBack.transform(
                                      ((pillT - 0.35) / 0.65)
                                          .clamp(0.0, 1.0)),
                                  child: Icon(
                                    error
                                        ? Icons.close_rounded
                                        : Icons.check_rounded,
                                    size: 22,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    (error
                                            ? widget.errorLabel
                                            : widget.successLabel) ??
                                        '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (error && (widget.errorHint ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                widget.errorHint!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
