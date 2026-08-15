import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgot = '/forgot-password';
  static const home = '/home';
  static const onlineStore = '/online-store';
  static const models = '/models';
  static const offers = '/offers';
  static const finance = '/finance';
  static const parts = '/parts';
  static const partsCart = '/parts/cart';
  static const partsCheckout = '/parts/checkout';
  static const protection = '/protection';
  static const maintenance = '/maintenance';
  static const news = '/news';
  static const usedCars = '/used-cars';
  static const contact = '/contact';
  static const financeRequests = '/finance-requests';
  static const tracking = '/tracking';
  static const cart = '/cart';
  static const favorites = '/favorites';
  static const store = '/store';
  static const profile = '/profile';
}

/// Manual back-history for the shell: go_router's `go` REPLACES the match
/// (menu / bottom-nav navigation), so there is nothing to pop. The shell
/// records every visited location here and the header back button walks it.
final class NavHistory {
  NavHistory._();

  static final List<String> _stack = [];

  /// Entry/auth screens never participate in back history.
  static const _excluded = {
    Routes.onboarding,
    Routes.welcome,
    Routes.signIn,
    Routes.signUp,
    Routes.forgot,
  };

  static void record(String location) {
    if (_excluded.contains(location)) return;
    if (_stack.isNotEmpty && _stack.last == location) return;
    _stack.add(location);
    if (_stack.length > 24) _stack.removeAt(0);
  }

  /// Pops the current location and returns the previous one (kept on the
  /// stack — it becomes current after navigation). Null when empty.
  static String? back(String current) {
    while (_stack.isNotEmpty && _stack.last == current) {
      _stack.removeLast();
    }
    return _stack.isEmpty ? null : _stack.last;
  }

  /// Whether walking back from [current] has somewhere to go.
  static bool hasBack(String current) => _stack.any((l) => l != current);

  /// Whether [location] takes part in back history at all (entry/auth
  /// screens never do).
  static bool participates(String location) => !_excluded.contains(location);
}

/// The ONE safe back action for in-screen back buttons: pops a real pushed
/// stack when it exists, otherwise walks [NavHistory] to the previous
/// screen (go() replaces the match, so pop would throw), else goes home.
void appBack(BuildContext context) {
  try {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
  } catch (_) {}
  String location = '';
  try {
    location = GoRouterState.of(context).matchedLocation;
  } catch (_) {}
  final prev = NavHistory.back(location);
  context.go(prev ?? Routes.home);
}
