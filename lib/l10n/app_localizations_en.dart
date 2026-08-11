// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hassan Jameel';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingSignIn => 'Sign In';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingTerms =>
      'By continuing, you agree to our Terms of Service';

  @override
  String get authWelcomeBack => 'Welcome Back';

  @override
  String get authLoginSubtitle => 'Log in to your account';

  @override
  String get authEmailOrPhone => 'Email, Phone or Identity';

  @override
  String get authEmailOrPhoneHint =>
      'you@example.com / 05xxxxxxxx / 1xxxxxxxxx';

  @override
  String get authContinue => 'Continue';

  @override
  String get authPassword => 'Password';

  @override
  String get authForgotPassword => 'Forgot Password?';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authOr => 'OR';

  @override
  String get authContinueAsGuest => 'Continue as Guest';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authInvalidAccess =>
      'Enter a valid email, phone, or identity number.';

  @override
  String get authRequiredField => 'This field is required';

  @override
  String get authInvalidEmail => 'Enter a valid email address';

  @override
  String get authInvalidCredentials => 'Invalid email or password.';

  @override
  String get authOtpTitle => 'Verification code';

  @override
  String get authOtpSentTo => 'We sent a verification code to';

  @override
  String get authOtpInvalid => 'Invalid verification code.';

  @override
  String get authOtpResend => 'Resend code';

  @override
  String get authBack => 'Back';

  @override
  String authDevOtpHint(String code) {
    return 'Dev OTP: $code';
  }

  @override
  String get absherTitle => 'Register with Absher';

  @override
  String get absherStep1 => 'Step 1 of 2 — complete Absher verification';

  @override
  String get absherStep2 => 'Step 2 of 2 — confirm the Absher code';

  @override
  String get absherLanguage => 'Language';

  @override
  String get absherArabic => 'Arabic';

  @override
  String get absherEnglish => 'English';

  @override
  String get absherIdentity => 'Identity number';

  @override
  String get absherMobile => 'Mobile number';

  @override
  String get absherBirthdate => 'Birth date';

  @override
  String get absherBirthdateHint => '1995-05';

  @override
  String get absherRegister => 'Register';

  @override
  String get absherOtpSent =>
      'We sent an Absher verification code to your registered mobile.';

  @override
  String get absherConfirm => 'Confirm OTP';

  @override
  String get absherInvalidIdentity => 'Enter a valid identity number.';

  @override
  String get absherInvalidMobile => 'Mobile must be 9 digits (e.g. 5xxxxxxxx).';

  @override
  String get absherInvalidBirthdate =>
      'Birth date must be YYYY-MM (e.g. 1995-05).';

  @override
  String get absherFailed => 'Could not complete Absher registration.';

  @override
  String get absherOtpInvalid => 'Invalid or expired OTP.';

  @override
  String get absherSessionExpired => 'Session expired, please try again.';

  @override
  String get absherHaveAccount => 'I have an account — sign in';

  @override
  String get authRegisteredNotice =>
      'Account created via Absher — sign in with your mobile number.';

  @override
  String get authNotFoundNotice =>
      'No account found for these details — create a new one.';

  @override
  String get forgotTitle => 'Reset password';

  @override
  String get forgotSubtitle => 'We\'ll send a verification code to your phone';

  @override
  String get forgotPhone => 'Phone number';

  @override
  String get forgotSendCode => 'Send code';

  @override
  String get forgotSendFailed => 'Could not send the code. Check the number.';

  @override
  String get forgotNewPassword => 'New password';

  @override
  String get forgotConfirmPassword => 'Confirm password';

  @override
  String get forgotSave => 'Save password';

  @override
  String get forgotFailed => 'Could not update password.';

  @override
  String get forgotDoneNotice => 'Password updated — sign in.';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get authPasswordsDontMatch => 'Passwords do not match';

  @override
  String get authInvalidPhone =>
      'Enter a valid Saudi phone number (05xxxxxxxx)';

  @override
  String get authNetworkError =>
      'Cannot reach the server. Check your connection.';

  @override
  String get authGenericError => 'Something went wrong. Please try again.';

  @override
  String get homeWelcome => 'Welcome';

  @override
  String get homeGuest => 'Guest';

  @override
  String get homeOnlineStore => 'Online Store';

  @override
  String get homeOnlineStoreSub => 'Reserve your car online with home delivery';

  @override
  String get homeViewAll => 'VIEW ALL';

  @override
  String get homeMeetTheModels => 'Meet the models';

  @override
  String get homeAll => 'All';

  @override
  String get homeProtection => 'Protection & Shading';

  @override
  String get homeProtectionDesc =>
      'Keep the factory shine with advanced shading and protective coatings.';

  @override
  String get homeSelectCar => 'Select Car';

  @override
  String get homeSelectModel => 'Select Model';

  @override
  String get homeServiceType => 'Service Type';

  @override
  String get homeCheckAvailability => 'Check Availability';

  @override
  String get homeSpareParts => 'Genuine Spare Parts';

  @override
  String get homeSparePartsSub => 'Find parts compatible with your vehicle';

  @override
  String get homeAddToCart => 'ADD TO CART';

  @override
  String get homeUsedCars => 'Trusted Used Cars';

  @override
  String get homeUsedCarsSub => 'Some inspected by Hassan Jameel';

  @override
  String get homeUsedCarsEmpty =>
      'No cars listed yet — be the first to list yours.';

  @override
  String get homeListYourCar => 'List your car';

  @override
  String get homeInspected => 'Inspected by Hassan Jameel';

  @override
  String get homeMaintenanceSpecials => 'Maintenance Specials';

  @override
  String get homeMaintenanceSpecialsSub => 'Keep your car in peak condition';

  @override
  String get homeVehicleOffers => 'Drive home with an offer';

  @override
  String get homeBuyNow => 'Buy Now';

  @override
  String get homeBook => 'Book';

  @override
  String get homeViewOffer => 'View offer';

  @override
  String get homeReserveNow => 'Reserve Now';

  @override
  String homeDaysLeft(int count) {
    return '$count days left';
  }

  @override
  String get homeFrom => 'From';

  @override
  String get currency => 'SAR';

  @override
  String get homeContactForPrice => 'Contact for price';

  @override
  String get homeComingSoonFeature => 'Coming soon';

  @override
  String get homeErrorRetry => 'Couldn\'t load the page. Tap to retry.';

  @override
  String get homeSignOut => 'Sign Out';

  @override
  String get homeThemeMode => 'Dark mode';

  @override
  String get settingsLanguage => 'العربية';

  @override
  String get brandToyota => 'Toyota';

  @override
  String get brandLexus => 'Lexus';

  @override
  String storeModelsCount(int count) {
    return '$count models available for instant reservation';
  }

  @override
  String get storeFilters => 'Filters';

  @override
  String get storeSearch => 'Search a model…';

  @override
  String osHeroGreeting(String name) {
    return 'Hello $name 👋';
  }

  @override
  String get osHeroGreetingGuest => 'Welcome 👋';

  @override
  String get osHeroTitle => 'Find your perfect car';

  @override
  String get storePriceUpTo => 'Price up to';

  @override
  String get storeCategories => 'Categories';

  @override
  String get storeColor => 'Color';

  @override
  String get storeAllColors => 'All colors';

  @override
  String get storeClearFilters => 'Clear all filters';

  @override
  String get storeApplyFilters => 'Show results';

  @override
  String get storeNoResults => 'No cars match your filters.';

  @override
  String get storeAvailableOnline => 'AVAILABLE ONLINE';

  @override
  String get storeFrom => 'FROM';

  @override
  String get storeVatNote =>
      'Inclusive of 15% VAT, License plate and Registration fees';

  @override
  String get storeAddToCart => 'Add to cart';

  @override
  String get cartAdded => 'Added to cart';

  @override
  String get cartTitle => 'My Cart';

  @override
  String get cartMakePayment => 'Make Payment';

  @override
  String get cartEmpty => 'Your cart is empty — browse the online store.';

  @override
  String get cartBrowse => 'Browse cars';

  @override
  String get cartTabVehicles => 'Vehicles cart';

  @override
  String get cartTabParts => 'Spare parts cart';

  @override
  String get favTitle => 'Favorites';

  @override
  String get favEmpty => 'No favorites yet — tap the heart on any car.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get sheetPickColor => 'Pick a color';

  @override
  String get sheetFinancingOptions => 'FINANCING OPTIONS';

  @override
  String get sheetPickBank => 'Pick a bank';

  @override
  String sheetBanksCount(int count) {
    return '$count banks offer financing for this vehicle.';
  }

  @override
  String get bankMonthly => 'MONTHLY';

  @override
  String get bankDown => 'DOWN';

  @override
  String get bankAdminFees => 'ADMIN FEES';

  @override
  String get bankTotal => 'TOTAL';

  @override
  String bankMonths(int count) {
    return '$count MONTHS';
  }

  @override
  String get sheetHowToBuy => 'How would you like to buy this car?';

  @override
  String get sheetSelectYourCar => 'Select Your Car';

  @override
  String get sheetLearnMore => 'Learn more';

  @override
  String get sheetNext => 'NEXT';

  @override
  String get ghHeroTitle => 'Your New Car Starts Here';

  @override
  String get ghHeroSubtitle =>
      'Discover Toyota & Lexus vehicles and finance offers';

  @override
  String get ghBrowseCars => 'Browse Cars';

  @override
  String get ghCalcFinance => 'Calculate Finance';

  @override
  String get ghQuickActions => 'Quick Actions';

  @override
  String get ghBookMaintenance => 'Book Service';

  @override
  String get ghCarOffers => 'Car Offers';

  @override
  String get ghMaintOffers => 'Service Offers';

  @override
  String get ghSpareParts => 'Spare Parts';

  @override
  String get ghBrowseByType => 'Browse Cars';

  @override
  String ghCarsCount(int count) {
    return '$count cars';
  }

  @override
  String get ghFinanceOffers => 'Finance Offers';

  @override
  String get ghServices => 'Hassan Jameel Services';

  @override
  String get ghSvcMaintenance => 'Maintenance';

  @override
  String get ghSvcProtection => 'Protection & Shading';

  @override
  String get ghSvcParts => 'Spare Parts';

  @override
  String get ghSvcFinance => 'Finance';

  @override
  String get ghLoginBenefit =>
      'Sign in to track your car, bookings, invoices and your exclusive offers.';

  @override
  String get ghLoginRequired =>
      'This service needs an account — sign in to track your bookings and orders.';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabGallery => 'Gallery';

  @override
  String get tabSpecs => 'Specs';

  @override
  String get tabFeatures => 'Features';

  @override
  String get tabComparison => 'Comparison';

  @override
  String get modelsPrice => 'Price';

  @override
  String get modelsTrims => 'Trims & Prices';

  @override
  String get modelsNoData => 'No data available for this model.';

  @override
  String get specYear => 'Year';

  @override
  String get specHp => 'Horsepower';

  @override
  String get specFuel => 'Fuel';

  @override
  String get specSeats => 'Seats';

  @override
  String get specCylinders => 'Cylinders';

  @override
  String get methodReserveTitle => 'Quick reservation';

  @override
  String get methodReserveBadge => 'BEST CHOICE';

  @override
  String get methodSignIn => 'Sign in';

  @override
  String get methodRefundable => 'Refundable';

  @override
  String get methodFree => 'Free';

  @override
  String get methodReserveB1 => 'The fastest way to receive your car';

  @override
  String get methodReserveB2 =>
      'Locks the price while you complete the purchase';

  @override
  String get methodReserveB3 => 'Reservation period: 1 business day';

  @override
  String get methodFinanceTitle => 'Apply for finance';

  @override
  String get methodFinanceB1 => 'Get a preliminary approval within minutes';

  @override
  String get methodFinanceB2 => 'A variety of options that fit your income';

  @override
  String get methodFinanceB3 => 'A finance specialist guides you step by step';

  @override
  String get methodContactTitle => 'Request a callback';

  @override
  String get methodContactB1 =>
      'A sales consultant calls you within minutes (work hours)';

  @override
  String get methodContactB2 => 'Help you with car details and the best offers';

  @override
  String get sheetTerms =>
      'I have read the terms & conditions and privacy policy.';

  @override
  String get sheetContinue => 'Continue';

  @override
  String get formApplicant => 'Applicant type';

  @override
  String get formName => 'Full name';

  @override
  String get formPhone => 'Mobile number';

  @override
  String get formEmail => 'Email';

  @override
  String get formCity => 'City';

  @override
  String get formIdentity => 'Identity number';

  @override
  String get formCN => 'Commercial registration (CN)';

  @override
  String get formQuantity => 'Quantity';

  @override
  String get formNote => 'Note (optional)';

  @override
  String get formSend => 'Send request';

  @override
  String get formNameAr => 'Full name (Arabic)';

  @override
  String get formNameEn => 'Full name (English)';

  @override
  String get formGender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get formWhatsapp => 'Receive updates on WhatsApp';

  @override
  String get stepPersonal => 'Personal';

  @override
  String get stepWork => 'Work';

  @override
  String get stepDocuments => 'Documents';

  @override
  String get formJob => 'Job title';

  @override
  String get formIncome => 'Monthly income';

  @override
  String get formFirstPayment => 'First payment (optional)';

  @override
  String get formMonthlyAmount => 'Preferred monthly installment (optional)';

  @override
  String get formPeriod => 'Finance period (months)';

  @override
  String get formWorkType => 'Work sector';

  @override
  String get workPrivate => 'Private';

  @override
  String get workGovernmental => 'Governmental';

  @override
  String get formSalaryBank => 'Salary bank';

  @override
  String get financeQ1 => 'Are you registered in SIMAH?';

  @override
  String get financeQ2 => 'Do you have traffic violations?';

  @override
  String get financeQ3 => 'Do you have a real-estate loan?';

  @override
  String get financeQ4 => 'Do you have other obligations?';

  @override
  String get answerYes => 'Yes';

  @override
  String get answerNo => 'No';

  @override
  String get formViolationsAmount => 'Violations amount';

  @override
  String get formObligationsAmount => 'Monthly obligations amount';

  @override
  String get formFinanceBank => 'Financing entity';

  @override
  String get docIdentity => 'National ID / CN';

  @override
  String get docLicense => 'Driving license';

  @override
  String get docInsurance => 'GOSI certificate';

  @override
  String get docAccount => 'Bank statement';

  @override
  String get docSalary => 'Salary definition letter';

  @override
  String get docUpload => 'Upload';

  @override
  String get docReplace => 'Replace';

  @override
  String get errIdentity => 'Enter a valid 10-digit number.';

  @override
  String get errDocTooBig => 'File is larger than 4MB.';

  @override
  String get errAnswerAll => 'Please answer all questions.';

  @override
  String get formNext => 'Next';

  @override
  String get successTitle => 'Request received!';

  @override
  String get successReserve =>
      'Your car is reserved — our team will contact you to complete the purchase.';

  @override
  String get successFinance =>
      'Your finance request was received — a specialist will contact you shortly.';

  @override
  String get successContact =>
      'Request received — a sales consultant will call you within work hours.';

  @override
  String get successRef => 'Reference';

  @override
  String get successClose => 'Done';

  @override
  String get reserveSignInFirst => 'Sign in to complete a quick reservation.';

  @override
  String get sheetDownPayment => 'Down Payment';

  @override
  String get sheetAmountRequired => 'Amount required';

  @override
  String get offersTitle => 'Offers';

  @override
  String get offersEmpty => 'No active offers right now.';

  @override
  String get offersView => 'View offer';

  @override
  String get offersEnded => 'Ended';

  @override
  String get offersDay => 'DAY';

  @override
  String get offersHour => 'HOUR';

  @override
  String get offersMin => 'MIN';

  @override
  String get offersSec => 'SEC';

  @override
  String get offersPackages => 'Packages';

  @override
  String get offersSupportedVehicles => 'Supported vehicles';

  @override
  String get offersTerms => 'Terms & Conditions';

  @override
  String get offersApplyFinance => 'Apply for finance';

  @override
  String get offersReserve => 'Reserve this offer';

  @override
  String get offersRequest => 'Request this offer';

  @override
  String offersRate(String rate) {
    return 'Financing rate $rate';
  }

  @override
  String get offersSubmitted =>
      'Your request was received — our team will contact you shortly.';

  @override
  String get offersSubmitFailed => 'Something went wrong — please try again.';

  @override
  String get offersVehicle => 'Vehicle';

  @override
  String get offersPackage => 'Package';

  @override
  String get offersYear => 'Manufacture year';

  @override
  String get offersMeter => 'Meter reading';

  @override
  String get offersVinOptional => 'VIN (optional)';

  @override
  String get offersIncome => 'Net monthly income';

  @override
  String get offersPeriod => 'Finance period (months)';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get formFullName => 'Full name';

  @override
  String get formFirstName => 'First name';

  @override
  String get formLastName => 'Last name';

  @override
  String get formEmailOptional => 'Email (optional)';

  @override
  String get formNoteOptional => 'Notes (optional)';

  @override
  String get formCheckFields => 'Please check the required fields.';

  @override
  String get finTitle => 'Finance your car';

  @override
  String get finSubtitle =>
      'Pick a bank, set your budget, and get an instant monthly-payment estimate.';

  @override
  String get finModeMonthly => 'Monthly';

  @override
  String get finModeModel => 'By model';

  @override
  String get finModeBudget => 'By budget';

  @override
  String get finMonthlyPayment => 'MONTHLY PAYMENT';

  @override
  String get finPeriodMonths => 'PERIOD (MONTHS)';

  @override
  String get finFinalPayment => 'FINAL PAYMENT';

  @override
  String get finSar => 'SAR';

  @override
  String get finMo => 'mo';

  @override
  String get finMaxPrice => 'Max price';

  @override
  String get finRefine => 'Refine';

  @override
  String get finNoCars => 'No cars match these filters.';

  @override
  String finFromMonthly(String amount) {
    return 'From $amount / month';
  }

  @override
  String get finApply => 'Finance';

  @override
  String get finEstMonthly => 'Monthly payment';

  @override
  String get finEstAdvance => 'Down payment';

  @override
  String get finEstBalloon => 'Final payment';

  @override
  String get finEstTotal => 'Total payable';

  @override
  String get finEstFees => 'Admin fees (incl. VAT)';

  @override
  String get finBuyingAs => 'Buying as';

  @override
  String get finCommercialReg => 'Commercial register';

  @override
  String get finAdvanceOptional => 'Advance payment (optional)';

  @override
  String get finCashPrice => 'Cash price';

  @override
  String get finCalculate => 'Calculate finance';

  @override
  String get finCalcSub =>
      'Pick your car and compare every bank\'s monthly payment.';

  @override
  String get finBestOffer => 'Best offers for you';

  @override
  String get finDownPct => 'Down payment %';

  @override
  String get finBankDefault => 'Bank default';

  @override
  String get finPerMonth => 'per month';

  @override
  String get partsTitle => 'Genuine spare parts';

  @override
  String get partsSubtitle => 'Find parts compatible with your vehicle.';

  @override
  String get partsSearchHint => 'Part name or number...';

  @override
  String partsResults(int count) {
    return '$count parts';
  }

  @override
  String get partsInStockOnly => 'In stock';

  @override
  String get partsEmpty => 'No parts found — try a different search.';

  @override
  String get partsSortPriceDesc => 'Price: high → low';

  @override
  String get partsSortPriceAsc => 'Price: low → high';

  @override
  String get partsSortNo => 'Part number';

  @override
  String get partsInStock => 'IN STOCK';

  @override
  String get partsOutOfStock => 'ON ORDER';

  @override
  String get partsDetailHint =>
      'Genuine part with dealer warranty. Online payment is coming with the payment module — meanwhile you can buy this part from any Hassan Jameel branch.';

  @override
  String get protTitle => 'Protection & polishing';

  @override
  String get protSubtitle => 'Pick your car to load the available packages.';

  @override
  String get protPickToStart => 'Pick your vehicle to start';

  @override
  String get protNoPackages => 'No packages available for this model yet.';

  @override
  String get protVehicleType => 'Vehicle type';

  @override
  String get protTierSilver => 'Silver';

  @override
  String get protTierGold => 'Gold';

  @override
  String get protTierPlatinum => 'Platinum';

  @override
  String get protTierDiamond => 'Diamond';

  @override
  String get protBookTitle => 'Book this package';

  @override
  String get protBranch => 'Branch';

  @override
  String get protPickDate => 'Pick a date';

  @override
  String get protNoHours =>
      'No available hours on this day — pick another date.';

  @override
  String get protBooked =>
      'Your booking was received — our service team will contact you to confirm.';

  @override
  String get protConfirmBooking => 'Confirm booking';

  @override
  String get acGoodMorning => 'Good morning';

  @override
  String get acGoodAfternoon => 'Good afternoon';

  @override
  String get acGoodEvening => 'Good evening';

  @override
  String get acGreetingSub => 'Your vehicles are ready for your next journey.';

  @override
  String get acCarInService => 'Your car is in service';

  @override
  String get acCarReady => 'Your car is ready for pickup 🎉';

  @override
  String get acStageReceived => 'Received';

  @override
  String get acStageInProgress => 'In progress';

  @override
  String get acStageQuality => 'Quality check';

  @override
  String get acStageReady => 'Ready';

  @override
  String get acStagePayment => 'Payment';

  @override
  String get acAmountDue => 'Amount due';

  @override
  String get acSadad => 'Sadad no.';

  @override
  String get acUpcomingBooking => 'Upcoming service appointment';

  @override
  String get acCarDetails => 'Car details';

  @override
  String get acNoCarsTitle => 'Add your car and follow everything about it';

  @override
  String get acNoCarsSub =>
      'Maintenance, bookings, invoices and offers made for your car — all in one place.';

  @override
  String get acMyGarage => 'My garage';

  @override
  String get acAddCarShort => 'ADD CAR';

  @override
  String get acAddCarTitle => 'Add your car';

  @override
  String get acAddCarSub =>
      'Own a car already? Register it with its VIN. Looking for one? Browse the store.';

  @override
  String get acHaveCar => 'I own a car — register it';

  @override
  String get acNoCar => 'I don\'t have one — browse cars';

  @override
  String get acAddCarCta => 'Add my car';

  @override
  String get acAddCarDone => 'Your car was added to your garage.';

  @override
  String get acVin => 'VIN (chassis number)';

  @override
  String get acVinHelp => '17 characters — find it on the registration card';

  @override
  String get acPlateOptional => 'Plate no. (optional)';

  @override
  String get acAliasOptional => 'Car name (optional)';

  @override
  String get acDuplicateVin => 'This VIN is already in your garage.';

  @override
  String get acInvalidVin =>
      'Please complete the fields — the VIN must be 17 characters.';

  @override
  String get acUpdateMeter => 'Update odometer';

  @override
  String get acCurrentKm => 'Current reading';

  @override
  String get acInvalidReading => 'Please enter a valid reading.';

  @override
  String acLowerReading(String latest) {
    return 'The reading can\'t be lower than the last recorded one ($latest KM).';
  }

  @override
  String acLastBranchReading(String km) {
    return 'Last documented reading: $km KM';
  }

  @override
  String acNextPm(String next, String remaining) {
    return 'Next maintenance at $next KM — about $remaining KM to go';
  }

  @override
  String acPmOverdue(String next) {
    return 'Maintenance overdue — the $next KM service is due now';
  }

  @override
  String get acPmNeedsReading =>
      'Enter your odometer reading to find the right maintenance';

  @override
  String get acPmNoPlan =>
      'No maintenance plan is available for this model yet.';

  @override
  String acOdometerLine(String km, String source) {
    return 'Odometer: $km KM ($source)';
  }

  @override
  String get acSourceBranch => 'branch documented';

  @override
  String get acSourceCustomer => 'your entry';

  @override
  String get acBuyCar => 'Buy a car';

  @override
  String get acMyOrders => 'My orders';

  @override
  String get acAllServices => 'All services';

  @override
  String get acJourneys => 'Your journeys';

  @override
  String get acJourneyService => 'Service';

  @override
  String get acJourneyBooking => 'Booking';

  @override
  String get acJourneyOrder => 'Order';

  @override
  String get acJourneyFinance => 'Finance request';

  @override
  String get acActionNeeded => 'Action needed';

  @override
  String get acOrderTracking => 'Order tracking';

  @override
  String get acNoTracking => 'No tracking updates yet.';

  @override
  String get acOffersForYou => 'Offers picked for you';

  @override
  String get acTabForYou => 'For you';

  @override
  String get acVinLabel => 'VIN';

  @override
  String get acPlate => 'Plate';

  @override
  String get acModelCode => 'Model code';

  @override
  String get acLastMaintenance => 'Last maintenance';

  @override
  String get acMeter => 'Odometer';

  @override
  String get mbTitle => 'Book a service';

  @override
  String get mbService => 'Service';

  @override
  String get mbPackage => 'Maintenance package';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifClear => 'Clear all';

  @override
  String get notifEmpty => 'No notifications yet.';

  @override
  String get newsTitle => 'News';

  @override
  String get newsSubtitle => 'Latest launches, events and announcements.';

  @override
  String get newsEmpty => 'No news yet.';

  @override
  String get contactTitle => 'Contact us';

  @override
  String get contactSubtitle =>
      'Pick a branch and send us a message — our team will reach out.';

  @override
  String get contactOpenMaps => 'Open in Google Maps';

  @override
  String get contactFormTitle => 'Send a message';

  @override
  String get contactSent =>
      'Your message was received — our team will contact you.';

  @override
  String get contactSubject => 'Subject';

  @override
  String get contactMessage => 'Your message';

  @override
  String get contactBranches => 'Our branches';

  @override
  String get finReqTitle => 'Finance requests';

  @override
  String get finReqEmpty => 'No finance requests yet.';

  @override
  String get finReqReason => 'Reason';

  @override
  String get finReqTimeline => 'Follow-up log';

  @override
  String get finStageReceived => 'Received';

  @override
  String get finStageContacting => 'Contacting you';

  @override
  String get finStageSentToBank => 'Sent to bank';

  @override
  String get finStageApproved => 'Approved';

  @override
  String get finStageRejected => 'Not approved';

  @override
  String get trackTitle => 'Service tracking';

  @override
  String get trackLive => 'LIVE';

  @override
  String get trackReconnecting => 'Reconnecting…';

  @override
  String get trackEmpty =>
      'No cars in the workshop right now — when your car is checked in, you\'ll follow it live here.';

  @override
  String get acAllServicesSub =>
      'Everything Hassan Jameel offers, one tap away.';

  @override
  String get offersForMyCar => 'For my car';

  @override
  String get offersAnotherCar => 'Another car';

  @override
  String mbStepOf(int step) {
    return 'Step $step of 3';
  }

  @override
  String get mbStep1Title => 'Choose the service';

  @override
  String get mbStep1Sub => 'What does your car need?';

  @override
  String get mbStep2Title => 'Vehicle details';

  @override
  String get mbStep2Sub => 'Book for one of your cars or another vehicle.';

  @override
  String get mbStep3Title => 'Slot & contact details';

  @override
  String get mbStep3Sub => 'Pick the day and time, and confirm your details.';

  @override
  String get mbForMyCar => 'One of my cars';

  @override
  String get mbForAnotherCar => 'Another vehicle';

  @override
  String get mbVinAuto => 'filled automatically';

  @override
  String get mbNext => 'Next';

  @override
  String get mbBack => 'Back';

  @override
  String get mbBadgeSecure => 'Secure booking';

  @override
  String get mbBadgeWarranty => '12-month warranty';

  @override
  String get mbBadgeFreeCancel => 'Free cancellation';

  @override
  String get calSun => 'Sun';

  @override
  String get calMon => 'Mon';

  @override
  String get calTue => 'Tue';

  @override
  String get calWed => 'Wed';

  @override
  String get calThu => 'Thu';

  @override
  String get calFri => 'Fri';

  @override
  String get calSat => 'Sat';

  @override
  String get calAvailable => 'Available';

  @override
  String get calHoliday => 'Holiday';

  @override
  String get calUnavailable => 'Unavailable';

  @override
  String get mbSubService => 'Sub-service';

  @override
  String get protBasePrice => 'Base price';

  @override
  String get protVat => 'VAT (15%)';

  @override
  String get protTotal => 'Total price';

  @override
  String get protReservePay => 'Reserve & pay securely';

  @override
  String get protMyCars => 'My cars';

  @override
  String get payMethodTitle => 'Payment method';

  @override
  String get payTinting => 'Tinting grade';

  @override
  String get payConfirm => 'Confirm & proceed to payment';

  @override
  String get paySuccess => 'Payment confirmed — your reservation is booked. 🎉';

  @override
  String get payFailed => 'Payment was not completed — you can try again.';

  @override
  String get paySadad => 'Pay via Sadad with this number:';

  @override
  String get payGatewayTitle => 'Secure payment';

  @override
  String get payMyfatoorahTag => 'Card / Apple Pay / STC Pay';

  @override
  String get payTabbyTag => 'Split in 4 — no interest';

  @override
  String get payTamaraTag => 'Split up to 12 — sharia-compliant';

  @override
  String get homeProtForCar => 'Protection packages for your car';

  @override
  String get offersForYourCar => 'For your car';

  @override
  String get offersPickTime => 'Pick a time';

  @override
  String get profileAccount => 'Profile & Account';

  @override
  String get profileVehiclesSub => 'Your garage and car details';

  @override
  String get profileOrdersSub => 'Track your orders and services';

  @override
  String get profileFinanceSub => 'Follow your finance applications';

  @override
  String get profileFavoritesSub => 'Your saved cars';

  @override
  String get profileNotifSub => 'Your notifications inbox';

  @override
  String get profileContactSub => 'Branches and support';

  @override
  String get profilePrefs => 'Preferences';

  @override
  String get profileDarkMode => 'Dark mode';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileOn => 'On';

  @override
  String get profileOff => 'Off';

  @override
  String get profilePersonal => 'Personal data';

  @override
  String get acActiveBadge => 'ACTIVE';

  @override
  String get svcProtectionSub => 'Premium window film and body protection.';

  @override
  String get svcFinanceSub => 'Flexible plans for your next upgrade.';

  @override
  String get svcOffersSub => 'Latest vehicle and maintenance offers.';

  @override
  String get svcStoreSub => 'Order your car online in simple steps.';

  @override
  String get svcModelsSub => 'Explore every model and trim.';

  @override
  String get svcFavoritesSub => 'Vehicles you liked, in one place.';

  @override
  String get svcFinReqSub => 'Track the status of your finance requests.';

  @override
  String get svcNewsSub => 'The latest Hassan Jameel news.';

  @override
  String get svcContactSub => 'Our branches and ways to reach us.';

  @override
  String get svcTrackingSub => 'Follow your car in the workshop, live.';

  @override
  String get protPopular => 'POPULAR';

  @override
  String get protSelectPackage => 'Select Package';

  @override
  String get offersClaim => 'Claim Offer Now';

  @override
  String get protChoose => 'Select';

  @override
  String get protWhyTitle => 'Why choose our services?';

  @override
  String get protWhyUv => 'UV Protection';

  @override
  String get protWhyUvSub => 'Shields against sun rays.';

  @override
  String get protWhyWater => 'Water Repellent';

  @override
  String get protWhyWaterSub => 'Hydrophobic nano technology.';

  @override
  String get protWhyInstall => 'Expert Installation';

  @override
  String get protWhyInstallSub => 'By certified technicians.';

  @override
  String get protWhyWarranty => 'Guaranteed Quality';

  @override
  String get protWhyWarrantySub => 'Warranty on all services.';

  @override
  String get protBookNow => 'Book Appointment Now';

  @override
  String get protSelectedCar => 'Selected car';

  @override
  String get protPlate => 'Plate number';

  @override
  String get protOtherModel => 'Choose another model';

  @override
  String get contactCallNow => 'Call now';

  @override
  String get partsSortRelevance => 'Best match';

  @override
  String get jdStatus => 'Status';

  @override
  String get jdReference => 'Reference';

  @override
  String get jdDate => 'Date';

  @override
  String get jdTotal => 'Total';

  @override
  String get jdPayNow => 'Pay now';

  @override
  String get jdDetailsTitle => 'Order details';

  @override
  String get pcTitle => 'Parts Cart';

  @override
  String get pcEmpty => 'Your cart is empty';

  @override
  String get pcSummary => 'Summary';

  @override
  String get pcCoupon => 'Coupon code';

  @override
  String get pcApply => 'Apply';

  @override
  String get pcCouponInvalid => 'Invalid code';

  @override
  String get pcSubtotal => 'Subtotal';

  @override
  String get pcDiscount => 'Discount';

  @override
  String get pcVat => 'VAT (15%)';

  @override
  String get pcTotal => 'Total';

  @override
  String get pcCheckout => 'Checkout';

  @override
  String get pcContinue => 'Continue shopping';

  @override
  String get pcRemove => 'Remove';

  @override
  String get pcAddToCart => 'Add to cart';

  @override
  String get pcInCart => 'In cart';

  @override
  String get pcQty => 'Quantity';

  @override
  String get pcCheckoutTitle => 'Checkout & Payment';

  @override
  String get pcPickup => 'Branch pickup';

  @override
  String get pcPickupMethod => 'Pickup method';

  @override
  String get pcChooseBranch => 'Choose branch';

  @override
  String get pcContact => 'Contact details';

  @override
  String get pcPayMethod => 'Payment method';

  @override
  String get pcOrder => 'Order';

  @override
  String get pcPayMyfatoorah => 'Card — MyFatoorah';

  @override
  String get pcPayTabby => 'Tabby — split in 4';

  @override
  String get pcPayTamara => 'Tamara — up to 12 installments';

  @override
  String get pcPaySadad => 'Sadad';

  @override
  String get pcSadadTitle => 'Sadad number';

  @override
  String get pcSadadHint => 'Pay via Sadad using this number.';

  @override
  String get pcSuccess => 'Your order was placed successfully!';

  @override
  String get pcOrderNo => 'Order no.';

  @override
  String get pcPayFailed => 'Payment was not completed. Please try again.';

  @override
  String get pcAdded => 'Added to cart';

  @override
  String get pcViewCart => 'View cart';

  @override
  String get ucTitle => 'Trusted Used Cars';

  @override
  String get ucSubtitle =>
      'Cars listed by their owners — some inspected by Hassan Jameel for your peace of mind.';

  @override
  String get ucSellCta => 'List your car';

  @override
  String get ucEmpty => 'No cars listed right now.';

  @override
  String get ucInspected => 'Inspected by Hassan Jameel';

  @override
  String get ucPriceOnContact => 'Price on contact';

  @override
  String get ucKm => 'km';

  @override
  String get ucWhatsapp => 'Contact to buy via WhatsApp';

  @override
  String get ucCarInfo => 'Car information';

  @override
  String get ucInspectionTitle => 'Full car inspection';

  @override
  String get ucInspectionSub => 'A thorough check of every part.';

  @override
  String get ucSafety => 'Safety';

  @override
  String get ucComfort => 'Comfort';

  @override
  String get ucTech => 'Technology';

  @override
  String get ucExterior => 'Exterior';

  @override
  String get ucYear => 'Year';

  @override
  String get ucMileage => 'Mileage';

  @override
  String get ucFuel => 'Fuel';

  @override
  String get ucGearbox => 'Gearbox';

  @override
  String get ucDrive => 'Drive';

  @override
  String get ucCondition => 'Condition';

  @override
  String get ucSeats => 'Seats';

  @override
  String get ucDoors => 'Doors';

  @override
  String get ucExtColor => 'Exterior color';

  @override
  String get ucIntColor => 'Interior color';

  @override
  String get ucOrigin => 'Origin';

  @override
  String get ucLicenseDuration => 'License duration';

  @override
  String get ucNotes => 'Notes';

  @override
  String get ucAddTitle => 'Add your used car';

  @override
  String get ucStepOwner => 'Owner';

  @override
  String get ucStepCar => 'Car';

  @override
  String get ucStepSpecs => 'Specifications';

  @override
  String get ucStepLicense => 'License & notes';

  @override
  String get ucStepPhotos => 'Photos';

  @override
  String get ucStepReview => 'Review';

  @override
  String get ucBrand => 'Brand';

  @override
  String get ucCarName => 'Car name';

  @override
  String get ucModelName => 'Model / trim';

  @override
  String get ucBodyType => 'Body type';

  @override
  String get ucPrice => 'Price (optional)';

  @override
  String get ucChassis => 'Chassis number';

  @override
  String get ucLicenseNo => 'Plate / license number';

  @override
  String get ucLicenseExpiry => 'License expiry';

  @override
  String get ucReqInspection => 'Request a Hassan Jameel inspection';

  @override
  String get ucAddPhotos => 'Add car photos';

  @override
  String get ucSubmit => 'Submit';

  @override
  String get ucSubmitted =>
      'Request received! We will review the details and contact you on approval.';

  @override
  String get trkHubTitle => 'Order tracking';

  @override
  String get trkAll => 'All';

  @override
  String get trkKindMaintenance => 'Maintenance';

  @override
  String get trkKindProtection => 'Protection & shading';

  @override
  String get trkKindOrders => 'My orders';

  @override
  String get trkHubEmpty => 'Nothing to track yet.';

  @override
  String get mbuyType => 'Purchase type';

  @override
  String get mbuyOnline => 'Online';

  @override
  String get mbuyOrder => 'Purchase order';

  @override
  String get mbuyFastReserve => 'Fast reserve';

  @override
  String get mbuyCash => 'Cash';

  @override
  String get mbuyDelivery => 'Delivery method';

  @override
  String get mbuyBranch => 'Branch pickup';

  @override
  String get mbuyAddress => 'Deliver to address';

  @override
  String get mbuyAddressHint => 'Write the delivery address';

  @override
  String get mbuySwipe => 'Swipe to complete';

  @override
  String get mbuySelect => 'Select...';

  @override
  String get onboardingHello => 'Hello';

  @override
  String get modelsAvailableTrims => 'Available trims';

  @override
  String get modelsChooseTrim => 'Choose trim';

  @override
  String get modelsChosen => 'Selected';

  @override
  String get modelsDiffsOnly => 'Show differences only';

  @override
  String get modelsCompareHint => 'Pick two trims to compare side by side';

  @override
  String get modelsColorsTitle => 'Available colors';

  @override
  String get modelsSpecsFor => 'Trim specifications';

  @override
  String get pfTitle => 'My account';

  @override
  String get pfMyData => 'My data';

  @override
  String get pfMyCars => 'My cars';

  @override
  String get pfMyOrders => 'My orders';

  @override
  String get pfMyBookings => 'My bookings';

  @override
  String get pfFinanceRequests => 'Finance requests';

  @override
  String get pfFavorites => 'Favorites';

  @override
  String get pfNotifications => 'Notifications';

  @override
  String get pfContactData => 'Contact details';

  @override
  String get pfPassword => 'Password';

  @override
  String get pfDeleteAccount => 'Delete account';

  @override
  String get pfSave => 'Save changes';

  @override
  String get pfSaved => 'Saved successfully';

  @override
  String get pfSaveFailed => 'Some data could not be saved';

  @override
  String get pfNameAr => 'Name (Arabic)';

  @override
  String get pfNameEn => 'Name (English)';

  @override
  String get pfFirstName => 'First name';

  @override
  String get pfMiddleName => 'Middle name';

  @override
  String get pfLastName => 'Last name';

  @override
  String get pfGender => 'Gender';

  @override
  String get pfCountry => 'Country';

  @override
  String get pfCity => 'City';

  @override
  String get pfAddress => 'Address';

  @override
  String get pfIdentity => 'Identity number';

  @override
  String get pfCr => 'Commercial registration';

  @override
  String get pfAccountType => 'Account type';

  @override
  String get pfPhone => 'Phone number';

  @override
  String get pfEmail => 'Email';

  @override
  String get pfPhoneExists => 'Phone number already in use';

  @override
  String get pfEmailExists => 'Email already in use';

  @override
  String get pfIdentityExists => 'Identity number already in use';

  @override
  String get pfOldPassword => 'Current password';

  @override
  String get pfNewPassword => 'New password';

  @override
  String get pfConfirmPassword => 'Confirm password';

  @override
  String get pfPasswordMismatch => 'Passwords do not match';

  @override
  String get pfPasswordShort => 'At least 6 characters';

  @override
  String get pfWrongOldPassword => 'Current password is incorrect';

  @override
  String get pfChangePassword => 'Change password';

  @override
  String get pfDeleteWarning =>
      'Your account will be deactivated and your data hidden from the app. This cannot be undone from the app.';

  @override
  String get pfDeleteConfirmHint => 'Type \"DELETE\" to confirm';

  @override
  String get pfDeleteWord => 'DELETE';

  @override
  String get pfSignedInAs => 'Signed in as';

  @override
  String get pfGuest => 'Guest';

  @override
  String get pfSignIn => 'Sign in';

  @override
  String get pfNoNotifications => 'No notifications yet';

  @override
  String get pfNoFavorites => 'No favorites yet';

  @override
  String get cmpTitle => 'Complaints';

  @override
  String get cmpSubmit => 'Submit a complaint';

  @override
  String get cmpSubmitSub =>
      'Tell us what happened and our team will follow up step by step';

  @override
  String get cmpTrack => 'Track complaints';

  @override
  String get cmpTrackSub =>
      'Follow your complaints and our team\'s replies step by step';

  @override
  String get cmpType => 'Complaint type';

  @override
  String get cmpTypeSales => 'Sales';

  @override
  String get cmpTypeParts => 'Spare parts';

  @override
  String get cmpTypeMaintenance => 'Maintenance';

  @override
  String get cmpTypeOther => 'Other';

  @override
  String get cmpName => 'Name';

  @override
  String get cmpPhone => 'Phone';

  @override
  String get cmpEmail => 'Email (optional)';

  @override
  String get cmpSubject => 'Subject (optional)';

  @override
  String get cmpBody => 'Complaint details';

  @override
  String get cmpBodyHint => 'Tell us exactly what happened…';

  @override
  String get cmpAttach => 'Attached photos (optional)';

  @override
  String get cmpAttachHint => 'Up to 6 photos (max 4 MB each)';

  @override
  String get cmpConsent =>
      'I agree to the privacy policy and processing of my personal data';

  @override
  String get cmpSend => 'Submit complaint';

  @override
  String get cmpSent => 'Your complaint was received';

  @override
  String get cmpRef => 'Complaint number';

  @override
  String get cmpStageReceived => 'Complaint received';

  @override
  String get cmpStageUpdated => 'Update / reply';

  @override
  String get cmpStageSolved => 'Solved';

  @override
  String get cmpStatusNew => 'Received';

  @override
  String get cmpStatusUpdated => 'New reply';

  @override
  String get cmpStatusSolved => 'Solved';

  @override
  String get cmpConversation => 'Conversation';

  @override
  String get cmpYou => 'You';

  @override
  String get cmpStaff => 'Customer care team';

  @override
  String get cmpReplyHint => 'Write your reply…';

  @override
  String get cmpReplySend => 'Send reply';

  @override
  String get cmpEmpty => 'No complaints yet';

  @override
  String get cmpBodyText => 'Complaint text';

  @override
  String get finReqSub => 'Own your car with financing offers you can\'t miss';

  @override
  String get finAbsher => 'Autofill from Absher';

  @override
  String get finAbsherOtp => 'Verification code';

  @override
  String get finAbsherId => 'Identity number';

  @override
  String get finAbsherMobile => 'Mobile (5xxxxxxxx)';

  @override
  String get finAbsherBirth => 'Date of birth';

  @override
  String get finAbsherSend => 'Send verification code';

  @override
  String get finAbsherConfirm => 'Confirm';

  @override
  String get finAbsherFilled => 'Details filled from Absher';

  @override
  String get finDocs => 'Required documents';

  @override
  String get finDocsHint =>
      'Optional for now — attach them to speed up your request, or our team will collect them';

  @override
  String get finWorkSector => 'Employer type';

  @override
  String get finGov => 'Governmental';

  @override
  String get finPrivate => 'Private sector';

  @override
  String get finIdDoc => 'National ID';

  @override
  String get finLicenseDoc => 'Driving license';

  @override
  String get finSalaryDoc => 'Salary letter';

  @override
  String get finInsuranceDoc => 'GOSI printout';

  @override
  String get finStatementDoc => 'Bank statement';

  @override
  String get finUpload => 'Upload';

  @override
  String get finUploaded => 'Attached';

  @override
  String get finPickFile => 'Choose a file (image or PDF)';

  @override
  String get finFileTooBig => 'Max 4 MB';

  @override
  String get finIncome => 'Net monthly income';

  @override
  String get finFirstPayOptional => 'Down payment (optional)';

  @override
  String get finLastPay => 'Final payment';

  @override
  String get finMonthly => 'Monthly installment';

  @override
  String get finFinalPrice => 'Final price';

  @override
  String get finPeriodTitle => 'Finance period';

  @override
  String get finMonths => 'months';

  @override
  String get finNotes => 'Notes';

  @override
  String get finFullName => 'Full name';

  @override
  String get finSendReq => 'Send request';

  @override
  String get finReqSent => 'Your request was received';

  @override
  String get finReqRef => 'Request number';

  @override
  String get finTrackCta => 'Track request';

  @override
  String get finBankRate => 'Financing entity';

  @override
  String get finIncomeRequired => 'Enter your net income';

  @override
  String get trkKindFinance => 'Finance';

  @override
  String get acJobCard => 'Job card';

  @override
  String get acTabMyCars => 'My cars';

  @override
  String get acStoreToyota => 'Toyota Store';

  @override
  String get acStoreLexus => 'Lexus Store';

  @override
  String get acKm => 'km';

  @override
  String get acQuickTitle => 'Quick services';

  @override
  String get cpnExclusive => 'Exclusive offer';

  @override
  String get cpnCopied => 'Code copied';

  @override
  String get cpnRemove => 'Remove';

  @override
  String get cpnCouponDiscount => 'Coupon discount';

  @override
  String get svcPartsSub => 'Genuine parts for your car — branch pickup';

  @override
  String get mhTitle => 'Maintenance services';

  @override
  String get mhHeroBadge => 'Maintenance Center';

  @override
  String get mhHeroTitle => 'Book your maintenance';

  @override
  String get mhHeroAccent => 'in 10 seconds';

  @override
  String get mhHeroSub =>
      'Certified maintenance center with 60+ years of experience. Original parts and factory-certified technicians.';

  @override
  String get mhBadgeCertified => 'Officially certified';

  @override
  String get mhBadgeSaso => 'SASO certified';

  @override
  String get mhReserveNow => 'Reserve now';

  @override
  String get mhPeriodic => 'Periodic schedule';

  @override
  String get mhYears => 'Years of experience';

  @override
  String get mhCars => 'Cars served';

  @override
  String get mhSatisfaction => 'Satisfaction';

  @override
  String get mhBranches => 'Branches';

  @override
  String get mhJourney => 'Your maintenance journey';

  @override
  String get mhJourneySub => 'Four simple steps from booking to handover.';

  @override
  String get mhStep1 => 'Book appointment';

  @override
  String get mhStep1Sub => 'Choose the service and time that suits you';

  @override
  String get mhStep2 => 'Car inspection';

  @override
  String get mhStep2Sub => 'Our experts perform a precise comprehensive check';

  @override
  String get mhStep3 => 'Execution';

  @override
  String get mhStep3Sub =>
      'Maintenance completed with the highest quality standards';

  @override
  String get mhStep4 => 'Delivery';

  @override
  String get mhStep4Sub => 'Receive your car ready and in best condition';

  @override
  String get mhOffers => 'Maintenance offers';

  @override
  String get mhWhyTitle => 'Why choose Hassan Jameel?';

  @override
  String get mhWhySub => 'Numbers and facts that speak for themselves.';

  @override
  String get mhFeatures => 'Features';

  @override
  String get mhUs => 'Us';

  @override
  String get mhOthers => 'Others';

  @override
  String get mhRowParts => '100% original parts';

  @override
  String get mhRowDiag => 'Factory-certified diagnostics';

  @override
  String get mhRowTeam => 'Specialized team';

  @override
  String get mhRowReport => 'Digital technical report with photos';

  @override
  String get mhRowTech => 'Factory-certified technicians';

  @override
  String get mhFeedback => 'Guest feedback';

  @override
  String get mhVerified => 'Verified';

  @override
  String get mhPeriodicTitle => 'Periodic maintenance schedule';

  @override
  String get mhPeriodicSub => 'Pick a mileage to see its scheduled tasks.';

  @override
  String get mhPeriodicEmpty => 'No periodic data available.';

  @override
  String get mhImportant => 'Important';

  @override
  String get mhReady => 'Ready to book?';

  @override
  String get mhReadySub =>
      'Reserve your slot in seconds and drive away with confidence.';

  @override
  String get mhBookService => 'Book a service';

  @override
  String get mhWhatsApp => 'Talk on WhatsApp';

  @override
  String get alNickname => 'Nickname';

  @override
  String get alRename => 'Rename';

  @override
  String get alSaved => 'Name saved';

  @override
  String get contactPopTitle => 'Customer service';

  @override
  String get contactPopOnline => 'Online now';

  @override
  String get contactPopWhatsApp => 'WhatsApp chat';

  @override
  String get contactPopCall => 'Call us';
}
