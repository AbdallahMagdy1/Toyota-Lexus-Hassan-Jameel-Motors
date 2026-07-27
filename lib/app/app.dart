import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injector.dart';
import '../core/theme/theme_factory.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/cart/bloc/cart_cubit.dart';
import '../features/parts/bloc/parts_cart_cubit.dart';
import '../features/online_store/bloc/collections_cubits.dart';
import '../features/settings/bloc/locale_cubit.dart';
import '../features/settings/bloc/theme_cubit.dart';
import '../shared/navigation/side_menu.dart';
import '../l10n/app_localizations.dart';

final class HjApp extends StatelessWidget {
  const HjApp({super.key});

  @override
  Widget build(BuildContext context) {
    // App-lifetime singletons from DI — .value providers never recreate them,
    // so locale/theme changes re-render in place without resetting navigation.
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<LocaleCubit>.value(value: sl<LocaleCubit>()),
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
        BlocProvider<FavoritesCubit>.value(value: sl<FavoritesCubit>()),
        BlocProvider<CartCubit>.value(value: sl<CartCubit>()),
        BlocProvider<PartsCartCubit>.value(value: sl<PartsCartCubit>()),
        BlocProvider<MenuCubit>.value(value: sl<MenuCubit>()),
      ],
      child: const _AppView(),
    );
  }
}

final class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final locale = context.watch<LocaleCubit>().state;

    return MaterialApp.router(
      title: 'Hassan Jameel',
      debugShowCheckedModeBanner: false,
      routerConfig: sl<GoRouter>(),
      // Device font-size settings can blow the UI up on phones (e.g. Oppo
      // F11 with "large" text). Clamp the scale so layouts stay intact.
      builder: (context, child) {
        Widget app = MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.1,
          child: child ?? const SizedBox.shrink(),
        );
        // Android only: paint the system status + navigation bars to match
        // the theme — white bars with dark icons in light mode, dark bars
        // with light icons in dark mode. Re-applies live on theme toggles.
        if (!kIsWeb && Platform.isAndroid) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final barColor = isDark ? const Color(0xFF0A0B0D) : Colors.white;
          app = AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: barColor,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: barColor,
              systemNavigationBarDividerColor: barColor,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
            ),
            child: app,
          );
        }
        return app;
      },
      theme: ThemeFactory.build(themeState.brand, Brightness.light),
      darkTheme: ThemeFactory.build(themeState.brand, Brightness.dark),
      themeMode: themeState.mode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
