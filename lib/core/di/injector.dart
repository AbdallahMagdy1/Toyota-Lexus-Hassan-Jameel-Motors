import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/router/app_router.dart';
import '../../features/account/bloc/active_car_cubit.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/cart/bloc/cart_cubit.dart';
import '../../features/parts/bloc/parts_cart_cubit.dart';
import '../../features/home/data/home_repository.dart';
import '../../features/onboarding/data/onboarding_repository.dart';
import '../../features/online_store/bloc/collections_cubits.dart';
import '../../features/online_store/data/online_store_repository.dart';
import '../../features/notifications/notifications.dart';
import '../../features/profile/bloc/avatar_cubit.dart';
import '../../features/settings/bloc/locale_cubit.dart';
import '../../features/vehicles/data/vehicles_repository.dart';
import '../../shared/navigation/side_menu.dart';
import '../../features/settings/bloc/theme_cubit.dart';
import '../../features/settings/bloc/store_links_cubit.dart';
import '../../features/settings/data/branding_repository.dart';
import '../../features/settings/data/store_links_repository.dart';
import '../network/api_client.dart';
import '../network/swr_cache.dart';
import '../storage/local_store.dart';

final sl = GetIt.instance;

/// The running store app's brand ('toyota' | 'lexus'), set once at bootstrap.
/// The ERP's SMS gateway keys sender names off this: 1 = Toyota, 2 = Lexus.
String appBrand = 'toyota';
int get appBrandId => appBrand == 'lexus' ? 2 : 1;

Future<void> setupInjector({String brand = 'toyota'}) async {
  appBrand = brand;
  final prefs = await SharedPreferences.getInstance();

  sl
    ..registerSingleton<LocalStore>(LocalStore(prefs))
    ..registerLazySingleton<ApiClient>(() {
      final client = ApiClient();
      // Every request identifies its store app — the backend brand-scopes
      // person-level data (garage, notifications, …) off this header.
      client.dio.options.headers['X-Brand'] = brand;
      // Stale-while-revalidate: catalog GETs paint instantly from disk and
      // refresh silently in the background (see SwrCacheInterceptor).
      client.dio.interceptors.add(SwrCacheInterceptor(client.dio, prefs));
      return client;
    })
    ..registerLazySingleton<BrandingRepository>(
      () => BrandingRepository(sl(), sl()),
    )
    ..registerLazySingleton<StoreLinksRepository>(
      () => StoreLinksRepository(sl()),
    )
    ..registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepository(sl()),
    )
    ..registerLazySingleton<AuthRepository>(() => AuthRepository(sl(), sl()))
    ..registerLazySingleton<HomeRepository>(() => HomeRepository(sl()))
    ..registerLazySingleton<OnlineStoreRepository>(() => OnlineStoreRepository(sl()))
    ..registerLazySingleton<VehiclesRepository>(() => VehiclesRepository(sl()))
    // App-lifetime blocs + THE router, created exactly once. Keeping them in
    // DI (not in a widget's build) means a locale/theme/brand change rebuilds
    // the UI in place — navigation stack and screen state survive, like the
    // website's instant language toggle.
    ..registerLazySingleton<ThemeCubit>(
        () => ThemeCubit(sl(), sl(), fixedBrand: brand))
    ..registerLazySingleton<StoreLinksCubit>(() => StoreLinksCubit(sl()))
    ..registerLazySingleton<LocaleCubit>(() => LocaleCubit(sl()))
    ..registerLazySingleton<AuthBloc>(() => AuthBloc(sl(), sl()))
    ..registerLazySingleton<ActiveCarCubit>(() => ActiveCarCubit(prefs))
    ..registerLazySingleton<FavoritesCubit>(() => FavoritesCubit(sl()))
    ..registerLazySingleton<CartCubit>(() => CartCubit(sl(), sl(), sl()))
    ..registerLazySingleton<PartsCartCubit>(() => PartsCartCubit(sl()))
    ..registerLazySingleton<MenuCubit>(MenuCubit.new)
    ..registerLazySingleton<NotificationsCubit>(() => NotificationsCubit(prefs))
    // App-wide profile photo: the side menu and the home app bar render long
    // before the profile screen exists, so the blob is fetched once here.
    ..registerLazySingleton<AvatarCubit>(() => AvatarCubit(sl()))
    ..registerLazySingleton<GoRouter>(
      () => buildRouter(authBloc: sl(), store: sl()),
    );
}
