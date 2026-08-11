import 'package:flutter/material.dart';

/// The reference swipe control: dark rounded track, a white circular thumb
/// carrying a CAR icon in the brand color, the label centered and animated
/// chevrons on the end. Dragging fills the track with the brand color;
/// releasing early — or a failed [onConfirm] — springs the thumb back.
final class SwipeAction extends StatefulWidget {
  const SwipeAction({
    super.key,
    required this.label,
    required this.onConfirm,
    this.enabled = true,
  });

  final String label;

  /// Return false to reject (the thumb springs back), true to stay complete.
  final Future<bool> Function() onConfirm;
  final bool enabled;

  @override
  State<SwipeAction> createState() => _SwipeActionState();
}

final class _SwipeActionState extends State<SwipeAction> {
  double _drag = 0; // 0..1
  bool _snapping = false;

  Future<void> _release() async {
    if (_drag > 0.8) {
      setState(() {
        _snapping = true;
        _drag = 1;
      });
      final ok = await widget.onConfirm();
      if (!mounted) return;
      setState(() {
        _snapping = true;
        _drag = ok ? 1 : 0;
      });
      if (ok) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (mounted) setState(() => _drag = 0);
      }
    } else {
      setState(() {
        _snapping = true;
        _drag = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    const h = 56.0;
    const thumb = 46.0;

    return LayoutBuilder(builder: (context, constraints) {
      final maxX = constraints.maxWidth - thumb - 10;
      return Opacity(
        opacity: widget.enabled ? 1 : 0.45,
        child: GestureDetector(
          onHorizontalDragUpdate: widget.enabled
              ? (d) => setState(() {
                    _snapping = false;
                    final delta = (isRtl ? -d.delta.dx : d.delta.dx) / maxX;
                    _drag = (_drag + delta).clamp(0.0, 1.0);
                  })
              : null,
          onHorizontalDragEnd: widget.enabled ? (_) => _release() : null,
          child: SizedBox(
            height: h,
            child: Stack(children: [
              // Dark track, like the reference pill.
              Container(
                height: h,
                decoration: BoxDecoration(
                  color: const Color(0xFF17181C),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // Brand fill growing behind the thumb.
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: _snapping
                      ? const Duration(milliseconds: 240)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  width: (thumb + 10 + maxX * _drag)
                      .clamp(thumb + 10, constraints.maxWidth),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              // Label + chevrons.
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: thumb + 14, end: 16),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    for (final o in [0.35, 0.6, 1.0])
                      Icon(
                        isRtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 18,
                        color: (_drag > 0.5 ? Colors.white : scheme.primary)
                            .withValues(alpha: o),
                      ),
                  ]),
                ),
              ),
              // White circular thumb with the brand car icon.
              AnimatedPositionedDirectional(
                duration: _snapping
                    ? const Duration(milliseconds: 240)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                start: 5 + maxX * _drag,
                top: 5,
                child: Container(
                  width: thumb,
                  height: thumb,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x40000000), blurRadius: 10),
                    ],
                  ),
                  child: Icon(Icons.directions_car_rounded,
                      color: scheme.primary, size: 22),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }
}
