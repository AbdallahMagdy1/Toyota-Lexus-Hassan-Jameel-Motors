import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/responsive.dart';

/// The reference "model year" tab strip (Ferrari-style):
///
///                 ┌────────┐
///                 │ MODEL  │
///   2017   2018   │  2019  │   2020   2021
///                 └────────┘
///
/// The ACTIVE tab is a tall gradient brand ribbon spanning the strip's FULL
/// height — caption (or accent tick) above the big bold value — while the
/// inactive labels are small muted words sitting LOW, at the ribbon's lower
/// third, exactly like the reference. Flat (no shadows); the switch is a
/// 280ms ease-out morph of position + size + color.
final class RaisedTabBar extends StatelessWidget {
  const RaisedTabBar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
    this.caption,
    this.scrollable = false,
  });

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  /// Tiny uppercase word inside the active ribbon, above the label — the
  /// reference's "MODEL". Null shows a small accent tick line instead.
  final String? caption;

  /// Scrollable row for variable tab counts; false = equal-width fit.
  final bool scrollable;

  static const _dur = Duration(milliseconds: 280);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stripHeight = context.rs(78);

    // The reference ribbon's subtle red gradient: a touch darker at the
    // top, a touch brighter toward the bottom start corner.
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: AlignmentDirectional.bottomStart,
      colors: [
        Color.lerp(scheme.primary, Colors.black, 0.10)!,
        scheme.primary,
        Color.lerp(scheme.primary, Colors.white, 0.14)!,
      ],
    );

    Widget item(int i) {
      final selected = i == index;

      final inner = selected
          ? Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if ((caption ?? '').isNotEmpty)
                  Text(
                    caption!.toUpperCase(),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: context.rf(7.5),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: scheme.onPrimary.withValues(alpha: 0.72),
                    ),
                  )
                else
                  Container(
                    width: context.rs(14),
                    height: 2.4,
                    decoration: BoxDecoration(
                      color: scheme.onPrimary.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                SizedBox(height: context.rs(5)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tabs[i],
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: context.rf(14),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tabs[i],
                maxLines: 1,
                style: TextStyle(
                  fontSize: context.rf(11.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: scheme.onSurface.withValues(alpha: 0.42),
                ),
              ),
            );

      // Inactive labels sit LOW (the ribbon's lower third), the active
      // ribbon spans the whole strip — the reference geometry.
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (i == index) return;
          HapticFeedback.selectionClick();
          onChanged(i);
        },
        child: SizedBox(
          height: stripHeight,
          child: AnimatedAlign(
            duration: _dur,
            curve: _curve,
            alignment:
                selected ? Alignment.center : const Alignment(0, 0.58),
            child: AnimatedContainer(
              duration: _dur,
              curve: _curve,
              height: selected ? stripHeight : context.rs(26),
              constraints: BoxConstraints(minWidth: context.rs(62)),
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(selected ? 15 : 8)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected ? gradient : null,
                borderRadius: BorderRadius.circular(context.rs(16)),
              ),
              child: inner,
            ),
          ),
        ),
      );
    }

    if (scrollable) {
      return SizedBox(
        height: stripHeight,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: tabs.length,
          separatorBuilder: (_, _) => SizedBox(width: context.rs(4)),
          itemBuilder: (context, i) => item(i),
        ),
      );
    }
    return SizedBox(
      height: stripHeight,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) Expanded(child: item(i)),
        ],
      ),
    );
  }
}
