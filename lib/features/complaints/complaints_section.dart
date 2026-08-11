import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../home/presentation/widgets/home_bits.dart';
import 'complaint_submit_sheet.dart';
import 'complaint_tracker_sheet.dart';

/// The complaints entry card embedded in the contact screen — the same
/// cycle as the website's contact-page complaints: submit a complaint,
/// then follow it (status + staff replies) in the tracker.
final class ComplaintsSection extends StatelessWidget {
  const ComplaintsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(context.rs(16)),
      decoration: softCardDecoration(context, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: context.rs(42),
              height: context.rs(42),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent_rounded,
                  size: 20, color: scheme.primary),
            ),
            SizedBox(width: context.rs(11)),
            Expanded(
              child: Text(t.cmpTitle,
                  style: TextStyle(
                      fontSize: context.rf(16), fontWeight: FontWeight.w800)),
            ),
          ]),
          SizedBox(height: context.rs(12)),
          _ActionTile(
            icon: Icons.edit_note_rounded,
            title: t.cmpSubmit,
            subtitle: t.cmpSubmitSub,
            onTap: () => showComplaintSubmitSheet(context),
          ),
          SizedBox(height: context.rs(8)),
          _ActionTile(
            icon: Icons.fact_check_outlined,
            title: t.cmpTrack,
            subtitle: t.cmpTrackSub,
            onTap: () => showComplaintTrackerSheet(context),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 240.ms);
  }
}

final class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.all(context.rs(12)),
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(
              width: context.rs(36),
              height: context.rs(36),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: scheme.primary),
            ),
            SizedBox(width: context.rs(11)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: context.rf(13),
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: context.rs(2)),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.rf(10.5),
                          height: 1.4,
                          color: scheme.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
            SizedBox(width: context.rs(6)),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 20,
              color: scheme.onSurface.withValues(alpha: 0.4),
            ),
          ]),
        ),
      ),
    );
  }
}
