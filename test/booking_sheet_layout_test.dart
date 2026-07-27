import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hj_mobile/core/di/injector.dart';
import 'package:hj_mobile/features/account/domain/account_models.dart';
import 'package:hj_mobile/features/account/presentation/maintenance_booking_sheet.dart';
import 'package:hj_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:hj_mobile/features/settings/bloc/locale_cubit.dart';
import 'package:hj_mobile/features/settings/bloc/theme_cubit.dart';
import 'package:hj_mobile/core/theme/app_brand.dart';
import 'package:hj_mobile/core/theme/theme_factory.dart';
import 'package:hj_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reproduces the reported "BoxConstraints forces an infinite width" crash
/// when opening the maintenance-booking sheet.
void main() {
  testWidgets('maintenance booking sheet lays out without exceptions',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setupInjector();

    const car = GarageCar(
      vin: 'JT123456789012345',
      brandEn: 'Toyota',
      modelEn: 'YARIS',
      year: '2026',
      modelCode: 'NGC101',
      productGroupId: 'YARIS',
      type: 'T1',
    );

    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<LocaleCubit>.value(value: sl<LocaleCubit>()),
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
      ],
      child: MaterialApp(
      locale: const Locale('ar'),
      // The REAL app theme — its button themes are what broke layout on
      // device while a default-theme test passed.
      theme: ThemeFactory.build(kFallbackBrands['toyota']!, Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  showMaintenanceBookingSheet(context, car: car),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    )));

    await tester.tap(find.text('open'));
    // Fixed pumps (no pumpAndSettle — spinners animate forever).
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final e = tester.takeException();
      expect(e, isNull, reason: 'layout exception after ${i * 100}ms: $e');
    }

    // Walk the 3 steps (validation errors are fine — layout must hold).
    for (var step = 0; step < 3; step++) {
      final next = find.text('التالي');
      if (next.evaluate().isEmpty) break;
      await tester.tap(next, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull,
          reason: 'layout exception on step ${step + 2}');
    }
  });
}
