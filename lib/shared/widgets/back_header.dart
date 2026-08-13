import 'package:flutter/material.dart';

import '../../app/router/routes.dart';
import '../../core/utils/responsive.dart';

/// The in-screen back header used by every pushed page: back chevron
/// (walks [appBack]), centered bold title, optional trailing action —
/// one widget instead of the hand-copied Row on each screen.
final class BackHeader extends StatelessWidget {
  const BackHeader({super.key, required this.title, this.trailing});

  final String title;

  /// Optional end-side action; a 48-wide spacer keeps the title centered
  /// when absent.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(context.rs(8), context.rs(6), context.rs(8), 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => appBack(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: context.rf(17), fontWeight: FontWeight.w800),
            ),
          ),
          trailing ?? const SizedBox(width: 48),
        ],
      ),
    );
  }
}
