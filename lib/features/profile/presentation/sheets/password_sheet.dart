import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/crypto.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../bloc/profile_cubit.dart';
import '../widgets/profile_bits.dart';

/// كلمة المرور — old (optional: OTP-only accounts have none) + new +
/// confirm. Passwords are MD5'd client-side, matching the sign-in cycle.
void showPasswordSheet(BuildContext context, ProfileCubit cubit) {
  showProfileSheet<void>(
    context,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _PasswordSheet()),
  );
}

final class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

final class _PasswordSheetState extends State<_PasswordSheet> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  String? _oldError;
  String? _newError;
  String? _confirmError;
  bool _busy = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ProfileCubit>();
    final guid = cubit.state.user?.guid;
    if (guid == null) return;

    setState(() {
      _oldError = null;
      _newError = _new.text.length < 6 ? t.pfPasswordShort : null;
      _confirmError = _confirm.text != _new.text ? t.pfPasswordMismatch : null;
    });
    if (_newError != null || _confirmError != null) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final res = await cubit.repo.updatePassword(
      guid: guid,
      oldPasswordMd5: _old.text.isEmpty ? null : md5Hex(_old.text),
      newPasswordMd5: md5Hex(_new.text),
    );
    if (!mounted) return;
    if (res.ok) {
      messenger.showSnackBar(SnackBar(content: Text(t.pfSaved)));
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _oldError = res.error == 'wrong_old_password'
            ? t.pfWrongOldPassword
            : null;
      });
      if (res.error != 'wrong_old_password') {
        messenger.showSnackBar(SnackBar(content: Text(t.pfSaveFailed)));
      }
    }
  }

  Widget _eye(bool visible, VoidCallback onTap) => IconButton(
        onPressed: onTap,
        iconSize: 19,
        icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return ProfileSheetShell(
      title: t.pfChangePassword,
      icon: Icons.lock_outline_rounded,
      children: [
        ProfileField(
          label: t.pfOldPassword,
          controller: _old,
          errorText: _oldError,
          obscure: !_showOld,
          autofillHints: const [AutofillHints.password],
          suffix: _eye(_showOld, () => setState(() => _showOld = !_showOld)),
        ),
        SizedBox(height: context.rs(14)),
        ProfileField(
          label: t.pfNewPassword,
          controller: _new,
          errorText: _newError,
          obscure: !_showNew,
          autofillHints: const [AutofillHints.newPassword],
          suffix: _eye(_showNew, () => setState(() => _showNew = !_showNew)),
        ),
        SizedBox(height: context.rs(14)),
        ProfileField(
          label: t.pfConfirmPassword,
          controller: _confirm,
          errorText: _confirmError,
          obscure: !_showConfirm,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          suffix: _eye(
              _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
        ),
        SizedBox(height: context.rs(22)),
        ProfileSaveButton(
            label: t.pfChangePassword, busy: _busy, onPressed: _save),
      ],
    );
  }
}
