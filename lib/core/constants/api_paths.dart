/// Backend endpoints — HJ.Mobile.Api (MobileAppBackEnd-next).
abstract final class ApiPaths {
  /// Android emulator reaches the host machine via 10.0.2.2.
  /// Override at build time: flutter run --dart-define=API_BASE_URL=http://192.168.x.x:5080
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fluttermobile.hassanjameelapp.com',
    // 'http://192.168.100.42:5080',
  );

  // Appearance (dashboard-driven).
  static const String themes = '/api/app/themes';
  static const String onboarding = '/api/app/onboarding';
  static const String homeServices = '/api/app/home/services';

  // Home feed (aggregated) + interactive sections.
  static const String home = '/api/app/home';
  static const String protectionByModel = '/api/app/protection-by-model';
  static const String partsSearch = '/api/app/parts/search';

  // Offers — same cycle as the website's /offers page (Site_Offers_* procs).
  static const String offers = '/api/app/offers';
  static const String offersReserve = '/api/app/offers/reserve';

  // Finance page — banks + filters + per-bank priced lineup (Site_Finance_*).
  static const String financeBanks = '/api/app/finance/banks';
  static const String financeFilters = '/api/app/finance/filters';
  static const String financeVehicles = '/api/app/finance/vehicles';

  // Spare parts (Site_Eparts_*).
  static const String partsFilters = '/api/app/parts/filters';
  static const String partsBanners = '/api/app/parts/banners';

  // Registered-user home (garage / dynamic card / journeys).
  static const String accountHomeState = '/api/app/account/home-state';
  static const String accountGarage = '/api/app/account/garage';
  static const String accountMeterReading = '/api/app/account/meter-reading';
  static const String accountNextPm = '/api/app/account/next-pm';
  static const String accountOrders = '/api/app/account/orders';

  // Maintenance / protection & shading (Site_Maintenance_*).
  static const String maintSettings = '/api/app/maintenance/settings';
  static const String maintProtectionByModel =
      '/api/app/maintenance/protection-by-model';
  static const String maintBranches = '/api/app/maintenance/branches';
  static const String maintHours = '/api/app/maintenance/available-hours';
  static const String maintBookings = '/api/app/maintenance/bookings';
  // Maintenance hub — periodic schedule dataset + guest testimonials
  // (same payloads the website's /maintenance/periodic page renders).
  static const String maintPeriodic = '/api/app/maintenance/periodic';
  static const String maintTestimonials = '/api/app/maintenance/testimonials';

  // Coupons — home banners + server-computed validation (website cycle).
  static const String couponHomeBanners = '/api/app/coupons/home-banners';
  static const String couponValidateProtection =
      '/api/app/coupons/validate-protection';
  static const String jobcardValidateCoupon =
      '/api/app/jobcard/validate-coupon';

  // News + Contact (website /news and /contact cycles).
  static const String news = '/api/app/news';
  static const String contact = '/api/app/contact';
  static const String contactMessages = '/api/app/contact/messages';

  // Finance requests tracker + FCM token + live tracking.
  static const String financeRequests = '/api/app/account/finance-requests';
  static const String fcmToken = '/api/user/token';
  static const String trackingStream = '/api/app/tracking/stream';
  static const String maintDays = '/api/app/maintenance/available-days';

  // Profile hub — account data cycle (same /api/user group as auth).
  static const String userByGuid = '/api/user'; // + '/{guid}'
  static const String userSettings = '/api/user/settings';
  static const String userAccountTypes = '/api/user/account-types';
  static const String userUpdateProfile = '/api/user/update-profile';
  static const String userUpdateIdentity = '/api/user/update-identity';
  static const String userUpdatePassword = '/api/user/update-password';
  static const String userUpdatePhone = '/api/user/update-phone';
  static const String userUpdateEmail = '/api/user/update-email';
  static const String userDeleteAccount = '/api/user/delete-account';

  // Favorites + server notification history (website profile parity).
  static const String accountFavorites = '/api/app/account/favorites';
  static const String accountFavoritesAdd = '/api/app/account/favorites/add';
  static const String accountFavoritesRemove =
      '/api/app/account/favorites/remove';
  static const String accountNotifications =
      '/api/app/account/notifications'; // + '/{guid}'

  // Auth — same cycle as the website (Site_User_* procs).
  static const String signIn = '/api/user/sign-in';
  static const String absher = '/api/user/absher';
  static const String otpRequest = '/api/user/otp/request';
  static const String otpVerify = '/api/user/otp/verify';
  static const String resetPassword = '/api/user/reset-password';
  static const String phoneExists = '/api/user/exists/phone';
  static const String emailExists = '/api/user/exists/email';
}
