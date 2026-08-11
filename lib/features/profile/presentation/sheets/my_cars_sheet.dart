import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../account/data/account_repository.dart';
import '../../../account/domain/account_models.dart';
import '../../../account/presentation/garage_sheets.dart';
import '../../../home/presentation/widgets/home_bits.dart';
import '../../../settings/bloc/locale_cubit.dart';
import '../widgets/profile_bits.dart';

/// سياراتي — the registered home's garage, reachable from the profile hub:
/// each car opens the SAME Vehicle Hub sheet; the add-car row opens the
/// SAME add-car flow (garage_sheets.dart owns both).
void showMyCarsSheet(BuildContext context, {required int userId}) {
  showProfileSheet<void>(
    context,
    // Follow-up sheets are opened on the CALLER's context — the picker pops
    // itself first, so its own context would be defunct by then.
    builder: (_) => _MyCarsSheet(
      userId: userId,
      onOpenCar: (car) => showVehicleHubSheet(context, car: car),
      onAddCar: () => showAddCarSheet(context),
    ),
  );
}

final class _MyCarsSheet extends StatefulWidget {
  const _MyCarsSheet({
    required this.userId,
    required this.onOpenCar,
    required this.onAddCar,
  });

  final int userId;
  final ValueChanged<GarageCar> onOpenCar;
  final VoidCallback onAddCar;

  @override
  State<_MyCarsSheet> createState() => _MyCarsSheetState();
}

final class _MyCarsSheetState extends State<_MyCarsSheet> {
  late final AccountRepository _repo = AccountRepository(sl<ApiClient>());
  List<GarageCar>? _cars;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Instant paint from the registered-home cache, then refresh.
    _cars = _repo.cachedHome(widget.userId)?.garage;
    _load();
  }

  Future<void> _load() async {
    try {
      final cars = await _repo.garage(widget.userId);
      if (!mounted) return;
      setState(() {
        _cars = cars;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = _cars == null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    final cars = _cars;

    return ProfileSheetShell(
      title: t.pfMyCars,
      icon: Icons.directions_car_outlined,
      children: [
        if (cars == null && !_failed)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.rs(56)),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (cars == null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.rs(48)),
            child: Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _failed = false);
                  _load();
                },
                child: Text(t.homeErrorRetry, textAlign: TextAlign.center),
              ),
            ),
          )
        else ...[
          if (cars.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.rs(28)),
              child: Column(
                children: [
                  Icon(Icons.no_crash_outlined,
                      size: 44,
                      color: scheme.onSurface.withValues(alpha: 0.25)),
                  SizedBox(height: context.rs(10)),
                  Text(
                    t.acAddCarSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: context.rf(12.5),
                        height: 1.5,
                        color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            )
          else
            for (final car in cars)
              Padding(
                padding: EdgeInsets.only(bottom: context.rs(8)),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onOpenCar(car);
                    },
                    child: Container(
                      padding: EdgeInsets.all(context.rs(12)),
                      decoration: softCardDecoration(context, radius: 16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: context.rs(72),
                              height: context.rs(48),
                              child: HomeImage(
                                  url: car.image,
                                  fit: BoxFit.contain,
                                  logicalWidth: 80),
                            ),
                          ),
                          SizedBox(width: context.rs(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${car.displayName(lang)} ${car.year ?? ''}'
                                      .trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: context.rf(13),
                                      fontWeight: FontWeight.w800),
                                ),
                                if (car.maskedPlate(lang).isNotEmpty)
                                  Text(
                                    car.maskedPlate(lang),
                                    style: TextStyle(
                                        fontSize: context.rf(10.5),
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.55)),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color:
                                  scheme.onSurface.withValues(alpha: 0.35)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          SizedBox(height: context.rs(10)),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onAddCar();
            },
            icon: const Icon(Icons.add_rounded, size: 19),
            label: Text(t.acAddCarCta),
          ),
        ],
      ],
    );
  }
}
