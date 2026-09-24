import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/responsive.dart';

/// The reference "model year" tab strip (Ferrari-style):
///
///   2017   2018   ┌────────┐   2020   2021
///                 │ MODEL  │
///                 │  2019  │
///                 └────────┘
///
/// Inactive tabs are small muted labels sitting on the strip's centerline;
/// the ACTIVE tab is a TALL two-line brand card — a tiny uppercase caption
/// (or a small accent line when no caption is given) above the big bold
/// value — filling the strip's height so it visibly towers over the row.
/// Flat by design (no shadows), animated with a 260ms ease-out morph.
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

  /// Tiny uppercase word inside the active card, above the label — the
  /// reference's "MODEL". Null shows a small accent tick line instead.
  final String? caption;

  /// Scrollable row for variable tab counts; false = equal-width fit.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stripHeight = context.rs(58);

    Widget item(int i, {bool expanded = false}) {
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
                SizedBox(height: context.rs(4)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tabs[i],
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: context.rf(13.5),
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
                  color: scheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            );

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (i == index) return;
          HapticFeedback.selectionClick();
          onChanged(i);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: selected ? stripHeight : stripHeight * 0.62,
          constraints: BoxConstraints(minWidth: context.rs(58)),
          padding: EdgeInsets.symmetric(
            horizontal: context.rs(selected ? 14 : (expanded ? 4 : 10)),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(context.rs(15)),
          ),
          child: inner,
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
          itemBuilder: (context, i) => Center(child: item(i)),
        ),
      );
    }
    return SizedBox(
      height: stripHeight,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(child: Center(child: item(i, expanded: true))),
        ],
      ),
    );
  }
}
