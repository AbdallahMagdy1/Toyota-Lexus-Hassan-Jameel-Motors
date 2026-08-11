import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../bloc/profile_cubit.dart';
import '../widgets/profile_bits.dart';

/// حذف الحساب — the destructive flow: warning, type-the-word confirmation
/// (حذف / DELETE), red confirm; on success sign out and land on welcome.
void showDeleteAccountSheet(BuildContext context, ProfileCubit cubit) {
  showProfileSheet<void>(
    context,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _DeleteAccountSheet()),
  );
}

final class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

final class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  bool _matches(String word) =>
      _confirm.text.trim().toLowerCase() == word.trim().toLowerCase();

  Future<void> _delete() async {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ProfileCubit>();
    final guid = cubit.state.user?.guid;
    if (guid == null || !_matches(t.pfDeleteWord)) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final ok = await cubit.repo.deleteAccount(guid);
    if (!mounted) return;
    if (!ok) {
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(t.pfSaveFailed)));
      return;
    }
    Navigator.of(context).pop();
    sl<AuthBloc>().add(const AuthSignOutRequested());
    router.go(Routes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final enabled = _matches(t.pfDeleteWord);

    return ProfileSheetShell(
      title: t.pfDeleteAccount,
      icon: Icons.delete_outline_rounded,
      children: [
        Container(
          padding: EdgeInsets.all(context.rs(14)),
          decoration: BoxDecoration(
            color: scheme.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 20, color: scheme.error),
              SizedBox(width: context.rs(10)),
              Expanded(
                child: Text(
                  t.pfDeleteWarning,
                  style: TextStyle(
                      fontSize: context.rf(12.5),
                      height: 1.5,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.rs(18)),
        ProfileField(
          label: t.pfDeleteConfirmHint,
          controller: _confirm,
          hint: t.pfDeleteWord,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: context.rs(22)),
        ProfileSaveButton(
          label: t.pfDeleteAccount,
          busy: _busy,
          enabled: enabled,
          destructive: true,
          onPressed: _delete,
        ),
      ],
    );
  }
}
