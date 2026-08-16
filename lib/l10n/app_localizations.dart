import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hassan Jameel'**
  String get appTitle;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get onboardingSignIn;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service'**
  String get onboardingTerms;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get authWelcomeBack;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account'**
  String get authLoginSubtitle;

  /// No description provided for @authEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email, Phone or Identity'**
  String get authEmailOrPhone;

  /// No description provided for @authEmailOrPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com / 05xxxxxxxx / 1xxxxxxxxx'**
  String get authEmailOrPhoneHint;

  /// No description provided for @authContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinue;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get authOr;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get authContinueAsGuest;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// No description provided for @authInvalidAccess.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email, phone, or identity number.'**
  String get authInvalidAccess;

  /// No description provided for @authRequiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get authRequiredField;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authInvalidEmail;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get authInvalidCredentials;

  /// No description provided for @authOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authOtpTitle;

  /// No description provided for @authOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to'**
  String get authOtpSentTo;

  /// No description provided for @authOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code.'**
  String get authOtpInvalid;

  /// No description provided for @otpVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified successfully'**
  String get otpVerifiedTitle;

  /// No description provided for @otpValidFor.
  ///
  /// In en, this message translates to:
  /// **'Code valid for {time}'**
  String otpValidFor(String time);

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'The code has expired — request a new one.'**
  String get otpExpired;

  /// No description provided for @otpIncorrectTitle.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code'**
  String get otpIncorrectTitle;

  /// No description provided for @otpIncorrectHint.
  ///
  /// In en, this message translates to:
  /// **'Check the code and tap to try again.'**
  String get otpIncorrectHint;

  /// No description provided for @authOtpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authOtpResend;

  /// No description provided for @authBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get authBack;

  /// No description provided for @authDevOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Dev OTP: {code}'**
  String authDevOtpHint(String code);

  /// No description provided for @absherTitle.
  ///
  /// In en, this message translates to:
  /// **'Register with Absher'**
  String get absherTitle;

  /// No description provided for @absherStep1.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2 — complete Absher verification'**
  String get absherStep1;

  /// No description provided for @absherStep2.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2 — confirm the Absher code'**
  String get absherStep2;

  /// No description provided for @absherLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get absherLanguage;

  /// No description provided for @absherArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get absherArabic;

  /// No description provided for @absherEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get absherEnglish;

  /// No description provided for @absherIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity number'**
  String get absherIdentity;

  /// No description provided for @absherMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get absherMobile;

  /// No description provided for @absherBirthdate.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get absherBirthdate;

  /// No description provided for @absherBirthdateHint.
  ///
  /// In en, this message translates to:
  /// **'1995-05'**
  String get absherBirthdateHint;

  /// No description provided for @absherRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get absherRegister;

  /// No description provided for @absherOtpSent.
  ///
  /// In en, this message translates to:
  /// **'We sent an Absher verification code to your registered mobile.'**
  String get absherOtpSent;

  /// No description provided for @absherConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm OTP'**
  String get absherConfirm;

  /// No description provided for @absherInvalidIdentity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid identity number.'**
  String get absherInvalidIdentity;

  /// No description provided for @absherInvalidMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile must be 9 digits (e.g. 5xxxxxxxx).'**
  String get absherInvalidMobile;

  /// No description provided for @absherInvalidBirthdate.
  ///
  /// In en, this message translates to:
  /// **'Birth date must be YYYY-MM (e.g. 1995-05).'**
  String get absherInvalidBirthdate;

  /// No description provided for @absherFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete Absher registration.'**
  String get absherFailed;

  /// No description provided for @absherOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired OTP.'**
  String get absherOtpInvalid;

  /// No description provided for @absherSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired, please try again.'**
  String get absherSessionExpired;

  /// No description provided for @absherHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I have an account — sign in'**
  String get absherHaveAccount;

  /// No description provided for @authRegisteredNotice.
  ///
  /// In en, this message translates to:
  /// **'Account created via Absher — sign in with your mobile number.'**
  String get authRegisteredNotice;

  /// No description provided for @authNotFoundNotice.
  ///
  /// In en, this message translates to:
  /// **'No account found for these details — create a new one.'**
  String get authNotFoundNotice;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a verification code to your phone'**
  String get forgotSubtitle;

  /// No description provided for @forgotPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get forgotPhone;

  /// No description provided for @forgotSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get forgotSendCode;

  /// No description provided for @forgotSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the code. Check the number.'**
  String get forgotSendFailed;

  /// No description provided for @forgotNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get forgotNewPassword;

  /// No description provided for @forgotConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get forgotConfirmPassword;

  /// No description provided for @forgotSave.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get forgotSave;

  /// No description provided for @forgotFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update password.'**
  String get forgotFailed;

  /// No description provided for @forgotDoneNotice.
  ///
  /// In en, this message translates to:
  /// **'Password updated — sign in.'**
  String get forgotDoneNotice;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDontMatch;

  /// No description provided for @authInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Saudi phone number (05xxxxxxxx)'**
  String get authInvalidPhone;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your connection.'**
  String get authNetworkError;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authGenericError;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeWelcome;

  /// No description provided for @homeGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get homeGuest;

  /// No description provided for @homeOnlineStore.
  ///
  /// In en, this message translates to:
  /// **'Online Store'**
  String get homeOnlineStore;

  /// No description provided for @homeOnlineStoreSub.
  ///
  /// In en, this message translates to:
  /// **'Reserve your car online with home delivery'**
  String get homeOnlineStoreSub;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'VIEW ALL'**
  String get homeViewAll;

  /// No description provided for @homeMeetTheModels.
  ///
  /// In en, this message translates to:
  /// **'Meet the models'**
  String get homeMeetTheModels;

  /// No description provided for @homeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeAll;

  /// No description provided for @homeProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection & Shading'**
  String get homeProtection;

  /// No description provided for @homeProtectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep the factory shine with advanced shading and protective coatings.'**
  String get homeProtectionDesc;

  /// No description provided for @homeSelectCar.
  ///
  /// In en, this message translates to:
  /// **'Select Car'**
  String get homeSelectCar;

  /// No description provided for @homeSelectModel.
  ///
  /// In en, this message translates to:
  /// **'Select Model'**
  String get homeSelectModel;

  /// No description provided for @homeServiceType.
  ///
  /// In en, this message translates to:
  /// **'Service Type'**
  String get homeServiceType;

  /// No description provided for @homeCheckAvailability.
  ///
  /// In en, this message translates to:
  /// **'Check Availability'**
  String get homeCheckAvailability;

  /// No description provided for @homeSpareParts.
  ///
  /// In en, this message translates to:
  /// **'Genuine Spare Parts'**
  String get homeSpareParts;

  /// No description provided for @homeSparePartsSub.
  ///
  /// In en, this message translates to:
  /// **'Find parts compatible with your vehicle'**
  String get homeSparePartsSub;

  /// No description provided for @homeAddToCart.
  ///
  /// In en, this message translates to:
  /// **'ADD TO CART'**
  String get homeAddToCart;

  /// No description provided for @homeUsedCars.
  ///
  /// In en, this message translates to:
  /// **'Trusted Used Cars'**
  String get homeUsedCars;

  /// No description provided for @homeUsedCarsSub.
  ///
  /// In en, this message translates to:
  /// **'Some inspected by Hassan Jameel'**
  String get homeUsedCarsSub;

  /// No description provided for @homeUsedCarsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cars listed yet — be the first to list yours.'**
  String get homeUsedCarsEmpty;

  /// No description provided for @homeListYourCar.
  ///
  /// In en, this message translates to:
  /// **'List your car'**
  String get homeListYourCar;

  /// No description provided for @homeInspected.
  ///
  /// In en, this message translates to:
  /// **'Inspected by Hassan Jameel'**
  String get homeInspected;

  /// No description provided for @homeMaintenanceSpecials.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Specials'**
  String get homeMaintenanceSpecials;

  /// No description provided for @homeMaintenanceSpecialsSub.
  ///
  /// In en, this message translates to:
  /// **'Keep your car in peak condition'**
  String get homeMaintenanceSpecialsSub;

  /// No description provided for @homeVehicleOffers.
  ///
  /// In en, this message translates to:
  /// **'Drive home with an offer'**
  String get homeVehicleOffers;

  /// No description provided for @homeBuyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get homeBuyNow;

  /// No description provided for @homeBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get homeBook;

  /// No description provided for @homeViewOffer.
  ///
  /// In en, this message translates to:
  /// **'View offer'**
  String get homeViewOffer;

  /// No description provided for @homeReserveNow.
  ///
  /// In en, this message translates to:
  /// **'Reserve Now'**
  String get homeReserveNow;

  /// No description provided for @homeDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String homeDaysLeft(int count);

  /// No description provided for @homeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get homeFrom;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get currency;

  /// No description provided for @homeContactForPrice.
  ///
  /// In en, this message translates to:
  /// **'Contact for price'**
  String get homeContactForPrice;

  /// No description provided for @homeComingSoonFeature.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get homeComingSoonFeature;

  /// No description provided for @homeErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the page. Tap to retry.'**
  String get homeErrorRetry;

  /// No description provided for @stateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get stateErrorTitle;

  /// No description provided for @stateErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get stateErrorBody;

  /// No description provided for @stateRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get stateRetry;

  /// No description provided for @homeSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get homeSignOut;

  /// No description provided for @homeThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get homeThemeMode;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get settingsLanguage;

  /// No description provided for @brandToyota.
  ///
  /// In en, this message translates to:
  /// **'Toyota'**
  String get brandToyota;

  /// No description provided for @brandLexus.
  ///
  /// In en, this message translates to:
  /// **'Lexus'**
  String get brandLexus;

  /// No description provided for @storeModelsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} models available for instant reservation'**
  String storeModelsCount(int count);

  /// No description provided for @storeFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get storeFilters;

  /// No description provided for @storeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search a model…'**
  String get storeSearch;

  /// No description provided for @osHeroGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello {name} 👋'**
  String osHeroGreeting(String name);

  /// No description provided for @osHeroGreetingGuest.
  ///
  /// In en, this message translates to:
  /// **'Welcome 👋'**
  String get osHeroGreetingGuest;

  /// No description provided for @osHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your perfect car'**
  String get osHeroTitle;

  /// No description provided for @storePriceUpTo.
  ///
  /// In en, this message translates to:
  /// **'Price up to'**
  String get storePriceUpTo;

  /// No description provided for @storeCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get storeCategories;

  /// No description provided for @storeColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get storeColor;

  /// No description provided for @storeAllColors.
  ///
  /// In en, this message translates to:
  /// **'All colors'**
  String get storeAllColors;

  /// No description provided for @storeClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get storeClearFilters;

  /// No description provided for @storeApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get storeApplyFilters;

  /// No description provided for @storeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No cars match your filters.'**
  String get storeNoResults;

  /// No description provided for @storeAvailableOnline.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE ONLINE'**
  String get storeAvailableOnline;

  /// No description provided for @storeFrom.
  ///
  /// In en, this message translates to:
  /// **'FROM'**
  String get storeFrom;

  /// No description provided for @storeVatNote.
  ///
  /// In en, this message translates to:
  /// **'Inclusive of 15% VAT, License plate and Registration fees'**
  String get storeVatNote;

  /// No description provided for @storeAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get storeAddToCart;

  /// No description provided for @cartAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get cartAdded;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get cartTitle;

  /// No description provided for @cartMakePayment.
  ///
  /// In en, this message translates to:
  /// **'Make Payment'**
  String get cartMakePayment;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty — browse the online store.'**
  String get cartEmpty;

  /// No description provided for @cartBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse cars'**
  String get cartBrowse;

  /// No description provided for @cartTabVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles cart'**
  String get cartTabVehicles;

  /// No description provided for @cartTabParts.
  ///
  /// In en, this message translates to:
  /// **'Spare parts cart'**
  String get cartTabParts;

  /// No description provided for @favTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favTitle;

  /// No description provided for @favEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet — tap the heart on any car.'**
  String get favEmpty;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @sheetPickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get sheetPickColor;

  /// No description provided for @sheetFinancingOptions.
  ///
  /// In en, this message translates to:
  /// **'FINANCING OPTIONS'**
  String get sheetFinancingOptions;

  /// No description provided for @sheetPickBank.
  ///
  /// In en, this message translates to:
  /// **'Pick a bank'**
  String get sheetPickBank;

  /// No description provided for @sheetBanksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} banks offer financing for this vehicle.'**
  String sheetBanksCount(int count);

  /// No description provided for @bankMonthly.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY'**
  String get bankMonthly;

  /// No description provided for @bankDown.
  ///
  /// In en, this message translates to:
  /// **'DOWN'**
  String get bankDown;

  /// No description provided for @bankAdminFees.
  ///
  /// In en, this message translates to:
  /// **'ADMIN FEES'**
  String get bankAdminFees;

  /// No description provided for @bankTotal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get bankTotal;

  /// No description provided for @bankMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} MONTHS'**
  String bankMonths(int count);

  /// No description provided for @sheetHowToBuy.
  ///
  /// In en, this message translates to:
  /// **'How would you like to buy this car?'**
  String get sheetHowToBuy;

  /// No description provided for @sheetSelectYourCar.
  ///
  /// In en, this message translates to:
  /// **'Select Your Car'**
  String get sheetSelectYourCar;

  /// No description provided for @sheetLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get sheetLearnMore;

  /// No description provided for @sheetNext.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get sheetNext;

  /// No description provided for @ghHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your New Car Starts Here'**
  String get ghHeroTitle;

  /// No description provided for @ghHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover Toyota & Lexus vehicles and finance offers'**
  String get ghHeroSubtitle;

  /// No description provided for @ghBrowseCars.
  ///
  /// In en, this message translates to:
  /// **'Browse Cars'**
  String get ghBrowseCars;

  /// No description provided for @ghCalcFinance.
  ///
  /// In en, this message translates to:
  /// **'Calculate Finance'**
  String get ghCalcFinance;

  /// No description provided for @ghQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get ghQuickActions;

  /// No description provided for @ghBookMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Book Service'**
  String get ghBookMaintenance;

  /// No description provided for @ghCarOffers.
  ///
  /// In en, this message translates to:
  /// **'Car Offers'**
  String get ghCarOffers;

  /// No description provided for @ghMaintOffers.
  ///
  /// In en, this message translates to:
  /// **'Service Offers'**
  String get ghMaintOffers;

  /// No description provided for @ghSpareParts.
  ///
  /// In en, this message translates to:
  /// **'Spare Parts'**
  String get ghSpareParts;

  /// No description provided for @ghBrowseByType.
  ///
  /// In en, this message translates to:
  /// **'Browse Cars'**
  String get ghBrowseByType;

  /// No description provided for @ghCarsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cars'**
  String ghCarsCount(int count);

  /// No description provided for @ghFinanceOffers.
  ///
  /// In en, this message translates to:
  /// **'Finance Offers'**
  String get ghFinanceOffers;

  /// No description provided for @ghServices.
  ///
  /// In en, this message translates to:
  /// **'Hassan Jameel Services'**
  String get ghServices;

  /// No description provided for @ghSvcMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get ghSvcMaintenance;

  /// No description provided for @ghSvcProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection & Shading'**
  String get ghSvcProtection;

  /// No description provided for @ghSvcParts.
  ///
  /// In en, this message translates to:
  /// **'Spare Parts'**
  String get ghSvcParts;

  /// No description provided for @ghSvcFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get ghSvcFinance;

  /// No description provided for @ghLoginBenefit.
  ///
  /// In en, this message translates to:
  /// **'Sign in to track your car, bookings, invoices and your exclusive offers.'**
  String get ghLoginBenefit;

  /// No description provided for @ghLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'This service needs an account — sign in to track your bookings and orders.'**
  String get ghLoginRequired;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get tabGallery;

  /// No description provided for @tabSpecs.
  ///
  /// In en, this message translates to:
  /// **'Specs'**
  String get tabSpecs;

  /// No description provided for @tabFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get tabFeatures;

  /// No description provided for @tabComparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get tabComparison;

  /// No description provided for @modelsPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get modelsPrice;

  /// No description provided for @modelsTrims.
  ///
  /// In en, this message translates to:
  /// **'Trims & Prices'**
  String get modelsTrims;

  /// No description provided for @modelsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available for this model.'**
  String get modelsNoData;

  /// No description provided for @specYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get specYear;

  /// No description provided for @specHp.
  ///
  /// In en, this message translates to:
  /// **'Horsepower'**
  String get specHp;

  /// No description provided for @specFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get specFuel;

  /// No description provided for @specSeats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get specSeats;

  /// No description provided for @specCylinders.
  ///
  /// In en, this message translates to:
  /// **'Cylinders'**
  String get specCylinders;

  /// No description provided for @methodReserveTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick reservation'**
  String get methodReserveTitle;

  /// No description provided for @methodReserveBadge.
  ///
  /// In en, this message translates to:
  /// **'BEST CHOICE'**
  String get methodReserveBadge;

  /// No description provided for @methodSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get methodSignIn;

  /// No description provided for @methodRefundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get methodRefundable;

  /// No description provided for @methodFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get methodFree;

  /// No description provided for @methodReserveB1.
  ///
  /// In en, this message translates to:
  /// **'The fastest way to receive your car'**
  String get methodReserveB1;

  /// No description provided for @methodReserveB2.
  ///
  /// In en, this message translates to:
  /// **'Locks the price while you complete the purchase'**
  String get methodReserveB2;

  /// No description provided for @methodReserveB3.
  ///
  /// In en, this message translates to:
  /// **'Reservation period: 1 business day'**
  String get methodReserveB3;

  /// No description provided for @methodFinanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply for finance'**
  String get methodFinanceTitle;

  /// No description provided for @methodFinanceB1.
  ///
  /// In en, this message translates to:
  /// **'Get a preliminary approval within minutes'**
  String get methodFinanceB1;

  /// No description provided for @methodFinanceB2.
  ///
  /// In en, this message translates to:
  /// **'A variety of options that fit your income'**
  String get methodFinanceB2;

  /// No description provided for @methodFinanceB3.
  ///
  /// In en, this message translates to:
  /// **'A finance specialist guides you step by step'**
  String get methodFinanceB3;

  /// No description provided for @methodContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Request a callback'**
  String get methodContactTitle;

  /// No description provided for @methodContactB1.
  ///
  /// In en, this message translates to:
  /// **'A sales consultant calls you within minutes (work hours)'**
  String get methodContactB1;

  /// No description provided for @methodContactB2.
  ///
  /// In en, this message translates to:
  /// **'Help you with car details and the best offers'**
  String get methodContactB2;

  /// No description provided for @sheetTerms.
  ///
  /// In en, this message translates to:
  /// **'I have read the terms & conditions and privacy policy.'**
  String get sheetTerms;

  /// No description provided for @sheetContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get sheetContinue;

  /// No description provided for @formApplicant.
  ///
  /// In en, this message translates to:
  /// **'Applicant type'**
  String get formApplicant;

  /// No description provided for @formName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get formName;

  /// No description provided for @formPhone.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get formPhone;

  /// No description provided for @formEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get formEmail;

  /// No description provided for @formCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get formCity;

  /// No description provided for @formIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity number'**
  String get formIdentity;

  /// No description provided for @formCN.
  ///
  /// In en, this message translates to:
  /// **'Commercial registration (CN)'**
  String get formCN;

  /// No description provided for @formQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get formQuantity;

  /// No description provided for @formNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get formNote;

  /// No description provided for @formSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get formSend;

  /// No description provided for @formNameAr.
  ///
  /// In en, this message translates to:
  /// **'Full name (Arabic)'**
  String get formNameAr;

  /// No description provided for @formNameEn.
  ///
  /// In en, this message translates to:
  /// **'Full name (English)'**
  String get formNameEn;

  /// No description provided for @formGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get formGender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @formWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Receive updates on WhatsApp'**
  String get formWhatsapp;

  /// No description provided for @stepPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get stepPersonal;

  /// No description provided for @stepWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get stepWork;

  /// No description provided for @stepDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get stepDocuments;

  /// No description provided for @formJob.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get formJob;

  /// No description provided for @formIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly income'**
  String get formIncome;

  /// No description provided for @formFirstPayment.
  ///
  /// In en, this message translates to:
  /// **'First payment (optional)'**
  String get formFirstPayment;

  /// No description provided for @formMonthlyAmount.
  ///
  /// In en, this message translates to:
  /// **'Preferred monthly installment (optional)'**
  String get formMonthlyAmount;

  /// No description provided for @formPeriod.
  ///
  /// In en, this message translates to:
  /// **'Finance period (months)'**
  String get formPeriod;

  /// No description provided for @formWorkType.
  ///
  /// In en, this message translates to:
  /// **'Work sector'**
  String get formWorkType;

  /// No description provided for @workPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get workPrivate;

  /// No description provided for @workGovernmental.
  ///
  /// In en, this message translates to:
  /// **'Governmental'**
  String get workGovernmental;

  /// No description provided for @formSalaryBank.
  ///
  /// In en, this message translates to:
  /// **'Salary bank'**
  String get formSalaryBank;

  /// No description provided for @financeQ1.
  ///
  /// In en, this message translates to:
  /// **'Are you registered in SIMAH?'**
  String get financeQ1;

  /// No description provided for @financeQ2.
  ///
  /// In en, this message translates to:
  /// **'Do you have traffic violations?'**
  String get financeQ2;

  /// No description provided for @financeQ3.
  ///
  /// In en, this message translates to:
  /// **'Do you have a real-estate loan?'**
  String get financeQ3;

  /// No description provided for @financeQ4.
  ///
  /// In en, this message translates to:
  /// **'Do you have other obligations?'**
  String get financeQ4;

  /// No description provided for @answerYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get answerYes;

  /// No description provided for @answerNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get answerNo;

  /// No description provided for @formViolationsAmount.
  ///
  /// In en, this message translates to:
  /// **'Violations amount'**
  String get formViolationsAmount;

  /// No description provided for @formObligationsAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly obligations amount'**
  String get formObligationsAmount;

  /// No description provided for @formFinanceBank.
  ///
  /// In en, this message translates to:
  /// **'Financing entity'**
  String get formFinanceBank;

  /// No description provided for @docIdentity.
  ///
  /// In en, this message translates to:
  /// **'National ID / CN'**
  String get docIdentity;

  /// No description provided for @docLicense.
  ///
  /// In en, this message translates to:
  /// **'Driving license'**
  String get docLicense;

  /// No description provided for @docInsurance.
  ///
  /// In en, this message translates to:
  /// **'GOSI certificate'**
  String get docInsurance;

  /// No description provided for @docAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank statement'**
  String get docAccount;

  /// No description provided for @docSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary definition letter'**
  String get docSalary;

  /// No description provided for @docUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get docUpload;

  /// No description provided for @docReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get docReplace;

  /// No description provided for @errIdentity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit number.'**
  String get errIdentity;

  /// No description provided for @errDocTooBig.
  ///
  /// In en, this message translates to:
  /// **'File is larger than 4MB.'**
  String get errDocTooBig;

  /// No description provided for @errAnswerAll.
  ///
  /// In en, this message translates to:
  /// **'Please answer all questions.'**
  String get errAnswerAll;

  /// No description provided for @formNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get formNext;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Request received!'**
  String get successTitle;

  /// No description provided for @successReserve.
  ///
  /// In en, this message translates to:
  /// **'Your car is reserved — our team will contact you to complete the purchase.'**
  String get successReserve;

  /// No description provided for @successFinance.
  ///
  /// In en, this message translates to:
  /// **'Your finance request was received — a specialist will contact you shortly.'**
  String get successFinance;

  /// No description provided for @successContact.
  ///
  /// In en, this message translates to:
  /// **'Request received — a sales consultant will call you within work hours.'**
  String get successContact;

  /// No description provided for @successRef.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get successRef;

  /// No description provided for @successClose.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get successClose;

  /// No description provided for @reserveSignInFirst.
  ///
  /// In en, this message translates to:
  /// **'Sign in to complete a quick reservation.'**
  String get reserveSignInFirst;

  /// No description provided for @sheetDownPayment.
  ///
  /// In en, this message translates to:
  /// **'Down Payment'**
  String get sheetDownPayment;

  /// No description provided for @sheetAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount required'**
  String get sheetAmountRequired;

  /// No description provided for @offersTitle.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offersTitle;

  /// No description provided for @offersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active offers right now.'**
  String get offersEmpty;

  /// No description provided for @offersView.
  ///
  /// In en, this message translates to:
  /// **'View offer'**
  String get offersView;

  /// No description provided for @offersEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get offersEnded;

  /// No description provided for @offersDay.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get offersDay;

  /// No description provided for @offersHour.
  ///
  /// In en, this message translates to:
  /// **'HOUR'**
  String get offersHour;

  /// No description provided for @offersMin.
  ///
  /// In en, this message translates to:
  /// **'MIN'**
  String get offersMin;

  /// No description provided for @offersSec.
  ///
  /// In en, this message translates to:
  /// **'SEC'**
  String get offersSec;

  /// No description provided for @offersPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get offersPackages;

  /// No description provided for @offersSupportedVehicles.
  ///
  /// In en, this message translates to:
  /// **'Supported vehicles'**
  String get offersSupportedVehicles;

  /// No description provided for @offersTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get offersTerms;

  /// No description provided for @offersApplyFinance.
  ///
  /// In en, this message translates to:
  /// **'Apply for finance'**
  String get offersApplyFinance;

  /// No description provided for @offersReserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve this offer'**
  String get offersReserve;

  /// No description provided for @offersRequest.
  ///
  /// In en, this message translates to:
  /// **'Request this offer'**
  String get offersRequest;

  /// No description provided for @offersRate.
  ///
  /// In en, this message translates to:
  /// **'Financing rate {rate}'**
  String offersRate(String rate);

  /// No description provided for @offersSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your request was received — our team will contact you shortly.'**
  String get offersSubmitted;

  /// No description provided for @offersSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong — please try again.'**
  String get offersSubmitFailed;

  /// No description provided for @offersVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get offersVehicle;

  /// No description provided for @offersPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get offersPackage;

  /// No description provided for @offersYear.
  ///
  /// In en, this message translates to:
  /// **'Manufacture year'**
  String get offersYear;

  /// No description provided for @offersMeter.
  ///
  /// In en, this message translates to:
  /// **'Meter reading'**
  String get offersMeter;

  /// No description provided for @offersVinOptional.
  ///
  /// In en, this message translates to:
  /// **'VIN (optional)'**
  String get offersVinOptional;

  /// No description provided for @offersIncome.
  ///
  /// In en, this message translates to:
  /// **'Net monthly income'**
  String get offersIncome;

  /// No description provided for @offersPeriod.
  ///
  /// In en, this message translates to:
  /// **'Finance period (months)'**
  String get offersPeriod;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @formFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get formFullName;

  /// No description provided for @formFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get formFirstName;

  /// No description provided for @formLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get formLastName;

  /// No description provided for @formEmailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get formEmailOptional;

  /// No description provided for @formNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get formNoteOptional;

  /// No description provided for @formCheckFields.
  ///
  /// In en, this message translates to:
  /// **'Please check the required fields.'**
  String get formCheckFields;

  /// No description provided for @finTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance your car'**
  String get finTitle;

  /// No description provided for @finSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a bank, set your budget, and get an instant monthly-payment estimate.'**
  String get finSubtitle;

  /// No description provided for @finModeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get finModeMonthly;

  /// No description provided for @finModeModel.
  ///
  /// In en, this message translates to:
  /// **'By model'**
  String get finModeModel;

  /// No description provided for @finModeBudget.
  ///
  /// In en, this message translates to:
  /// **'By budget'**
  String get finModeBudget;

  /// No description provided for @finMonthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY PAYMENT'**
  String get finMonthlyPayment;

  /// No description provided for @finPeriodMonths.
  ///
  /// In en, this message translates to:
  /// **'PERIOD (MONTHS)'**
  String get finPeriodMonths;

  /// No description provided for @finFinalPayment.
  ///
  /// In en, this message translates to:
  /// **'FINAL PAYMENT'**
  String get finFinalPayment;

  /// No description provided for @finSar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get finSar;

  /// No description provided for @finMo.
  ///
  /// In en, this message translates to:
  /// **'mo'**
  String get finMo;

  /// No description provided for @finMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get finMaxPrice;

  /// No description provided for @finRefine.
  ///
  /// In en, this message translates to:
  /// **'Refine'**
  String get finRefine;

  /// No description provided for @finNoCars.
  ///
  /// In en, this message translates to:
  /// **'No cars match these filters.'**
  String get finNoCars;

  /// No description provided for @finFromMonthly.
  ///
  /// In en, this message translates to:
  /// **'From {amount} / month'**
  String finFromMonthly(String amount);

  /// No description provided for @finApply.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finApply;

  /// No description provided for @finEstMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly payment'**
  String get finEstMonthly;

  /// No description provided for @finEstAdvance.
  ///
  /// In en, this message translates to:
  /// **'Down payment'**
  String get finEstAdvance;

  /// No description provided for @finEstBalloon.
  ///
  /// In en, this message translates to:
  /// **'Final payment'**
  String get finEstBalloon;

  /// No description provided for @finEstTotal.
  ///
  /// In en, this message translates to:
  /// **'Total payable'**
  String get finEstTotal;

  /// No description provided for @finEstFees.
  ///
  /// In en, this message translates to:
  /// **'Admin fees (incl. VAT)'**
  String get finEstFees;

  /// No description provided for @finBuyingAs.
  ///
  /// In en, this message translates to:
  /// **'Buying as'**
  String get finBuyingAs;

  /// No description provided for @finCommercialReg.
  ///
  /// In en, this message translates to:
  /// **'Commercial register'**
  String get finCommercialReg;

  /// No description provided for @finAdvanceOptional.
  ///
  /// In en, this message translates to:
  /// **'Advance payment (optional)'**
  String get finAdvanceOptional;

  /// No description provided for @finCashPrice.
  ///
  /// In en, this message translates to:
  /// **'Cash price'**
  String get finCashPrice;

  /// No description provided for @finCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate finance'**
  String get finCalculate;

  /// No description provided for @finCalcSub.
  ///
  /// In en, this message translates to:
  /// **'Pick your car and compare every bank\'s monthly payment.'**
  String get finCalcSub;

  /// No description provided for @finBestOffer.
  ///
  /// In en, this message translates to:
  /// **'Best offers for you'**
  String get finBestOffer;

  /// No description provided for @finDownPct.
  ///
  /// In en, this message translates to:
  /// **'Down payment %'**
  String get finDownPct;

  /// No description provided for @finBankDefault.
  ///
  /// In en, this message translates to:
  /// **'Bank default'**
  String get finBankDefault;

  /// No description provided for @finPerMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get finPerMonth;

  /// No description provided for @partsTitle.
  ///
  /// In en, this message translates to:
  /// **'Genuine spare parts'**
  String get partsTitle;

  /// No description provided for @partsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find parts compatible with your vehicle.'**
  String get partsSubtitle;

  /// No description provided for @partsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Part name or number...'**
  String get partsSearchHint;

  /// No description provided for @partsResults.
  ///
  /// In en, this message translates to:
  /// **'{count} parts'**
  String partsResults(int count);

  /// No description provided for @partsInStockOnly.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get partsInStockOnly;

  /// No description provided for @partsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No parts found — try a different search.'**
  String get partsEmpty;

  /// No description provided for @partsSortPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Price: high → low'**
  String get partsSortPriceDesc;

  /// No description provided for @partsSortPriceAsc.
  ///
  /// In en, this message translates to:
  /// **'Price: low → high'**
  String get partsSortPriceAsc;

  /// No description provided for @partsSortNo.
  ///
  /// In en, this message translates to:
  /// **'Part number'**
  String get partsSortNo;

  /// No description provided for @partsInStock.
  ///
  /// In en, this message translates to:
  /// **'IN STOCK'**
  String get partsInStock;

  /// No description provided for @partsOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'ON ORDER'**
  String get partsOutOfStock;

  /// No description provided for @partsDetailHint.
  ///
  /// In en, this message translates to:
  /// **'Genuine part with dealer warranty. Online payment is coming with the payment module — meanwhile you can buy this part from any Hassan Jameel branch.'**
  String get partsDetailHint;

  /// No description provided for @protTitle.
  ///
  /// In en, this message translates to:
  /// **'Protection & shading'**
  String get protTitle;

  /// No description provided for @protSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your car to load the available packages.'**
  String get protSubtitle;

  /// No description provided for @protPickToStart.
  ///
  /// In en, this message translates to:
  /// **'Pick your vehicle to start'**
  String get protPickToStart;

  /// No description provided for @protNoPackages.
  ///
  /// In en, this message translates to:
  /// **'No packages available for this model yet.'**
  String get protNoPackages;

  /// No description provided for @protVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get protVehicleType;

  /// No description provided for @protTierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get protTierSilver;

  /// No description provided for @protTierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get protTierGold;

  /// No description provided for @protTierPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get protTierPlatinum;

  /// No description provided for @protTierDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get protTierDiamond;

  /// No description provided for @protBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Book this package'**
  String get protBookTitle;

  /// No description provided for @protBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get protBranch;

  /// No description provided for @protPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get protPickDate;

  /// No description provided for @protNoHours.
  ///
  /// In en, this message translates to:
  /// **'No available hours on this day — pick another date.'**
  String get protNoHours;

  /// No description provided for @protBooked.
  ///
  /// In en, this message translates to:
  /// **'Your booking was received — our service team will contact you to confirm.'**
  String get protBooked;

  /// No description provided for @protConfirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get protConfirmBooking;

  /// No description provided for @acGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get acGoodMorning;

  /// No description provided for @acGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get acGoodAfternoon;

  /// No description provided for @acGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get acGoodEvening;

  /// No description provided for @acGreetingSub.
  ///
  /// In en, this message translates to:
  /// **'Your vehicles are ready for your next journey.'**
  String get acGreetingSub;

  /// No description provided for @acCarInService.
  ///
  /// In en, this message translates to:
  /// **'Your car is in service'**
  String get acCarInService;

  /// No description provided for @acCarReady.
  ///
  /// In en, this message translates to:
  /// **'Your car is ready for pickup 🎉'**
  String get acCarReady;

  /// No description provided for @acStageReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get acStageReceived;

  /// No description provided for @acStageInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get acStageInProgress;

  /// No description provided for @acStageQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality check'**
  String get acStageQuality;

  /// No description provided for @acStageReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get acStageReady;

  /// No description provided for @acStagePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get acStagePayment;

  /// No description provided for @acAmountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get acAmountDue;

  /// No description provided for @acSadad.
  ///
  /// In en, this message translates to:
  /// **'Sadad no.'**
  String get acSadad;

  /// No description provided for @acUpcomingBooking.
  ///
  /// In en, this message translates to:
  /// **'Upcoming service appointment'**
  String get acUpcomingBooking;

  /// No description provided for @acCarDetails.
  ///
  /// In en, this message translates to:
  /// **'Car details'**
  String get acCarDetails;

  /// No description provided for @acNoCarsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your car and follow everything about it'**
  String get acNoCarsTitle;

  /// No description provided for @acNoCarsSub.
  ///
  /// In en, this message translates to:
  /// **'Maintenance, bookings, invoices and offers made for your car — all in one place.'**
  String get acNoCarsSub;

  /// No description provided for @acMyGarage.
  ///
  /// In en, this message translates to:
  /// **'My garage'**
  String get acMyGarage;

  /// No description provided for @acAddCarShort.
  ///
  /// In en, this message translates to:
  /// **'ADD CAR'**
  String get acAddCarShort;

  /// No description provided for @acAddCarTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your car'**
  String get acAddCarTitle;

  /// No description provided for @acAddCarSub.
  ///
  /// In en, this message translates to:
  /// **'Own a car already? Register it with its VIN. Looking for one? Browse the store.'**
  String get acAddCarSub;

  /// No description provided for @acHaveCar.
  ///
  /// In en, this message translates to:
  /// **'I own a car — register it'**
  String get acHaveCar;

  /// No description provided for @acNoCar.
  ///
  /// In en, this message translates to:
  /// **'I don\'t have one — browse cars'**
  String get acNoCar;

  /// No description provided for @acAddCarCta.
  ///
  /// In en, this message translates to:
  /// **'Add my car'**
  String get acAddCarCta;

  /// No description provided for @acAddCarDone.
  ///
  /// In en, this message translates to:
  /// **'Your car was added to your garage.'**
  String get acAddCarDone;

  /// No description provided for @acVin.
  ///
  /// In en, this message translates to:
  /// **'VIN (chassis number)'**
  String get acVin;

  /// No description provided for @acVinHelp.
  ///
  /// In en, this message translates to:
  /// **'17 characters — find it on the registration card'**
  String get acVinHelp;

  /// No description provided for @acPlateOptional.
  ///
  /// In en, this message translates to:
  /// **'Plate no. (optional)'**
  String get acPlateOptional;

  /// No description provided for @acAliasOptional.
  ///
  /// In en, this message translates to:
  /// **'Car name (optional)'**
  String get acAliasOptional;

  /// No description provided for @acDuplicateVin.
  ///
  /// In en, this message translates to:
  /// **'This VIN is already in your garage.'**
  String get acDuplicateVin;

  /// No description provided for @acInvalidVin.
  ///
  /// In en, this message translates to:
  /// **'Please complete the fields — the VIN must be 17 characters.'**
  String get acInvalidVin;

  /// No description provided for @acUpdateMeter.
  ///
  /// In en, this message translates to:
  /// **'Update odometer'**
  String get acUpdateMeter;

  /// No description provided for @acCurrentKm.
  ///
  /// In en, this message translates to:
  /// **'Current reading'**
  String get acCurrentKm;

  /// No description provided for @acInvalidReading.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid reading.'**
  String get acInvalidReading;

  /// No description provided for @acLowerReading.
  ///
  /// In en, this message translates to:
  /// **'The reading can\'t be lower than the last recorded one ({latest} KM).'**
  String acLowerReading(String latest);

  /// No description provided for @acLastBranchReading.
  ///
  /// In en, this message translates to:
  /// **'Last documented reading: {km} KM'**
  String acLastBranchReading(String km);

  /// No description provided for @acChipReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get acChipReady;

  /// No description provided for @acNextShort.
  ///
  /// In en, this message translates to:
  /// **'Next service {km} KM'**
  String acNextShort(String km);

  /// No description provided for @acNextPm.
  ///
  /// In en, this message translates to:
  /// **'Next maintenance at {next} KM — about {remaining} KM to go'**
  String acNextPm(String next, String remaining);

  /// No description provided for @acPmOverdue.
  ///
  /// In en, this message translates to:
  /// **'Maintenance overdue — the {next} KM service is due now'**
  String acPmOverdue(String next);

  /// No description provided for @acPmNeedsReading.
  ///
  /// In en, this message translates to:
  /// **'Enter your odometer reading to find the right maintenance'**
  String get acPmNeedsReading;

  /// No description provided for @acPmNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No maintenance plan is available for this model yet.'**
  String get acPmNoPlan;

  /// No description provided for @acOdometerLine.
  ///
  /// In en, this message translates to:
  /// **'Odometer: {km} KM ({source})'**
  String acOdometerLine(String km, String source);

  /// No description provided for @acSourceBranch.
  ///
  /// In en, this message translates to:
  /// **'branch documented'**
  String get acSourceBranch;

  /// No description provided for @acSourceCustomer.
  ///
  /// In en, this message translates to:
  /// **'your entry'**
  String get acSourceCustomer;

  /// No description provided for @acBuyCar.
  ///
  /// In en, this message translates to:
  /// **'Buy a car'**
  String get acBuyCar;

  /// No description provided for @acMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get acMyOrders;

  /// No description provided for @acAllServices.
  ///
  /// In en, this message translates to:
  /// **'All services'**
  String get acAllServices;

  /// No description provided for @acJourneys.
  ///
  /// In en, this message translates to:
  /// **'Your journeys'**
  String get acJourneys;

  /// No description provided for @acJourneyService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get acJourneyService;

  /// No description provided for @acJourneyBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get acJourneyBooking;

  /// No description provided for @acJourneyOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get acJourneyOrder;

  /// No description provided for @acJourneyFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance request'**
  String get acJourneyFinance;

  /// No description provided for @acActionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Action needed'**
  String get acActionNeeded;

  /// No description provided for @acOrderTracking.
  ///
  /// In en, this message translates to:
  /// **'Order tracking'**
  String get acOrderTracking;

  /// No description provided for @acNoTracking.
  ///
  /// In en, this message translates to:
  /// **'No tracking updates yet.'**
  String get acNoTracking;

  /// No description provided for @acOffersForYou.
  ///
  /// In en, this message translates to:
  /// **'Offers picked for you'**
  String get acOffersForYou;

  /// No description provided for @acTabForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get acTabForYou;

  /// No description provided for @acVinLabel.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get acVinLabel;

  /// No description provided for @acPlate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get acPlate;

  /// No description provided for @acModelCode.
  ///
  /// In en, this message translates to:
  /// **'Model code'**
  String get acModelCode;

  /// No description provided for @acLastMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Last maintenance'**
  String get acLastMaintenance;

  /// No description provided for @acMeter.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get acMeter;

  /// No description provided for @mbTitle.
  ///
  /// In en, this message translates to:
  /// **'Book a service'**
  String get mbTitle;

  /// No description provided for @mbService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get mbService;

  /// No description provided for @mbPackage.
  ///
  /// In en, this message translates to:
  /// **'Maintenance package'**
  String get mbPackage;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get notifClear;

  /// No description provided for @notifEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notifEmpty;

  /// No description provided for @newsTitle.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get newsTitle;

  /// No description provided for @newsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest launches, events and announcements.'**
  String get newsSubtitle;

  /// No description provided for @newsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No news yet.'**
  String get newsEmpty;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactTitle;

  /// No description provided for @contactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a branch and send us a message — our team will reach out.'**
  String get contactSubtitle;

  /// No description provided for @contactOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get contactOpenMaps;

  /// No description provided for @contactFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get contactFormTitle;

  /// No description provided for @contactSent.
  ///
  /// In en, this message translates to:
  /// **'Your message was received — our team will contact you.'**
  String get contactSent;

  /// No description provided for @contactSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get contactSubject;

  /// No description provided for @contactMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get contactMessage;

  /// No description provided for @contactBranches.
  ///
  /// In en, this message translates to:
  /// **'Our branches'**
  String get contactBranches;

  /// No description provided for @finReqTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance requests'**
  String get finReqTitle;

  /// No description provided for @finReqEmpty.
  ///
  /// In en, this message translates to:
  /// **'No finance requests yet.'**
  String get finReqEmpty;

  /// No description provided for @finReqReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get finReqReason;

  /// No description provided for @finReqTimeline.
  ///
  /// In en, this message translates to:
  /// **'Follow-up log'**
  String get finReqTimeline;

  /// No description provided for @finStageReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get finStageReceived;

  /// No description provided for @finStageContacting.
  ///
  /// In en, this message translates to:
  /// **'Contacting you'**
  String get finStageContacting;

  /// No description provided for @finStageSentToBank.
  ///
  /// In en, this message translates to:
  /// **'Sent to bank'**
  String get finStageSentToBank;

  /// No description provided for @finStageApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get finStageApproved;

  /// No description provided for @finStageRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get finStageRejected;

  /// No description provided for @trackTitle.
  ///
  /// In en, this message translates to:
  /// **'Service tracking'**
  String get trackTitle;

  /// No description provided for @trackLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get trackLive;

  /// No description provided for @trackReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get trackReconnecting;

  /// No description provided for @trackEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cars in the workshop right now — when your car is checked in, you\'ll follow it live here.'**
  String get trackEmpty;

  /// No description provided for @acAllServicesSub.
  ///
  /// In en, this message translates to:
  /// **'Everything Hassan Jameel offers, one tap away.'**
  String get acAllServicesSub;

  /// No description provided for @offersForMyCar.
  ///
  /// In en, this message translates to:
  /// **'For my car'**
  String get offersForMyCar;

  /// No description provided for @offersAnotherCar.
  ///
  /// In en, this message translates to:
  /// **'Another car'**
  String get offersAnotherCar;

  /// No description provided for @mbStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 3'**
  String mbStepOf(int step);

  /// No description provided for @mbStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Choose the service'**
  String get mbStep1Title;

  /// No description provided for @mbStep1Sub.
  ///
  /// In en, this message translates to:
  /// **'What does your car need?'**
  String get mbStep1Sub;

  /// No description provided for @mbStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details'**
  String get mbStep2Title;

  /// No description provided for @mbStep2Sub.
  ///
  /// In en, this message translates to:
  /// **'Book for one of your cars or another vehicle.'**
  String get mbStep2Sub;

  /// No description provided for @mbStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Slot & contact details'**
  String get mbStep3Title;

  /// No description provided for @mbStep3Sub.
  ///
  /// In en, this message translates to:
  /// **'Pick the day and time, and confirm your details.'**
  String get mbStep3Sub;

  /// No description provided for @mbForMyCar.
  ///
  /// In en, this message translates to:
  /// **'One of my cars'**
  String get mbForMyCar;

  /// No description provided for @mbForAnotherCar.
  ///
  /// In en, this message translates to:
  /// **'Another vehicle'**
  String get mbForAnotherCar;

  /// No description provided for @mbVinAuto.
  ///
  /// In en, this message translates to:
  /// **'filled automatically'**
  String get mbVinAuto;

  /// No description provided for @mbNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get mbNext;

  /// No description provided for @mbBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get mbBack;

  /// No description provided for @mbBadgeSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure booking'**
  String get mbBadgeSecure;

  /// No description provided for @mbBadgeWarranty.
  ///
  /// In en, this message translates to:
  /// **'12-month warranty'**
  String get mbBadgeWarranty;

  /// No description provided for @mbBadgeFreeCancel.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get mbBadgeFreeCancel;

  /// No description provided for @calSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get calSun;

  /// No description provided for @calMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get calMon;

  /// No description provided for @calTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get calTue;

  /// No description provided for @calWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get calWed;

  /// No description provided for @calThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get calThu;

  /// No description provided for @calFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get calFri;

  /// No description provided for @calSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get calSat;

  /// No description provided for @calAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get calAvailable;

  /// No description provided for @calHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get calHoliday;

  /// No description provided for @calUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get calUnavailable;

  /// No description provided for @mbSubService.
  ///
  /// In en, this message translates to:
  /// **'Sub-service'**
  String get mbSubService;

  /// No description provided for @protBasePrice.
  ///
  /// In en, this message translates to:
  /// **'Base price'**
  String get protBasePrice;

  /// No description provided for @protVat.
  ///
  /// In en, this message translates to:
  /// **'VAT (15%)'**
  String get protVat;

  /// No description provided for @protTotal.
  ///
  /// In en, this message translates to:
  /// **'Total price'**
  String get protTotal;

  /// No description provided for @protReservePay.
  ///
  /// In en, this message translates to:
  /// **'Reserve & pay securely'**
  String get protReservePay;

  /// No description provided for @protMyCars.
  ///
  /// In en, this message translates to:
  /// **'My cars'**
  String get protMyCars;

  /// No description provided for @payMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get payMethodTitle;

  /// No description provided for @payTinting.
  ///
  /// In en, this message translates to:
  /// **'Tinting grade'**
  String get payTinting;

  /// No description provided for @payConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm & proceed to payment'**
  String get payConfirm;

  /// No description provided for @paySuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed — your reservation is booked. 🎉'**
  String get paySuccess;

  /// No description provided for @payFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment was not completed — you can try again.'**
  String get payFailed;

  /// No description provided for @paySadad.
  ///
  /// In en, this message translates to:
  /// **'Pay via Sadad with this number:'**
  String get paySadad;

  /// No description provided for @payGatewayTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure payment'**
  String get payGatewayTitle;

  /// No description provided for @payMyfatoorahTag.
  ///
  /// In en, this message translates to:
  /// **'Card / Apple Pay / STC Pay'**
  String get payMyfatoorahTag;

  /// No description provided for @payTabbyTag.
  ///
  /// In en, this message translates to:
  /// **'Split in 4 — no interest'**
  String get payTabbyTag;

  /// No description provided for @payTamaraTag.
  ///
  /// In en, this message translates to:
  /// **'Split up to 12 — sharia-compliant'**
  String get payTamaraTag;

  /// No description provided for @homeProtForCar.
  ///
  /// In en, this message translates to:
  /// **'Protection packages for your car'**
  String get homeProtForCar;

  /// No description provided for @offersForYourCar.
  ///
  /// In en, this message translates to:
  /// **'For your car'**
  String get offersForYourCar;

  /// No description provided for @offersPickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get offersPickTime;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Profile & Account'**
  String get profileAccount;

  /// No description provided for @profileVehiclesSub.
  ///
  /// In en, this message translates to:
  /// **'Your garage and car details'**
  String get profileVehiclesSub;

  /// No description provided for @profileOrdersSub.
  ///
  /// In en, this message translates to:
  /// **'Track your orders and services'**
  String get profileOrdersSub;

  /// No description provided for @profileFinanceSub.
  ///
  /// In en, this message translates to:
  /// **'Follow your finance applications'**
  String get profileFinanceSub;

  /// No description provided for @profileFavoritesSub.
  ///
  /// In en, this message translates to:
  /// **'Your saved cars'**
  String get profileFavoritesSub;

  /// No description provided for @profileNotifSub.
  ///
  /// In en, this message translates to:
  /// **'Your notifications inbox'**
  String get profileNotifSub;

  /// No description provided for @profileContactSub.
  ///
  /// In en, this message translates to:
  /// **'Branches and support'**
  String get profileContactSub;

  /// No description provided for @profilePrefs.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePrefs;

  /// No description provided for @profileDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get profileDarkMode;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get profileOn;

  /// No description provided for @profileOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get profileOff;

  /// No description provided for @profilePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal data'**
  String get profilePersonal;

  /// No description provided for @acActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get acActiveBadge;

  /// No description provided for @svcProtectionSub.
  ///
  /// In en, this message translates to:
  /// **'Premium window film and body protection.'**
  String get svcProtectionSub;

  /// No description provided for @svcFinanceSub.
  ///
  /// In en, this message translates to:
  /// **'Flexible plans for your next upgrade.'**
  String get svcFinanceSub;

  /// No description provided for @svcOffersSub.
  ///
  /// In en, this message translates to:
  /// **'Latest vehicle and maintenance offers.'**
  String get svcOffersSub;

  /// No description provided for @svcStoreSub.
  ///
  /// In en, this message translates to:
  /// **'Order your car online in simple steps.'**
  String get svcStoreSub;

  /// No description provided for @svcModelsSub.
  ///
  /// In en, this message translates to:
  /// **'Explore every model and trim.'**
  String get svcModelsSub;

  /// No description provided for @svcFavoritesSub.
  ///
  /// In en, this message translates to:
  /// **'Vehicles you liked, in one place.'**
  String get svcFavoritesSub;

  /// No description provided for @svcFinReqSub.
  ///
  /// In en, this message translates to:
  /// **'Track the status of your finance requests.'**
  String get svcFinReqSub;

  /// No description provided for @svcNewsSub.
  ///
  /// In en, this message translates to:
  /// **'The latest Hassan Jameel news.'**
  String get svcNewsSub;

  /// No description provided for @svcContactSub.
  ///
  /// In en, this message translates to:
  /// **'Our branches and ways to reach us.'**
  String get svcContactSub;

  /// No description provided for @svcTrackingSub.
  ///
  /// In en, this message translates to:
  /// **'Follow your car in the workshop, live.'**
  String get svcTrackingSub;

  /// No description provided for @protPopular.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get protPopular;

  /// No description provided for @protSelectPackage.
  ///
  /// In en, this message translates to:
  /// **'Select Package'**
  String get protSelectPackage;

  /// No description provided for @offersClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim Offer Now'**
  String get offersClaim;

  /// No description provided for @protChoose.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get protChoose;

  /// No description provided for @protWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why choose our services?'**
  String get protWhyTitle;

  /// No description provided for @protWhyUv.
  ///
  /// In en, this message translates to:
  /// **'UV Protection'**
  String get protWhyUv;

  /// No description provided for @protWhyUvSub.
  ///
  /// In en, this message translates to:
  /// **'Shields against sun rays.'**
  String get protWhyUvSub;

  /// No description provided for @protWhyWater.
  ///
  /// In en, this message translates to:
  /// **'Water Repellent'**
  String get protWhyWater;

  /// No description provided for @protWhyWaterSub.
  ///
  /// In en, this message translates to:
  /// **'Hydrophobic nano technology.'**
  String get protWhyWaterSub;

  /// No description provided for @protWhyInstall.
  ///
  /// In en, this message translates to:
  /// **'Expert Installation'**
  String get protWhyInstall;

  /// No description provided for @protWhyInstallSub.
  ///
  /// In en, this message translates to:
  /// **'By certified technicians.'**
  String get protWhyInstallSub;

  /// No description provided for @protWhyWarranty.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed Quality'**
  String get protWhyWarranty;

  /// No description provided for @protWhyWarrantySub.
  ///
  /// In en, this message translates to:
  /// **'Warranty on all services.'**
  String get protWhyWarrantySub;

  /// No description provided for @protBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment Now'**
  String get protBookNow;

  /// No description provided for @protSelectedCar.
  ///
  /// In en, this message translates to:
  /// **'Selected car'**
  String get protSelectedCar;

  /// No description provided for @protPlate.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get protPlate;

  /// No description provided for @protOtherModel.
  ///
  /// In en, this message translates to:
  /// **'Choose another model'**
  String get protOtherModel;

  /// No description provided for @contactCallNow.
  ///
  /// In en, this message translates to:
  /// **'Call now'**
  String get contactCallNow;

  /// No description provided for @partsSortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Best match'**
  String get partsSortRelevance;

  /// No description provided for @jdStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get jdStatus;

  /// No description provided for @jdReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get jdReference;

  /// No description provided for @jdDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get jdDate;

  /// No description provided for @jdTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get jdTotal;

  /// No description provided for @jdPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get jdPayNow;

  /// No description provided for @jdDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get jdDetailsTitle;

  /// No description provided for @pcTitle.
  ///
  /// In en, this message translates to:
  /// **'Parts Cart'**
  String get pcTitle;

  /// No description provided for @pcEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get pcEmpty;

  /// No description provided for @pcSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get pcSummary;

  /// No description provided for @pcCoupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon code'**
  String get pcCoupon;

  /// No description provided for @pcApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get pcApply;

  /// No description provided for @pcCouponInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get pcCouponInvalid;

  /// No description provided for @pcSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get pcSubtotal;

  /// No description provided for @pcDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get pcDiscount;

  /// No description provided for @pcVat.
  ///
  /// In en, this message translates to:
  /// **'VAT (15%)'**
  String get pcVat;

  /// No description provided for @pcTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get pcTotal;

  /// No description provided for @pcCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get pcCheckout;

  /// No description provided for @pcContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue shopping'**
  String get pcContinue;

  /// No description provided for @pcRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get pcRemove;

  /// No description provided for @pcAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get pcAddToCart;

  /// No description provided for @pcInCart.
  ///
  /// In en, this message translates to:
  /// **'In cart'**
  String get pcInCart;

  /// No description provided for @pcQty.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get pcQty;

  /// No description provided for @pcCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout & Payment'**
  String get pcCheckoutTitle;

  /// No description provided for @pcPickup.
  ///
  /// In en, this message translates to:
  /// **'Branch pickup'**
  String get pcPickup;

  /// No description provided for @pcPickupMethod.
  ///
  /// In en, this message translates to:
  /// **'Pickup method'**
  String get pcPickupMethod;

  /// No description provided for @pcChooseBranch.
  ///
  /// In en, this message translates to:
  /// **'Choose branch'**
  String get pcChooseBranch;

  /// No description provided for @pcContact.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get pcContact;

  /// No description provided for @pcPayMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get pcPayMethod;

  /// No description provided for @pcOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get pcOrder;

  /// No description provided for @pcPayMyfatoorah.
  ///
  /// In en, this message translates to:
  /// **'Card — MyFatoorah'**
  String get pcPayMyfatoorah;

  /// No description provided for @pcPayTabby.
  ///
  /// In en, this message translates to:
  /// **'Tabby — split in 4'**
  String get pcPayTabby;

  /// No description provided for @pcPayTamara.
  ///
  /// In en, this message translates to:
  /// **'Tamara — up to 12 installments'**
  String get pcPayTamara;

  /// No description provided for @pcPaySadad.
  ///
  /// In en, this message translates to:
  /// **'Sadad'**
  String get pcPaySadad;

  /// No description provided for @pcSadadTitle.
  ///
  /// In en, this message translates to:
  /// **'Sadad number'**
  String get pcSadadTitle;

  /// No description provided for @pcSadadHint.
  ///
  /// In en, this message translates to:
  /// **'Pay via Sadad using this number.'**
  String get pcSadadHint;

  /// No description provided for @pcSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your order was placed successfully!'**
  String get pcSuccess;

  /// No description provided for @pcOrderNo.
  ///
  /// In en, this message translates to:
  /// **'Order no.'**
  String get pcOrderNo;

  /// No description provided for @pcPayFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment was not completed. Please try again.'**
  String get pcPayFailed;

  /// No description provided for @pcAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get pcAdded;

  /// No description provided for @pcViewCart.
  ///
  /// In en, this message translates to:
  /// **'View cart'**
  String get pcViewCart;

  /// No description provided for @ucTitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted Used Cars'**
  String get ucTitle;

  /// No description provided for @ucSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cars listed by their owners — some inspected by Hassan Jameel for your peace of mind.'**
  String get ucSubtitle;

  /// No description provided for @ucSellCta.
  ///
  /// In en, this message translates to:
  /// **'List your car'**
  String get ucSellCta;

  /// No description provided for @ucEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cars listed right now.'**
  String get ucEmpty;

  /// No description provided for @ucInspected.
  ///
  /// In en, this message translates to:
  /// **'Inspected by Hassan Jameel'**
  String get ucInspected;

  /// No description provided for @ucPriceOnContact.
  ///
  /// In en, this message translates to:
  /// **'Price on contact'**
  String get ucPriceOnContact;

  /// No description provided for @ucKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get ucKm;

  /// No description provided for @ucWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Contact to buy via WhatsApp'**
  String get ucWhatsapp;

  /// No description provided for @ucCarInfo.
  ///
  /// In en, this message translates to:
  /// **'Car information'**
  String get ucCarInfo;

  /// No description provided for @ucInspectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Full car inspection'**
  String get ucInspectionTitle;

  /// No description provided for @ucInspectionSub.
  ///
  /// In en, this message translates to:
  /// **'A thorough check of every part.'**
  String get ucInspectionSub;

  /// No description provided for @ucSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get ucSafety;

  /// No description provided for @ucComfort.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get ucComfort;

  /// No description provided for @ucTech.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get ucTech;

  /// No description provided for @ucExterior.
  ///
  /// In en, this message translates to:
  /// **'Exterior'**
  String get ucExterior;

  /// No description provided for @ucYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get ucYear;

  /// No description provided for @ucMileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get ucMileage;

  /// No description provided for @ucFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get ucFuel;

  /// No description provided for @ucGearbox.
  ///
  /// In en, this message translates to:
  /// **'Gearbox'**
  String get ucGearbox;

  /// No description provided for @ucDrive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get ucDrive;

  /// No description provided for @ucCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get ucCondition;

  /// No description provided for @ucSeats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get ucSeats;

  /// No description provided for @ucDoors.
  ///
  /// In en, this message translates to:
  /// **'Doors'**
  String get ucDoors;

  /// No description provided for @ucExtColor.
  ///
  /// In en, this message translates to:
  /// **'Exterior color'**
  String get ucExtColor;

  /// No description provided for @ucIntColor.
  ///
  /// In en, this message translates to:
  /// **'Interior color'**
  String get ucIntColor;

  /// No description provided for @ucOrigin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get ucOrigin;

  /// No description provided for @ucLicenseDuration.
  ///
  /// In en, this message translates to:
  /// **'License duration'**
  String get ucLicenseDuration;

  /// No description provided for @ucNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get ucNotes;

  /// No description provided for @ucAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your used car'**
  String get ucAddTitle;

  /// No description provided for @ucStepOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ucStepOwner;

  /// No description provided for @ucStepCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get ucStepCar;

  /// No description provided for @ucStepSpecs.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get ucStepSpecs;

  /// No description provided for @ucStepLicense.
  ///
  /// In en, this message translates to:
  /// **'License & notes'**
  String get ucStepLicense;

  /// No description provided for @ucStepPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get ucStepPhotos;

  /// No description provided for @ucStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get ucStepReview;

  /// No description provided for @ucBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get ucBrand;

  /// No description provided for @ucCarName.
  ///
  /// In en, this message translates to:
  /// **'Car name'**
  String get ucCarName;

  /// No description provided for @ucModelName.
  ///
  /// In en, this message translates to:
  /// **'Model / trim'**
  String get ucModelName;

  /// No description provided for @ucBodyType.
  ///
  /// In en, this message translates to:
  /// **'Body type'**
  String get ucBodyType;

  /// No description provided for @ucPrice.
  ///
  /// In en, this message translates to:
  /// **'Price (optional)'**
  String get ucPrice;

  /// No description provided for @ucChassis.
  ///
  /// In en, this message translates to:
  /// **'Chassis number'**
  String get ucChassis;

  /// No description provided for @ucLicenseNo.
  ///
  /// In en, this message translates to:
  /// **'Plate / license number'**
  String get ucLicenseNo;

  /// No description provided for @ucLicenseExpiry.
  ///
  /// In en, this message translates to:
  /// **'License expiry'**
  String get ucLicenseExpiry;

  /// No description provided for @ucReqInspection.
  ///
  /// In en, this message translates to:
  /// **'Request a Hassan Jameel inspection'**
  String get ucReqInspection;

  /// No description provided for @ucAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add car photos'**
  String get ucAddPhotos;

  /// No description provided for @ucSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get ucSubmit;

  /// No description provided for @ucSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request received! We will review the details and contact you on approval.'**
  String get ucSubmitted;

  /// No description provided for @trkHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Order tracking'**
  String get trkHubTitle;

  /// No description provided for @trkAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get trkAll;

  /// No description provided for @trkKindMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get trkKindMaintenance;

  /// No description provided for @trkKindProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection & shading'**
  String get trkKindProtection;

  /// No description provided for @trkKindOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get trkKindOrders;

  /// No description provided for @trkHubEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to track yet.'**
  String get trkHubEmpty;

  /// No description provided for @trkStageBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get trkStageBooked;

  /// No description provided for @trkStageReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get trkStageReceived;

  /// No description provided for @trkStageAgreement.
  ///
  /// In en, this message translates to:
  /// **'Agreement'**
  String get trkStageAgreement;

  /// No description provided for @trkStageInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get trkStageInProgress;

  /// No description provided for @trkStageQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality check'**
  String get trkStageQuality;

  /// No description provided for @trkStageReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get trkStageReady;

  /// No description provided for @trkStageDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get trkStageDelivered;

  /// No description provided for @trkAgreementTitle.
  ///
  /// In en, this message translates to:
  /// **'Your approval is needed'**
  String get trkAgreementTitle;

  /// No description provided for @trkAgreementBody.
  ///
  /// In en, this message translates to:
  /// **'Review and sign the repair agreement so the workshop can start.'**
  String get trkAgreementBody;

  /// No description provided for @trkAgreementCta.
  ///
  /// In en, this message translates to:
  /// **'Review agreement'**
  String get trkAgreementCta;

  /// No description provided for @trkEta.
  ///
  /// In en, this message translates to:
  /// **'Expected ready'**
  String get trkEta;

  /// No description provided for @trkCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get trkCanceled;

  /// No description provided for @trkRateTitle.
  ///
  /// In en, this message translates to:
  /// **'How did we do?'**
  String get trkRateTitle;

  /// No description provided for @trkRateBody.
  ///
  /// In en, this message translates to:
  /// **'Your car is delivered. Rate the service — it takes a minute.'**
  String get trkRateBody;

  /// No description provided for @trkRateCta.
  ///
  /// In en, this message translates to:
  /// **'Rate the service'**
  String get trkRateCta;

  /// No description provided for @evalTitle.
  ///
  /// In en, this message translates to:
  /// **'Service evaluation'**
  String get evalTitle;

  /// No description provided for @evalNote.
  ///
  /// In en, this message translates to:
  /// **'Anything else you\'d like to add?'**
  String get evalNote;

  /// No description provided for @evalNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Your notes (optional)'**
  String get evalNoteHint;

  /// No description provided for @evalTellUs.
  ///
  /// In en, this message translates to:
  /// **'Tell us more'**
  String get evalTellUs;

  /// No description provided for @evalSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit evaluation'**
  String get evalSubmit;

  /// No description provided for @evalMissingAnswers.
  ///
  /// In en, this message translates to:
  /// **'Please answer all required questions.'**
  String get evalMissingAnswers;

  /// No description provided for @evalThanksTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get evalThanksTitle;

  /// No description provided for @evalThanksBody.
  ///
  /// In en, this message translates to:
  /// **'Your evaluation has been recorded. We value your feedback.'**
  String get evalThanksBody;

  /// No description provided for @evalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Evaluation unavailable'**
  String get evalUnavailable;

  /// No description provided for @evalUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This evaluation link is no longer valid.'**
  String get evalUnavailableBody;

  /// No description provided for @mbuyType.
  ///
  /// In en, this message translates to:
  /// **'Purchase type'**
  String get mbuyType;

  /// No description provided for @mbuyOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get mbuyOnline;

  /// No description provided for @mbuyOrder.
  ///
  /// In en, this message translates to:
  /// **'Purchase order'**
  String get mbuyOrder;

  /// No description provided for @mbuyFastReserve.
  ///
  /// In en, this message translates to:
  /// **'Fast reserve'**
  String get mbuyFastReserve;

  /// No description provided for @mbuyCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get mbuyCash;

  /// No description provided for @mbuyDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery method'**
  String get mbuyDelivery;

  /// No description provided for @mbuyBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch pickup'**
  String get mbuyBranch;

  /// No description provided for @mbuyAddress.
  ///
  /// In en, this message translates to:
  /// **'Deliver to address'**
  String get mbuyAddress;

  /// No description provided for @mbuyAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Write the delivery address'**
  String get mbuyAddressHint;

  /// No description provided for @mbuySwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe to complete'**
  String get mbuySwipe;

  /// No description provided for @mbuySelect.
  ///
  /// In en, this message translates to:
  /// **'Select...'**
  String get mbuySelect;

  /// No description provided for @onboardingHello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get onboardingHello;

  /// No description provided for @modelsAvailableTrims.
  ///
  /// In en, this message translates to:
  /// **'Available trims'**
  String get modelsAvailableTrims;

  /// No description provided for @modelsChooseTrim.
  ///
  /// In en, this message translates to:
  /// **'Choose trim'**
  String get modelsChooseTrim;

  /// No description provided for @modelsChosen.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get modelsChosen;

  /// No description provided for @modelsDiffsOnly.
  ///
  /// In en, this message translates to:
  /// **'Show differences only'**
  String get modelsDiffsOnly;

  /// No description provided for @modelsCompareHint.
  ///
  /// In en, this message translates to:
  /// **'Pick two trims to compare side by side'**
  String get modelsCompareHint;

  /// No description provided for @modelsColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available colors'**
  String get modelsColorsTitle;

  /// No description provided for @modelsSpecsFor.
  ///
  /// In en, this message translates to:
  /// **'Trim specifications'**
  String get modelsSpecsFor;

  /// No description provided for @pfTitle.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get pfTitle;

  /// No description provided for @pfMyData.
  ///
  /// In en, this message translates to:
  /// **'My data'**
  String get pfMyData;

  /// No description provided for @pfMyCars.
  ///
  /// In en, this message translates to:
  /// **'My cars'**
  String get pfMyCars;

  /// No description provided for @pfMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get pfMyOrders;

  /// No description provided for @pfMyBookings.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get pfMyBookings;

  /// No description provided for @pfFinanceRequests.
  ///
  /// In en, this message translates to:
  /// **'Finance requests'**
  String get pfFinanceRequests;

  /// No description provided for @pfFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get pfFavorites;

  /// No description provided for @pfNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get pfNotifications;

  /// No description provided for @pfContactData.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get pfContactData;

  /// No description provided for @pfPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get pfPassword;

  /// No description provided for @pfDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get pfDeleteAccount;

  /// No description provided for @pfSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get pfSave;

  /// No description provided for @pfSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get pfSaved;

  /// No description provided for @pfSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Some data could not be saved'**
  String get pfSaveFailed;

  /// No description provided for @pfNameAr.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get pfNameAr;

  /// No description provided for @pfNameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get pfNameEn;

  /// No description provided for @pfFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get pfFirstName;

  /// No description provided for @pfMiddleName.
  ///
  /// In en, this message translates to:
  /// **'Middle name'**
  String get pfMiddleName;

  /// No description provided for @pfLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get pfLastName;

  /// No description provided for @pfGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get pfGender;

  /// No description provided for @pfCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get pfCountry;

  /// No description provided for @pfCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get pfCity;

  /// No description provided for @pfAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get pfAddress;

  /// No description provided for @pfIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity number'**
  String get pfIdentity;

  /// No description provided for @pfCr.
  ///
  /// In en, this message translates to:
  /// **'Commercial registration'**
  String get pfCr;

  /// No description provided for @pfAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get pfAccountType;

  /// No description provided for @pfPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get pfPhone;

  /// No description provided for @pfEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get pfEmail;

  /// No description provided for @pfPhoneExists.
  ///
  /// In en, this message translates to:
  /// **'Phone number already in use'**
  String get pfPhoneExists;

  /// No description provided for @pfEmailExists.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get pfEmailExists;

  /// No description provided for @pfIdentityExists.
  ///
  /// In en, this message translates to:
  /// **'Identity number already in use'**
  String get pfIdentityExists;

  /// No description provided for @pfOldPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get pfOldPassword;

  /// No description provided for @pfNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get pfNewPassword;

  /// No description provided for @pfConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get pfConfirmPassword;

  /// No description provided for @pfPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get pfPasswordMismatch;

  /// No description provided for @pfPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get pfPasswordShort;

  /// No description provided for @pfWrongOldPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get pfWrongOldPassword;

  /// No description provided for @pfChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get pfChangePassword;

  /// No description provided for @pfDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Your account will be deactivated and your data hidden from the app. This cannot be undone from the app.'**
  String get pfDeleteWarning;

  /// No description provided for @pfDeleteConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Type \"DELETE\" to confirm'**
  String get pfDeleteConfirmHint;

  /// No description provided for @pfDeleteWord.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get pfDeleteWord;

  /// No description provided for @pfSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get pfSignedInAs;

  /// No description provided for @pfChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get pfChangePhoto;

  /// No description provided for @pfViewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get pfViewPhoto;

  /// No description provided for @pfPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get pfPhotoUpdated;

  /// No description provided for @pfPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the photo — try again.'**
  String get pfPhotoFailed;

  /// No description provided for @pfGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get pfGuest;

  /// No description provided for @pfSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get pfSignIn;

  /// No description provided for @pfNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get pfNoNotifications;

  /// No description provided for @pfNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get pfNoFavorites;

  /// No description provided for @cmpTitle.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get cmpTitle;

  /// No description provided for @cmpSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit a complaint'**
  String get cmpSubmit;

  /// No description provided for @cmpSubmitSub.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened and our team will follow up step by step'**
  String get cmpSubmitSub;

  /// No description provided for @cmpTrack.
  ///
  /// In en, this message translates to:
  /// **'Track complaints'**
  String get cmpTrack;

  /// No description provided for @cmpTrackSub.
  ///
  /// In en, this message translates to:
  /// **'Follow your complaints and our team\'s replies step by step'**
  String get cmpTrackSub;

  /// No description provided for @cmpType.
  ///
  /// In en, this message translates to:
  /// **'Complaint type'**
  String get cmpType;

  /// No description provided for @cmpTypeSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get cmpTypeSales;

  /// No description provided for @cmpTypeParts.
  ///
  /// In en, this message translates to:
  /// **'Spare parts'**
  String get cmpTypeParts;

  /// No description provided for @cmpTypeMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get cmpTypeMaintenance;

  /// No description provided for @cmpTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cmpTypeOther;

  /// No description provided for @cmpName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get cmpName;

  /// No description provided for @cmpPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get cmpPhone;

  /// No description provided for @cmpEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get cmpEmail;

  /// No description provided for @cmpSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject (optional)'**
  String get cmpSubject;

  /// No description provided for @cmpBody.
  ///
  /// In en, this message translates to:
  /// **'Complaint details'**
  String get cmpBody;

  /// No description provided for @cmpBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us exactly what happened…'**
  String get cmpBodyHint;

  /// No description provided for @cmpAttach.
  ///
  /// In en, this message translates to:
  /// **'Attached photos (optional)'**
  String get cmpAttach;

  /// No description provided for @cmpAttachHint.
  ///
  /// In en, this message translates to:
  /// **'Up to 6 photos (max 4 MB each)'**
  String get cmpAttachHint;

  /// No description provided for @cmpConsent.
  ///
  /// In en, this message translates to:
  /// **'I agree to the privacy policy and processing of my personal data'**
  String get cmpConsent;

  /// No description provided for @cmpSend.
  ///
  /// In en, this message translates to:
  /// **'Submit complaint'**
  String get cmpSend;

  /// No description provided for @cmpSent.
  ///
  /// In en, this message translates to:
  /// **'Your complaint was received'**
  String get cmpSent;

  /// No description provided for @cmpRef.
  ///
  /// In en, this message translates to:
  /// **'Complaint number'**
  String get cmpRef;

  /// No description provided for @cmpStageReceived.
  ///
  /// In en, this message translates to:
  /// **'Complaint received'**
  String get cmpStageReceived;

  /// No description provided for @cmpStageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Update / reply'**
  String get cmpStageUpdated;

  /// No description provided for @cmpStageSolved.
  ///
  /// In en, this message translates to:
  /// **'Solved'**
  String get cmpStageSolved;

  /// No description provided for @cmpStatusNew.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get cmpStatusNew;

  /// No description provided for @cmpStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'New reply'**
  String get cmpStatusUpdated;

  /// No description provided for @cmpStatusSolved.
  ///
  /// In en, this message translates to:
  /// **'Solved'**
  String get cmpStatusSolved;

  /// No description provided for @cmpConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get cmpConversation;

  /// No description provided for @cmpYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get cmpYou;

  /// No description provided for @cmpStaff.
  ///
  /// In en, this message translates to:
  /// **'Customer care team'**
  String get cmpStaff;

  /// No description provided for @cmpReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write your reply…'**
  String get cmpReplyHint;

  /// No description provided for @cmpReplySend.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get cmpReplySend;

  /// No description provided for @cmpEmpty.
  ///
  /// In en, this message translates to:
  /// **'No complaints yet'**
  String get cmpEmpty;

  /// No description provided for @cmpBodyText.
  ///
  /// In en, this message translates to:
  /// **'Complaint text'**
  String get cmpBodyText;

  /// No description provided for @finReqSub.
  ///
  /// In en, this message translates to:
  /// **'Own your car with financing offers you can\'t miss'**
  String get finReqSub;

  /// No description provided for @finAbsher.
  ///
  /// In en, this message translates to:
  /// **'Autofill from Absher'**
  String get finAbsher;

  /// No description provided for @finAbsherOtp.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get finAbsherOtp;

  /// No description provided for @finAbsherId.
  ///
  /// In en, this message translates to:
  /// **'Identity number'**
  String get finAbsherId;

  /// No description provided for @finAbsherMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile (5xxxxxxxx)'**
  String get finAbsherMobile;

  /// No description provided for @finAbsherBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get finAbsherBirth;

  /// No description provided for @finAbsherSend.
  ///
  /// In en, this message translates to:
  /// **'Send verification code'**
  String get finAbsherSend;

  /// No description provided for @finAbsherConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get finAbsherConfirm;

  /// No description provided for @finAbsherFilled.
  ///
  /// In en, this message translates to:
  /// **'Details filled from Absher'**
  String get finAbsherFilled;

  /// No description provided for @finDocs.
  ///
  /// In en, this message translates to:
  /// **'Required documents'**
  String get finDocs;

  /// No description provided for @finDocsHint.
  ///
  /// In en, this message translates to:
  /// **'Optional for now — attach them to speed up your request, or our team will collect them'**
  String get finDocsHint;

  /// No description provided for @finWorkSector.
  ///
  /// In en, this message translates to:
  /// **'Employer type'**
  String get finWorkSector;

  /// No description provided for @finGov.
  ///
  /// In en, this message translates to:
  /// **'Governmental'**
  String get finGov;

  /// No description provided for @finPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private sector'**
  String get finPrivate;

  /// No description provided for @finIdDoc.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get finIdDoc;

  /// No description provided for @finLicenseDoc.
  ///
  /// In en, this message translates to:
  /// **'Driving license'**
  String get finLicenseDoc;

  /// No description provided for @finSalaryDoc.
  ///
  /// In en, this message translates to:
  /// **'Salary letter'**
  String get finSalaryDoc;

  /// No description provided for @finInsuranceDoc.
  ///
  /// In en, this message translates to:
  /// **'GOSI printout'**
  String get finInsuranceDoc;

  /// No description provided for @finStatementDoc.
  ///
  /// In en, this message translates to:
  /// **'Bank statement'**
  String get finStatementDoc;

  /// No description provided for @finUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get finUpload;

  /// No description provided for @finUploaded.
  ///
  /// In en, this message translates to:
  /// **'Attached'**
  String get finUploaded;

  /// No description provided for @finPickFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file (image or PDF)'**
  String get finPickFile;

  /// No description provided for @finFileTooBig.
  ///
  /// In en, this message translates to:
  /// **'Max 4 MB'**
  String get finFileTooBig;

  /// No description provided for @finIncome.
  ///
  /// In en, this message translates to:
  /// **'Net monthly income'**
  String get finIncome;

  /// No description provided for @finFirstPayOptional.
  ///
  /// In en, this message translates to:
  /// **'Down payment (optional)'**
  String get finFirstPayOptional;

  /// No description provided for @finLastPay.
  ///
  /// In en, this message translates to:
  /// **'Final payment'**
  String get finLastPay;

  /// No description provided for @finMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly installment'**
  String get finMonthly;

  /// No description provided for @finFinalPrice.
  ///
  /// In en, this message translates to:
  /// **'Final price'**
  String get finFinalPrice;

  /// No description provided for @finPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance period'**
  String get finPeriodTitle;

  /// No description provided for @finMonths.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get finMonths;

  /// No description provided for @finNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get finNotes;

  /// No description provided for @finFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get finFullName;

  /// No description provided for @finSendReq.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get finSendReq;

  /// No description provided for @finReqSent.
  ///
  /// In en, this message translates to:
  /// **'Your request was received'**
  String get finReqSent;

  /// No description provided for @finReqRef.
  ///
  /// In en, this message translates to:
  /// **'Request number'**
  String get finReqRef;

  /// No description provided for @finTrackCta.
  ///
  /// In en, this message translates to:
  /// **'Track request'**
  String get finTrackCta;

  /// No description provided for @finBankRate.
  ///
  /// In en, this message translates to:
  /// **'Financing entity'**
  String get finBankRate;

  /// No description provided for @finIncomeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your net income'**
  String get finIncomeRequired;

  /// No description provided for @trkKindFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get trkKindFinance;

  /// No description provided for @acJobCard.
  ///
  /// In en, this message translates to:
  /// **'Job card'**
  String get acJobCard;

  /// No description provided for @acTabMyCars.
  ///
  /// In en, this message translates to:
  /// **'My cars'**
  String get acTabMyCars;

  /// No description provided for @acStoreToyota.
  ///
  /// In en, this message translates to:
  /// **'Toyota Store'**
  String get acStoreToyota;

  /// No description provided for @acStoreLexus.
  ///
  /// In en, this message translates to:
  /// **'Lexus Store'**
  String get acStoreLexus;

  /// No description provided for @acKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get acKm;

  /// No description provided for @acQuickTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick services'**
  String get acQuickTitle;

  /// No description provided for @cpnExclusive.
  ///
  /// In en, this message translates to:
  /// **'Exclusive offer'**
  String get cpnExclusive;

  /// No description provided for @cpnCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get cpnCopied;

  /// No description provided for @cpnRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cpnRemove;

  /// No description provided for @cpnCouponDiscount.
  ///
  /// In en, this message translates to:
  /// **'Coupon discount'**
  String get cpnCouponDiscount;

  /// No description provided for @svcPartsSub.
  ///
  /// In en, this message translates to:
  /// **'Genuine parts for your car — branch pickup'**
  String get svcPartsSub;

  /// No description provided for @mhTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance services'**
  String get mhTitle;

  /// No description provided for @mhHeroBadge.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Center'**
  String get mhHeroBadge;

  /// No description provided for @mhHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Book your maintenance'**
  String get mhHeroTitle;

  /// No description provided for @mhHeroAccent.
  ///
  /// In en, this message translates to:
  /// **'in 10 seconds'**
  String get mhHeroAccent;

  /// No description provided for @mhHeroSub.
  ///
  /// In en, this message translates to:
  /// **'Certified maintenance center with 60+ years of experience. Original parts and factory-certified technicians.'**
  String get mhHeroSub;

  /// No description provided for @mhBadgeCertified.
  ///
  /// In en, this message translates to:
  /// **'Officially certified'**
  String get mhBadgeCertified;

  /// No description provided for @mhBadgeSaso.
  ///
  /// In en, this message translates to:
  /// **'SASO certified'**
  String get mhBadgeSaso;

  /// No description provided for @mhReserveNow.
  ///
  /// In en, this message translates to:
  /// **'Reserve now'**
  String get mhReserveNow;

  /// No description provided for @mhPeriodic.
  ///
  /// In en, this message translates to:
  /// **'Periodic schedule'**
  String get mhPeriodic;

  /// No description provided for @mhYears.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get mhYears;

  /// No description provided for @mhCars.
  ///
  /// In en, this message translates to:
  /// **'Cars served'**
  String get mhCars;

  /// No description provided for @mhSatisfaction.
  ///
  /// In en, this message translates to:
  /// **'Satisfaction'**
  String get mhSatisfaction;

  /// No description provided for @mhBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get mhBranches;

  /// No description provided for @mhJourney.
  ///
  /// In en, this message translates to:
  /// **'Your maintenance journey'**
  String get mhJourney;

  /// No description provided for @mhJourneySub.
  ///
  /// In en, this message translates to:
  /// **'Four simple steps from booking to handover.'**
  String get mhJourneySub;

  /// No description provided for @mhStep1.
  ///
  /// In en, this message translates to:
  /// **'Book appointment'**
  String get mhStep1;

  /// No description provided for @mhStep1Sub.
  ///
  /// In en, this message translates to:
  /// **'Choose the service and time that suits you'**
  String get mhStep1Sub;

  /// No description provided for @mhStep2.
  ///
  /// In en, this message translates to:
  /// **'Car inspection'**
  String get mhStep2;

  /// No description provided for @mhStep2Sub.
  ///
  /// In en, this message translates to:
  /// **'Our experts perform a precise comprehensive check'**
  String get mhStep2Sub;

  /// No description provided for @mhStep3.
  ///
  /// In en, this message translates to:
  /// **'Execution'**
  String get mhStep3;

  /// No description provided for @mhStep3Sub.
  ///
  /// In en, this message translates to:
  /// **'Maintenance completed with the highest quality standards'**
  String get mhStep3Sub;

  /// No description provided for @mhStep4.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get mhStep4;

  /// No description provided for @mhStep4Sub.
  ///
  /// In en, this message translates to:
  /// **'Receive your car ready and in best condition'**
  String get mhStep4Sub;

  /// No description provided for @mhOffers.
  ///
  /// In en, this message translates to:
  /// **'Maintenance offers'**
  String get mhOffers;

  /// No description provided for @mhWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why choose Hassan Jameel?'**
  String get mhWhyTitle;

  /// No description provided for @mhWhySub.
  ///
  /// In en, this message translates to:
  /// **'Numbers and facts that speak for themselves.'**
  String get mhWhySub;

  /// No description provided for @mhFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get mhFeatures;

  /// No description provided for @mhUs.
  ///
  /// In en, this message translates to:
  /// **'Us'**
  String get mhUs;

  /// No description provided for @mhOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get mhOthers;

  /// No description provided for @mhRowParts.
  ///
  /// In en, this message translates to:
  /// **'100% original parts'**
  String get mhRowParts;

  /// No description provided for @mhRowDiag.
  ///
  /// In en, this message translates to:
  /// **'Factory-certified diagnostics'**
  String get mhRowDiag;

  /// No description provided for @mhRowTeam.
  ///
  /// In en, this message translates to:
  /// **'Specialized team'**
  String get mhRowTeam;

  /// No description provided for @mhRowReport.
  ///
  /// In en, this message translates to:
  /// **'Digital technical report with photos'**
  String get mhRowReport;

  /// No description provided for @mhRowTech.
  ///
  /// In en, this message translates to:
  /// **'Factory-certified technicians'**
  String get mhRowTech;

  /// No description provided for @mhFeedback.
  ///
  /// In en, this message translates to:
  /// **'Guest feedback'**
  String get mhFeedback;

  /// No description provided for @mhVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get mhVerified;

  /// No description provided for @mhPeriodicTitle.
  ///
  /// In en, this message translates to:
  /// **'Periodic maintenance schedule'**
  String get mhPeriodicTitle;

  /// No description provided for @mhPeriodicSub.
  ///
  /// In en, this message translates to:
  /// **'Pick a mileage to see its scheduled tasks.'**
  String get mhPeriodicSub;

  /// No description provided for @mhPeriodicEmpty.
  ///
  /// In en, this message translates to:
  /// **'No periodic data available.'**
  String get mhPeriodicEmpty;

  /// No description provided for @mhImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get mhImportant;

  /// No description provided for @mhReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to book?'**
  String get mhReady;

  /// No description provided for @mhReadySub.
  ///
  /// In en, this message translates to:
  /// **'Reserve your slot in seconds and drive away with confidence.'**
  String get mhReadySub;

  /// No description provided for @mhBookService.
  ///
  /// In en, this message translates to:
  /// **'Book a service'**
  String get mhBookService;

  /// No description provided for @mhWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Talk on WhatsApp'**
  String get mhWhatsApp;

  /// No description provided for @alNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get alNickname;

  /// No description provided for @alRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get alRename;

  /// No description provided for @alSaved.
  ///
  /// In en, this message translates to:
  /// **'Name saved'**
  String get alSaved;

  /// No description provided for @contactPopTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer service'**
  String get contactPopTitle;

  /// No description provided for @contactPopOnline.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get contactPopOnline;

  /// No description provided for @contactPopWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp chat'**
  String get contactPopWhatsApp;

  /// No description provided for @contactPopCall.
  ///
  /// In en, this message translates to:
  /// **'Call us'**
  String get contactPopCall;

  /// No description provided for @osOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get osOrderDetails;

  /// No description provided for @osInclVat.
  ///
  /// In en, this message translates to:
  /// **'Including Value Added Tax'**
  String get osInclVat;

  /// No description provided for @osExteriorColor.
  ///
  /// In en, this message translates to:
  /// **'Exterior color'**
  String get osExteriorColor;

  /// No description provided for @osInnerColor.
  ///
  /// In en, this message translates to:
  /// **'Inner color'**
  String get osInnerColor;

  /// No description provided for @osTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get osTotal;

  /// No description provided for @osAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount required to be paid'**
  String get osAmountRequired;

  /// No description provided for @osHowYouPay.
  ///
  /// In en, this message translates to:
  /// **'How you pay'**
  String get osHowYouPay;

  /// No description provided for @osPayHint.
  ///
  /// In en, this message translates to:
  /// **'The down payment is paid by Visa or Mada; the remaining amount via SADAD.'**
  String get osPayHint;

  /// No description provided for @formPayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Pay & confirm'**
  String get formPayConfirm;

  /// No description provided for @reserveWillPay.
  ///
  /// In en, this message translates to:
  /// **'You will pay now'**
  String get reserveWillPay;

  /// No description provided for @linkTerms.
  ///
  /// In en, this message translates to:
  /// **'terms & conditions'**
  String get linkTerms;

  /// No description provided for @linkPrivacy.
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get linkPrivacy;

  /// No description provided for @termsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I have read the '**
  String get termsPrefix;

  /// No description provided for @termsJoin.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get termsJoin;

  /// No description provided for @termsSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get termsSuffix;

  /// No description provided for @finReqLearnTitle.
  ///
  /// In en, this message translates to:
  /// **'What are the financing requirements & required documents?'**
  String get finReqLearnTitle;

  /// No description provided for @finReqLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get finReqLearnMore;

  /// No description provided for @finReqDialogReqs.
  ///
  /// In en, this message translates to:
  /// **'Financing requirements:'**
  String get finReqDialogReqs;

  /// No description provided for @finReqDialogDocs.
  ///
  /// In en, this message translates to:
  /// **'Required documents:'**
  String get finReqDialogDocs;

  /// No description provided for @finReqSaudi.
  ///
  /// In en, this message translates to:
  /// **'Saudi'**
  String get finReqSaudi;

  /// No description provided for @finReqResident.
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get finReqResident;

  /// No description provided for @finReqAge.
  ///
  /// In en, this message translates to:
  /// **'Client age from 21 years'**
  String get finReqAge;

  /// No description provided for @finReqWorkDuration.
  ///
  /// In en, this message translates to:
  /// **'Employment duration of 95 days'**
  String get finReqWorkDuration;

  /// No description provided for @finReqSalarySaudi.
  ///
  /// In en, this message translates to:
  /// **'Salary from SAR 3,000'**
  String get finReqSalarySaudi;

  /// No description provided for @finReqSalaryResident.
  ///
  /// In en, this message translates to:
  /// **'Salary from SAR 5,000'**
  String get finReqSalaryResident;

  /// No description provided for @finReqDoc1.
  ///
  /// In en, this message translates to:
  /// **'Valid national ID'**
  String get finReqDoc1;

  /// No description provided for @finReqDoc2.
  ///
  /// In en, this message translates to:
  /// **'Valid driving license'**
  String get finReqDoc2;

  /// No description provided for @finReqDoc3.
  ///
  /// In en, this message translates to:
  /// **'Recent GOSI (insurance) print — no older than 10 days'**
  String get finReqDoc3;

  /// No description provided for @finReqDoc4.
  ///
  /// In en, this message translates to:
  /// **'Salary certificate attested by the Chamber of Commerce — no older than 2 months'**
  String get finReqDoc4;

  /// No description provided for @finReqDoc5.
  ///
  /// In en, this message translates to:
  /// **'Bank statement for the last 3 months'**
  String get finReqDoc5;

  /// No description provided for @cpcTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your purchase'**
  String get cpcTitle;

  /// No description provided for @cpcDepositBanner.
  ///
  /// In en, this message translates to:
  /// **'Your deposit is received and your car is reserved. Continue the purchase steps below.'**
  String get cpcDepositBanner;

  /// No description provided for @cpcYourCar.
  ///
  /// In en, this message translates to:
  /// **'Your car'**
  String get cpcYourCar;

  /// No description provided for @cpcStepProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection & Shading'**
  String get cpcStepProtection;

  /// No description provided for @cpcStepContract.
  ///
  /// In en, this message translates to:
  /// **'Contract & signature'**
  String get cpcStepContract;

  /// No description provided for @cpcStepDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery scheduling'**
  String get cpcStepDelivery;

  /// No description provided for @cpcStepPayment.
  ///
  /// In en, this message translates to:
  /// **'Remaining payment'**
  String get cpcStepPayment;

  /// No description provided for @cpcProtectionHint.
  ///
  /// In en, this message translates to:
  /// **'Choose any protection & shading packages to add to your car (optional).'**
  String get cpcProtectionHint;

  /// No description provided for @cpcNoPackages.
  ///
  /// In en, this message translates to:
  /// **'No protection packages are available for this vehicle. You can continue without adding any.'**
  String get cpcNoPackages;

  /// No description provided for @cpcNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get cpcNoneSelected;

  /// No description provided for @cpcSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String cpcSelectedCount(int count);

  /// No description provided for @cpcByChoice.
  ///
  /// In en, this message translates to:
  /// **'By selection'**
  String get cpcByChoice;

  /// No description provided for @cpcConfirmSelection.
  ///
  /// In en, this message translates to:
  /// **'Confirm selection'**
  String get cpcConfirmSelection;

  /// No description provided for @cpcContinueWithout.
  ///
  /// In en, this message translates to:
  /// **'Continue without adding'**
  String get cpcContinueWithout;

  /// No description provided for @cpcLockedStep.
  ///
  /// In en, this message translates to:
  /// **'This step is coming soon in the app — our team will contact you to complete it.'**
  String get cpcLockedStep;

  /// No description provided for @cpcNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find the car reservation for this link.'**
  String get cpcNotFound;

  /// No description provided for @cpcResumeBanner.
  ///
  /// In en, this message translates to:
  /// **'Continue your car purchase'**
  String get cpcResumeBanner;

  /// No description provided for @cpcSelectionDone.
  ///
  /// In en, this message translates to:
  /// **'Your selection is noted — the next steps will be completed with our team.'**
  String get cpcSelectionDone;

  /// No description provided for @cpcCompletePurchase.
  ///
  /// In en, this message translates to:
  /// **'Complete purchase'**
  String get cpcCompletePurchase;

  /// No description provided for @cpcBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get cpcBack;

  /// No description provided for @cpcSignInFirst.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your car purchase steps.'**
  String get cpcSignInFirst;

  /// No description provided for @cpcContractTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales contract & signature'**
  String get cpcContractTitle;

  /// No description provided for @cpcAddons.
  ///
  /// In en, this message translates to:
  /// **'Add-ons:'**
  String get cpcAddons;

  /// No description provided for @cpcContractPreparing.
  ///
  /// In en, this message translates to:
  /// **'Creating your sales order and preparing the contract, please don\'t close this screen…'**
  String get cpcContractPreparing;

  /// No description provided for @cpcContractFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the sales order.'**
  String get cpcContractFailed;

  /// No description provided for @cpcContractReady.
  ///
  /// In en, this message translates to:
  /// **'Your sales contract is ready.'**
  String get cpcContractReady;

  /// No description provided for @cpcViewContract.
  ///
  /// In en, this message translates to:
  /// **'View contract (PDF)'**
  String get cpcViewContract;

  /// No description provided for @cpcAgreeContract.
  ///
  /// In en, this message translates to:
  /// **'I agree to the terms & conditions of the sales contract.'**
  String get cpcAgreeContract;

  /// No description provided for @cpcAgreeFirst.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the terms first.'**
  String get cpcAgreeFirst;

  /// No description provided for @cpcNoIdentity.
  ///
  /// In en, this message translates to:
  /// **'Your account has no valid identity number.'**
  String get cpcNoIdentity;

  /// No description provided for @cpcSignAbsher.
  ///
  /// In en, this message translates to:
  /// **'Sign with Absher'**
  String get cpcSignAbsher;

  /// No description provided for @cpcSignOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the Absher verification code sent to your phone'**
  String get cpcSignOtpHint;

  /// No description provided for @cpcSignConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm signature'**
  String get cpcSignConfirm;

  /// No description provided for @cpcSignResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get cpcSignResend;

  /// No description provided for @cpcSignSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the verification code, try again.'**
  String get cpcSignSendFailed;

  /// No description provided for @cpcSignInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code.'**
  String get cpcSignInvalidOtp;

  /// No description provided for @cpcTestModeSign.
  ///
  /// In en, this message translates to:
  /// **'Test mode: signing without Absher.'**
  String get cpcTestModeSign;

  /// No description provided for @cpcSignTest.
  ///
  /// In en, this message translates to:
  /// **'Sign contract (test)'**
  String get cpcSignTest;

  /// No description provided for @cpcAlreadySigned.
  ///
  /// In en, this message translates to:
  /// **'The contract is signed.'**
  String get cpcAlreadySigned;

  /// No description provided for @cpcContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get cpcContinue;

  /// No description provided for @cpcDeliveryHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a date and time to receive your car.'**
  String get cpcDeliveryHint;

  /// No description provided for @cpcDeliveryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading delivery scheduling…'**
  String get cpcDeliveryLoading;

  /// No description provided for @cpcDeliveryNotReady.
  ///
  /// In en, this message translates to:
  /// **'Delivery scheduling will open once your order is confirmed (usually within one working day). You can continue to payment now and schedule delivery later.'**
  String get cpcDeliveryNotReady;

  /// No description provided for @cpcDeliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get cpcDeliveryDate;

  /// No description provided for @cpcDeliveryTimes.
  ///
  /// In en, this message translates to:
  /// **'Available times'**
  String get cpcDeliveryTimes;

  /// No description provided for @cpcDeliveryNoSlots.
  ///
  /// In en, this message translates to:
  /// **'No available times on this day. Try another date.'**
  String get cpcDeliveryNoSlots;

  /// No description provided for @cpcDeliveryBooked.
  ///
  /// In en, this message translates to:
  /// **'Delivery slot booked'**
  String get cpcDeliveryBooked;

  /// No description provided for @cpcDeliveryBookFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t book the slot, try again.'**
  String get cpcDeliveryBookFailed;

  /// No description provided for @cpcDeliveryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm slot'**
  String get cpcDeliveryConfirm;

  /// No description provided for @cpcDeliveryLater.
  ///
  /// In en, this message translates to:
  /// **'Schedule later'**
  String get cpcDeliveryLater;

  /// No description provided for @cpcContinuePayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get cpcContinuePayment;

  /// No description provided for @cpcPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay the remaining amount'**
  String get cpcPayTitle;

  /// No description provided for @cpcPayCar.
  ///
  /// In en, this message translates to:
  /// **'Car price (incl. VAT)'**
  String get cpcPayCar;

  /// No description provided for @cpcPayAddons.
  ///
  /// In en, this message translates to:
  /// **'Add-ons (protection & shading)'**
  String get cpcPayAddons;

  /// No description provided for @cpcPayDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit paid'**
  String get cpcPayDeposit;

  /// No description provided for @cpcPayRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining amount'**
  String get cpcPayRemaining;

  /// No description provided for @cpcPayProceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed to payment'**
  String get cpcPayProceed;

  /// No description provided for @cpcSadadOpenBank.
  ///
  /// In en, this message translates to:
  /// **'Open your bank app → SADAD and enter the number to pay.'**
  String get cpcSadadOpenBank;

  /// No description provided for @cpcPayDone.
  ///
  /// In en, this message translates to:
  /// **'Your car purchase is complete'**
  String get cpcPayDone;

  /// No description provided for @cpcPayProcessing.
  ///
  /// In en, this message translates to:
  /// **'Payment is being processed'**
  String get cpcPayProcessing;

  /// No description provided for @cpcPayThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for choosing Hassan Jameel. Your delivery details will follow shortly.'**
  String get cpcPayThanks;

  /// No description provided for @cpcPayConfirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming your payment…'**
  String get cpcPayConfirming;

  /// No description provided for @cpcTestModePay.
  ///
  /// In en, this message translates to:
  /// **'Test mode: payment is marked complete without going to the gateway.'**
  String get cpcTestModePay;

  /// No description provided for @cpcPayTest.
  ///
  /// In en, this message translates to:
  /// **'Complete purchase (test)'**
  String get cpcPayTest;

  /// No description provided for @cpcTestPaid.
  ///
  /// In en, this message translates to:
  /// **'Purchase completed (test mode)'**
  String get cpcTestPaid;

  /// No description provided for @cpcTestPaidHint.
  ///
  /// In en, this message translates to:
  /// **'All steps passed successfully without a real charge.'**
  String get cpcTestPaidHint;

  /// No description provided for @offersFinancingBy.
  ///
  /// In en, this message translates to:
  /// **'Financing by'**
  String get offersFinancingBy;

  /// No description provided for @pfDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Warning: this will permanently delete your account and hide all your data — it cannot be undone from the app.'**
  String get pfDeleteNote;

  /// No description provided for @pfDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get pfDeleteDialogTitle;

  /// No description provided for @pfDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? Your data will be hidden from the app and this cannot be undone.'**
  String get pfDeleteDialogBody;

  /// No description provided for @pfCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pfCancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
