import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/bloc/locale_cubit.dart';
import '../../bloc/profile_cubit.dart';
import '../widgets/profile_bits.dart';

/// بيانات الاتصال — phone and email, each with its own save
/// (Site_User_UpdatePhone / Site_User_UpdateEmail; *_exists errors map to
/// inline messages under the field).
void showContactDataSheet(BuildContext context, ProfileCubit cubit) {
  showProfileSheet<void>(
    context,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _ContactDataSheet()),
  );
}

final class _ContactDataSheet extends StatefulWidget {
  const _ContactDataSheet();

  @override
  State<_ContactDataSheet> createState() => _ContactDataSheetState();
}

final class _ContactDataSheetState extends State<_ContactDataSheet> {
  final _phone = TextEditingController();
  final _email = TextEditingController();

  String? _phoneError;
  String? _emailError;
  bool _phoneBusy = false;
  bool _emailBusy = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileCubit>().state;
    _phone.text = state.user?.phone ?? '';
    _email.text = state.user?.email ?? '';
  }

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _savePhone() async {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ProfileCubit>();
    final guid = cubit.state.user?.guid;
    final phone = _phone.text.trim();
    if (guid == null) return;
    if (phone.isEmpty) {
      final lang = context.read<LocaleCubit>().state.languageCode;
      setState(() => _phoneError = bi(lang, ar: 'مطلوب', en: 'Required'));
      return;
    }
    setState(() {
      _phoneBusy = true;
      _phoneError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final res = await cubit.repo.updatePhone(guid: guid, phone: phone);
    if (!mounted) return;
    if (res.ok) {
      await cubit.refreshUser();
      if (!mounted) return;
      setState(() => _phoneBusy = false);
      messenger.showSnackBar(SnackBar(content: Text(t.pfSaved)));
    } else {
      setState(() {
        _phoneBusy = false;
        _phoneError =
            res.error == 'phone_exists' ? t.pfPhoneExists : t.pfSaveFailed;
      });
    }
  }

  Future<void> _saveEmail() async {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ProfileCubit>();
    final guid = cubit.state.user?.guid;
    final email = _email.text.trim();
    if (guid == null) return;
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!valid) {
      final lang = context.read<LocaleCubit>().state.languageCode;
      setState(() => _emailError = bi(lang,
          ar: 'بريد إلكتروني غير صحيح', en: 'Invalid email address'));
      return;
    }
    setState(() {
      _emailBusy = true;
      _emailError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final res = await cubit.repo.updateEmail(guid: guid, email: email);
    if (!mounted) return;
    if (res.ok) {
      await cubit.refreshUser();
      if (!mounted) return;
      setState(() => _emailBusy = false);
      messenger.showSnackBar(SnackBar(content: Text(t.pfSaved)));
    } else {
      setState(() {
        _emailBusy = false;
        _emailError =
            res.error == 'email_exists' ? t.pfEmailExists : t.pfSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return ProfileSheetShell(
      title: t.pfContactData,
      icon: Icons.alternate_email_rounded,
      children: [
        ProfileField(
          label: t.pfPhone,
          controller: _phone,
          errorText: _phoneError,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          autofillHints: const [AutofillHints.telephoneNumber],
          textInputAction: TextInputAction.done,
        ),
        SizedBox(height: context.rs(12)),
        ProfileSaveButton(
            label: t.pfSave, busy: _phoneBusy, onPressed: _savePhone),
        SizedBox(height: context.rs(20)),
        const Divider(),
        SizedBox(height: context.rs(20)),
        ProfileField(
          label: t.pfEmail,
          controller: _email,
          errorText: _emailError,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
        ),
        SizedBox(height: context.rs(12)),
        ProfileSaveButton(
            label: t.pfSave, busy: _emailBusy, onPressed: _saveEmail),
      ],
    );
  }
}
