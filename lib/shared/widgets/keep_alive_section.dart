import 'package:flutter/material.dart';

/// Keeps a scroll-list section's State alive when it scrolls out of the
/// viewport. Sections that own their data (a FutureBuilder future, a
/// section-local cubit, a page controller) would otherwise be unmounted by
/// the ListView and REFETCH on every scroll-back — this pins them for the
/// lifetime of the list.
final class KeepAliveSection extends StatefulWidget {
  const KeepAliveSection({super.key, required this.child});

  final Widget child;

  @override
  State<KeepAliveSection> createState() => _KeepAliveSectionState();
}

final class _KeepAliveSectionState extends State<KeepAliveSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
