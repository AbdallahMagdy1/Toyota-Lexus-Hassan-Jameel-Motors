import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/local_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/account/presentation/finance_requests_screen.dart';
import '../../features/account/presentation/service_tracking_screen.dart';
import '../../features/content/contact_screen.dart';
import '../../features/content/news_screen.dart';
import '../../features/finance/presentation/finance_screen.dart';
import '../../features/offers/presentation/offers_screen.dart';
import '../../features/online_store/presentation/online_store_screen.dart';
import '../../features/parts/presentation/parts_cart_screen.dart';
import '../../features/parts/presentation/parts_screen.dart';
import '../../features/used_cars/used_cars_screen.dart';
import '../../features/protection/presentation/protection_screen.dart';
import '../../features/vehicles/presentation/models_screen.dart';
import '../../features/welcome/presentation/welcome_screen.dart';
import '../../shared/navigation/bottom_nav.dart';
import '../../shared/navigation/side_menu.dart';
import '../../shared/widgets/brand_switch_fab.dart';
import 'routes.dart';

/// Re-triggers go_router's redirect whenever the AuthBloc emits.
final class _BlocRefresh extends ChangeNotifier {
  _BlocRefresh(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// One Scaffold for the whole app (ShellRoute). Screens are plain widgets
/// swapped inside it with the NZ AnimatedStackView transition: the incoming
/// screen slides fully in from the trailing edge OVER the static current
/// screen — pure slide, no fade (and it slides back out on pop).
GoRouter buildRouter({required AuthBloc authBloc, required LocalStore store}) {
  CustomTransitionPage<void> page(Widget child, GoRouterState state) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Forward navigation enters from the trailing edge (right in LTR,
          // left in RTL); the page below stays put, exactly like the NZ
          // AnimatedStackView. The slide is opaque, so nothing shows through.
          final isRtl = Directionality.of(context) == TextDirection.rtl;
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(isRtl ? -1.0 : 1.0, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            )),
            // Solid backdrop so the underlying page never bleeds through
            // while sliding.
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: child,
            ),
          );
        },
      );

  return GoRouter(
    initialLocation: store.onboardingDone ? Routes.welcome : Routes.onboarding,
    refreshListenable: _BlocRefresh(authBloc.stream),
    redirect: (context, state) {
      final status = authBloc.state.status;
      final signedIn = authBloc.state.isSignedIn;
      final authed = status == AuthStatus.authenticated;
      final onAuthPage = state.matchedLocation == Routes.signIn ||
          state.matchedLocation == Routes.signUp ||
          state.matchedLocation == Routes.forgot;
      final onEntry = state.matchedLocation == Routes.onboarding ||
          state.matchedLocation == Routes.welcome;

      // Guests may open the auth pages (benefit prompts route them there);
      // only fully-authenticated users are bounced back home.
      if (authed && (onAuthPage || onEntry)) return Routes.home;
      if (signedIn && onEntry) return Routes.home;
      if (!signedIn && state.matchedLocation == Routes.home) {
        return store.onboardingDone ? Routes.welcome : Routes.onboarding;
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            _AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: Routes.onboarding,
            pageBuilder: (context, state) => page(const OnboardingScreen(), state),
          ),
          GoRoute(
            path: Routes.welcome,
            pageBuilder: (context, state) => page(const WelcomeScreen(), state),
          ),
          GoRoute(
            path: Routes.signIn,
            pageBuilder: (context, state) => page(
              SignInScreen(
                prefillMobile: state.uri.queryParameters['mobile'],
                notice: state.uri.queryParameters['notice'],
              ),
              state,
            ),
          ),
          GoRoute(
            path: Routes.signUp,
            pageBuilder: (context, state) => page(
              SignUpScreen(
                prefillMobile: state.uri.queryParameters['mobile'],
                notFound: state.uri.queryParameters['notFound'] == '1',
              ),
              state,
            ),
          ),
          GoRoute(
            path: Routes.forgot,
            pageBuilder: (context, state) => page(const ForgotPasswordScreen(), state),
          ),
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) => page(const HomeScreen(), state),
          ),
          GoRoute(
            path: Routes.onlineStore,
            pageBuilder: (context, state) =>
                page(const OnlineStoreScreen(), state),
          ),
          GoRoute(
            path: Routes.models,
            pageBuilder: (context, state) => page(
                ModelsScreen(
                    initialCategory: state.uri.queryParameters['category']),
                state),
          ),
          GoRoute(
            path: Routes.offers,
            pageBuilder: (context, state) => page(
                OffersScreen(
                    initialTypeId:
                        int.tryParse(state.uri.queryParameters['type'] ?? '')),
                state),
          ),
          GoRoute(
            path: Routes.finance,
            pageBuilder: (context, state) => page(const FinanceScreen(), state),
          ),
          GoRoute(
            path: Routes.parts,
            pageBuilder: (context, state) => page(const PartsScreen(), state),
          ),
          GoRoute(
            path: Routes.protection,
            pageBuilder: (context, state) =>
                page(const ProtectionScreen(), state),
          ),
          GoRoute(
            path: Routes.news,
            pageBuilder: (context, state) => page(const NewsScreen(), state),
          ),
          GoRoute(
            path: Routes.contact,
            pageBuilder: (context, state) => page(const ContactScreen(), state),
          ),
          GoRoute(
            path: Routes.financeRequests,
            pageBuilder: (context, state) =>
                page(const FinanceRequestsScreen(), state),
          ),
          GoRoute(
            path: Routes.tracking,
            pageBuilder: (context, state) =>
                page(const ServiceTrackingScreen(), state),
          ),
          GoRoute(
            path: Routes.cart,
            pageBuilder: (context, state) => page(const CartScreen(), state),
          ),
          GoRoute(
            path: Routes.usedCars,
            pageBuilder: (context, state) =>
                page(const UsedCarsScreen(), state),
          ),
          GoRoute(
            path: Routes.partsCart,
            pageBuilder: (context, state) =>
                page(const PartsCartScreen(), state),
          ),
          GoRoute(
            path: Routes.partsCheckout,
            pageBuilder: (context, state) =>
                page(const PartsCheckoutScreen(), state),
          ),
          GoRoute(
            path: Routes.favorites,
            pageBuilder: (context, state) => page(const FavoritesScreen(), state),
          ),
          GoRoute(
            path: Routes.profile,
            pageBuilder: (context, state) => page(const ProfileScreen(), state),
          ),
        ],
      ),
    ],
  );
}

/// THE app Scaffold — the only one in the entire app. Hosts the overlay
/// side menu (panel slides over the dimmed content from the start edge)
/// and the floating bottom nav on the four tab routes.
final class _AppShell extends StatelessWidget {
  const _AppShell({required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    final menuOpen = context.watch<MenuCubit>().state;
    final width = MediaQuery.sizeOf(context).width;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Main content + bottom nav.
          Stack(
            children: [
              child,
              if (AppBottomNav.showsOn(location))
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AppBottomNav(location: location),
                ),
              // Contact FAB — the website's floating headphones button.
              if (AppBottomNav.showsOn(location)) const ContactFab(),
            ],
          ),
          // Dim scrim — fades in with the panel, tap to close. IgnorePointer
          // keeps the tree cheap when the menu is shut (opacity-only anim).
          IgnorePointer(
            ignoring: !menuOpen,
            child: AnimatedOpacity(
              opacity: menuOpen ? 1 : 0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              child: GestureDetector(
                onTap: () => context.read<MenuCubit>().dismiss(),
                child: Container(color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
          ),
          // The panel — slides in from the start edge, rounded trailing
          // corners, ~74% width like the reference.
          AnimatedSlide(
            offset: menuOpen ? Offset.zero : Offset(isRtl ? 1.06 : -1.06, 0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                width: width * 0.74,
                height: double.infinity,
                child: SideMenu(location: location),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
