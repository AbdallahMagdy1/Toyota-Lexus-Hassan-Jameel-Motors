import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/di/injector.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/notifications.dart';
import '../../../settings/bloc/locale_cubit.dart';
import '../../bloc/profile_cubit.dart';
import '../../domain/profile_models.dart';
import '../widgets/profile_bits.dart';

/// الإشعارات — one sheet, two sections: the device push inbox (the existing
/// NotificationsCubit data, marked read on open — same behavior as
/// showNotificationsSheet) followed by the SERVER history from
/// /api/app/account/notifications/{guid} (Web_Notify, bilingual).
void showProfileNotificationsSheet(BuildContext context, ProfileCubit cubit) {
  sl<NotificationsCubit>().markAllRead();
  showProfileSheet<void>(
    context,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider.value(value: sl<NotificationsCubit>()),
      ],
      child: const _NotificationsSheet(),
    ),
  );
}

final class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

final class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<ServerNotification>? _history;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cubit = context.read<ProfileCubit>();
    final guid = cubit.state.user?.guid;
    if (guid == null) {
      setState(() => _loading = false);
      return;
    }
    final history = await cubit.repo.notifications(guid);
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  Widget _tile({
    required BuildContext context,
    required String title,
    required String body,
    required DateTime? date,
    IconData icon = Icons.notifications_active_outlined,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: context.rs(8)),
      padding: EdgeInsets.all(context.rs(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.rs(34),
            height: context.rs(34),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: scheme.primary),
          ),
          SizedBox(width: context.rs(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: context.rf(12.5),
                        fontWeight: FontWeight.w800)),
                if (body.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: context.rs(2)),
                    child: Text(body,
                        style: TextStyle(
                            fontSize: context.rf(11.5),
                            height: 1.4,
                            color:
                                scheme.onSurface.withValues(alpha: 0.65))),
                  ),
                if (date != null)
                  Padding(
                    padding: EdgeInsets.only(top: context.rs(3)),
                    child: Text(
                      DateFormat('yyyy/MM/dd – HH:mm').format(date),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                          fontSize: context.rf(9.5),
                          color: scheme.onSurface.withValues(alpha: 0.45)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    final local = context
        .watch<NotificationsCubit>()
        .state
        .$1;
    final history = _history ?? const <ServerNotification>[];
    final empty = !_loading && local.isEmpty && history.isEmpty;

    Widget sectionLabel(String s) => Padding(
          padding: EdgeInsetsDirectional.only(
              start: 2, top: context.rs(6), bottom: context.rs(8)),
          child: Text(
            s,
            style: TextStyle(
                fontSize: context.rf(11),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: scheme.onSurface.withValues(alpha: 0.5)),
          ),
        );

    return ProfileSheetShell(
      title: t.pfNotifications,
      icon: Icons.notifications_none_rounded,
      children: [
        if (empty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.rs(48)),
            child: Column(
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 44,
                    color: scheme.onSurface.withValues(alpha: 0.25)),
                SizedBox(height: context.rs(10)),
                Text(t.pfNoNotifications,
                    style: TextStyle(
                        fontSize: context.rf(13),
                        color: scheme.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          )
        else ...[
          if (local.isNotEmpty) ...[
            sectionLabel(t.notifTitle),
            for (final n in local)
              _tile(
                context: context,
                title: n.title(lang),
                body: n.body(lang),
                date: n.date,
              ),
            SizedBox(height: context.rs(8)),
          ],
          sectionLabel(t.pfNotifications),
          if (_loading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.rs(28)),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (history.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.rs(18)),
              child: Center(
                child: Text(t.pfNoNotifications,
                    style: TextStyle(
                        fontSize: context.rf(12.5),
                        color: scheme.onSurface.withValues(alpha: 0.5))),
              ),
            )
          else
            for (final n in history)
              _tile(
                context: context,
                title: n.title(lang),
                body: n.body(lang),
                date: n.createdDate,
                icon: Icons.campaign_outlined,
              ),
        ],
      ],
    );
  }
}
