import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../settings/bloc/locale_cubit.dart';
import '../../bloc/profile_cubit.dart';
import '../../domain/profile_models.dart';
import '../widgets/profile_bits.dart';

/// بياناتي — the website profile's personal-data tab as one sheet:
/// Arabic/English names, gender, country → city, address, then account
/// type + identity/CR. Save = update-profile then update-identity.
void showMyDataSheet(BuildContext context, ProfileCubit cubit) {
  cubit.ensureLookups();
  showProfileSheet<void>(
    context,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _MyDataSheet()),
  );
}

final class _MyDataSheet extends StatefulWidget {
  const _MyDataSheet();

  @override
  State<_MyDataSheet> createState() => _MyDataSheetState();
}

final class _MyDataSheetState extends State<_MyDataSheet> {
  final _firstAr = TextEditingController();
  final _middleAr = TextEditingController();
  final _lastAr = TextEditingController();
  final _firstEn = TextEditingController();
  final _middleEn = TextEditingController();
  final _lastEn = TextEditingController();
  final _address = TextEditingController();
  final _identity = TextEditingController();
  final _cr = TextEditingController();

  String? _genderId;
  String? _countryId;
  String? _cityId;
  String? _custGroupId;

  final Map<String, String> _errors = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<ProfileCubit>().state.user;
    if (u != null) {
      _firstAr.text = u.firstNameAr ?? '';
      _middleAr.text = u.middleNameAr ?? '';
      _lastAr.text = u.lastNameAr ?? '';
      _firstEn.text = u.firstNameEn ?? '';
      _middleEn.text = u.middleNameEn ?? '';
      _lastEn.text = u.lastNameEn ?? '';
      _address.text = u.address ?? '';
      _identity.text = u.identity ?? '';
      _cr.text = u.tradeNo ?? '';
      _genderId = u.genderId?.toString();
      _countryId = u.countryId;
      _cityId = u.cityId;
      _custGroupId = u.custGroupId;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstAr, _middleAr, _lastAr, _firstEn, _middleEn, _lastEn,
      _address, _identity, _cr,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  AccountType? _selectedType(List<AccountType>? types) {
    if (types == null || _custGroupId == null) return null;
    for (final t in types) {
      if (t.id == _custGroupId) return t;
    }
    return null;
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final lang = context.read<LocaleCubit>().state.languageCode;
    final cubit = context.read<ProfileCubit>();
    final user = cubit.state.user;
    final guid = user?.guid;
    if (guid == null) return;

    final required = bi(lang, ar: 'مطلوب', en: 'Required');
    final type = _selectedType(cubit.state.accountTypes);
    setState(() {
      _errors.clear();
      if (_firstAr.text.trim().isEmpty) _errors['firstAr'] = required;
      if (_lastAr.text.trim().isEmpty) _errors['lastAr'] = required;
      if (_firstEn.text.trim().isEmpty) _errors['firstEn'] = required;
      if (_lastEn.text.trim().isEmpty) _errors['lastEn'] = required;
      if (type != null) {
        if (type.needIdentity && _identity.text.trim().isEmpty) {
          _errors['identity'] = required;
        }
        if (!type.needIdentity && _cr.text.trim().isEmpty) {
          _errors['cr'] = required;
        }
      }
    });
    if (_errors.isNotEmpty) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final repo = cubit.repo;

    final profile = await repo.updateProfile(
      guid: guid,
      firstNameAr: _firstAr.text.trim(),
      middleNameAr: _middleAr.text.trim(),
      lastNameAr: _lastAr.text.trim(),
      firstNameEn: _firstEn.text.trim(),
      middleNameEn: _middleEn.text.trim(),
      lastNameEn: _lastEn.text.trim(),
      genderId: _genderId == null ? null : int.tryParse(_genderId!),
      countryId: _countryId,
      cityId: _cityId,
      address: _address.text.trim(),
    );
    if (!mounted) return;
    if (!profile.ok) {
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(t.pfSaveFailed)));
      return;
    }

    // Second leg — account type + identity/CR, like the website tab.
    final identity = _identity.text.trim();
    final cr = _cr.text.trim();
    if (_custGroupId != null || identity.isNotEmpty || cr.isNotEmpty) {
      final id = await repo.updateIdentity(
        guid: guid,
        identity: identity.isEmpty ? null : identity,
        cr: cr.isEmpty ? null : cr,
        custGroupId: _custGroupId,
      );
      if (!mounted) return;
      if (!id.ok) {
        setState(() {
          _busy = false;
          if (id.error == 'identity_exists') {
            _errors['identity'] = t.pfIdentityExists;
          }
        });
        messenger.showSnackBar(SnackBar(
            content: Text(id.error == 'identity_exists'
                ? t.pfIdentityExists
                : t.pfSaveFailed)));
        return;
      }
    }

    await cubit.refreshUser();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(content: Text(t.pfSaved)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final state = context.watch<ProfileCubit>().state;

    return ProfileSheetShell(
      title: t.pfMyData,
      icon: Icons.badge_outlined,
      children: [
        if (!state.lookupsReady && state.lookupsBusy)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.rs(56)),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (!state.lookupsReady)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.rs(48)),
            child: Center(
              child: TextButton(
                onPressed: () => context.read<ProfileCubit>().ensureLookups(),
                child: Text(t.homeErrorRetry, textAlign: TextAlign.center),
              ),
            ),
          )
        else
          ..._form(t, lang, state),
      ],
    );
  }

  List<Widget> _form(AppLocalizations t, String lang, ProfileState state) {
    final settings = state.settings!;
    final types = state.accountTypes!;
    final type = _selectedType(types);
    final cities = settings.citiesOf(_countryId);

    Widget gap([double h = 14]) => SizedBox(height: context.rs(h));

    Widget section(String label) => Padding(
          padding: EdgeInsetsDirectional.only(
              start: 2, bottom: context.rs(8), top: context.rs(6)),
          child: Text(label,
              style: TextStyle(
                  fontSize: context.rf(13.5), fontWeight: FontWeight.w800)),
        );

    Widget nameRow({
      required TextEditingController first,
      required TextEditingController middle,
      required TextEditingController last,
      required String firstErrKey,
      required String lastErrKey,
      TextDirection? dir,
    }) =>
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProfileField(
                label: t.pfFirstName,
                controller: first,
                errorText: _errors[firstErrKey],
                textDirection: dir,
                autofillHints: const [AutofillHints.givenName],
              ),
            ),
            SizedBox(width: context.rs(8)),
            Expanded(
              child: ProfileField(
                label: t.pfMiddleName,
                controller: middle,
                textDirection: dir,
                autofillHints: const [AutofillHints.middleName],
              ),
            ),
            SizedBox(width: context.rs(8)),
            Expanded(
              child: ProfileField(
                label: t.pfLastName,
                controller: last,
                errorText: _errors[lastErrKey],
                textDirection: dir,
                autofillHints: const [AutofillHints.familyName],
              ),
            ),
          ],
        );

    return [
      section(t.pfNameAr),
      nameRow(
        first: _firstAr,
        middle: _middleAr,
        last: _lastAr,
        firstErrKey: 'firstAr',
        lastErrKey: 'lastAr',
        dir: TextDirection.rtl,
      ),
      gap(),
      section(t.pfNameEn),
      nameRow(
        first: _firstEn,
        middle: _middleEn,
        last: _lastEn,
        firstErrKey: 'firstEn',
        lastErrKey: 'lastEn',
        dir: TextDirection.ltr,
      ),
      gap(18),
      AppDropdown<String>(
        label: t.pfGender,
        value: _genderId,
        items: [
          for (final g in settings.genders)
            if (g.id != null)
              AppDropdownItem(value: g.id!, label: g.name(lang)),
        ],
        onChanged: (v) => setState(() => _genderId = v),
      ),
      gap(),
      AppDropdown<String>(
        label: t.pfCountry,
        value: _countryId,
        items: [
          for (final c in settings.countries)
            if (c.id != null)
              AppDropdownItem(value: c.id!, label: c.name(lang)),
        ],
        onChanged: (v) => setState(() {
          _countryId = v;
          _cityId = null;
        }),
      ),
      gap(),
      AppDropdown<String>(
        label: t.pfCity,
        value: _cityId,
        enabled: cities.isNotEmpty,
        items: [
          for (final c in cities)
            if (c.id != null)
              AppDropdownItem(value: c.id!, label: c.name(lang)),
        ],
        onChanged: (v) => setState(() => _cityId = v),
      ),
      gap(),
      ProfileField(
        label: t.pfAddress,
        controller: _address,
        keyboardType: TextInputType.streetAddress,
        autofillHints: const [AutofillHints.fullStreetAddress],
      ),
      gap(18),
      AppDropdown<String>(
        label: t.pfAccountType,
        value: _custGroupId,
        items: [
          for (final at in types)
            if (at.id != null)
              AppDropdownItem(value: at.id!, label: at.name(lang)),
        ],
        onChanged: (v) => setState(() => _custGroupId = v),
      ),
      gap(),
      if (type == null || type.needIdentity)
        ProfileField(
          label: t.pfIdentity,
          controller: _identity,
          errorText: _errors['identity'],
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
        )
      else
        ProfileField(
          label: t.pfCr,
          controller: _cr,
          errorText: _errors['cr'],
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
        ),
      gap(22),
      ProfileSaveButton(label: t.pfSave, busy: _busy, onPressed: _save),
    ];
  }
}
