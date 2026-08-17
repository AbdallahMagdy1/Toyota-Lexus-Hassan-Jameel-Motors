import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';
import '../../features/home/presentation/widgets/home_bits.dart'
    show softCardDecoration;

/// One quick-link action: icon + label + tap.
typedef QuickLinkAction = (IconData, String, VoidCallback);

/// "Quick Links"-style strip (reference mock): ONE white floating panel
/// holding a horizontal row — the first action as a filled brand tile
/// (white icon + label inside), the rest as plain dark icons with labels
/// below, and a tiny scroll-progress bar underneath when the row overflows.
/// Progress updates through a ValueNotifier, so scrolling repaints only the
/// 4px indicator — never the panel or the tiles.
final class QuickLinksPanel extends StatefulWidget {
  const QuickLinksPanel({
    super.key,
    required this.actions,
    this.centered = false,
  });

  final List<QuickLinkAction> actions;

  /// Center the tiles instead of leading them (for short fixed sets) —
  /// also hugs the tiles vertically (no scroll-indicator strip).
  final bool centered;

  @override
  State<QuickLinksPanel> createState() => _QuickLinksPanelState();
}

final class _QuickLinksPanelState extends State<QuickLinksPanel> {
  /// 0..1 scroll progress; -1 = row fits, indicator hidden.
  final ValueNotifier<double> _progress = ValueNotifier(-1);

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  bool _onMetrics(ScrollMetrics metrics) {
    final max = metrics.maxScrollExtent;
    _progress.value = max <= 0 ? -1 : (metrics.pixels / max).clamp(0.0, 1.0);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget tile(int i) {
      final (icon, label, onTap) = widget.actions[i];
      // First action = the mock's filled brand tile.
      return i == 0
          ? _PrimaryTile(icon: icon, label: label, onTap: onTap)
          : _PlainTile(icon: icon, label: label, onTap: onTap);
    }

    // Centered mode hugs its children: tight symmetric padding, no
    // scroll-progress strip, and the row is exactly the tiles' height.
    if (widget.centered) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
        child: Container(
          decoration: softCardDecoration(context, radius: 22),
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.all(context.rs(8)),
          child: SizedBox(
            height: context.rs(78),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.actions.length; i++) ...[
                  if (i > 0) SizedBox(width: context.rs(14)),
                  tile(i),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
      child: Container(
        decoration: softCardDecoration(context, radius: 22),
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.fromLTRB(
            context.rs(8), context.rs(12), context.rs(8), context.rs(8)),
        child: Column(children: [
          SizedBox(
            height: context.rs(86),
            child: NotificationListener<ScrollMetricsNotification>(
              // Fires on first layout too, so the indicator knows
              // immediately whether the row overflows.
              onNotification: (n) => _onMetrics(n.metrics),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) => _onMetrics(n.metrics),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: context.rs(4)),
                  itemCount: widget.actions.length,
                  separatorBuilder: (_, _) => SizedBox(width: context.rs(6)),
                  itemBuilder: (context, i) => tile(i),
                ),
              ),
            ),
          ),
          // ── Tiny scroll-progress bar (brand on gray), mock-style ──
          ValueListenableBuilder<double>(
            valueListenable: _progress,
            builder: (context, p, _) {
              if (p < 0) return SizedBox(height: context.rs(4));
              return Padding(
                padding: EdgeInsets.only(top: context.rs(6)),
                child: Container(
                  width: context.rs(52),
                  height: context.rs(4),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Align(
                    alignment: AlignmentDirectional(-1 + 2 * p, 0),
                    child: Container(
                      width: context.rs(22),
                      height: context.rs(4),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

/// Filled brand tile — the mock's highlighted "Emergency Services" item:
/// white icon + tiny white label inside a brand rounded square.
final class _PrimaryTile extends StatelessWidget {
  const _PrimaryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: context.rs(78),
          padding: EdgeInsets.symmetric(horizontal: context.rs(6)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: context.rs(22), color: scheme.onPrimary),
              SizedBox(height: context.rs(6)),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.rf(9.5),
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: scheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plain item — dark icon with a small bold label below (the mock's
/// Lab Results / Radiology Results tiles).
final class _PlainTile extends StatelessWidget {
  const _PlainTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: context.rs(78),
          padding: EdgeInsets.symmetric(horizontal: context.rs(4)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: context.rs(24),
                  color: scheme.onSurface.withValues(alpha: 0.85)),
              SizedBox(height: context.rs(6)),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.rf(9.5),
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
