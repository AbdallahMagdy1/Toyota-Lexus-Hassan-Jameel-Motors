// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'حسن جميل';

  @override
  String get onboardingGetStarted => 'ابدأ الآن';

  @override
  String get onboardingSignIn => 'تسجيل الدخول';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingTerms => 'بالمتابعة، أنت توافق على شروط الخدمة';

  @override
  String get authWelcomeBack => 'مرحباً بعودتك';

  @override
  String get authLoginSubtitle => 'سجّل الدخول إلى حسابك';

  @override
  String get authEmailOrPhone => 'البريد أو الجوال أو الهوية';

  @override
  String get authEmailOrPhoneHint =>
      'you@example.com / 05xxxxxxxx / 1xxxxxxxxx';

  @override
  String get authContinue => 'متابعة';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get authSignIn => 'تسجيل الدخول';

  @override
  String get authOr => 'أو';

  @override
  String get authContinueAsGuest => 'المتابعة كزائر';

  @override
  String get authNoAccount => 'ليس لديك حساب؟';

  @override
  String get authSignUp => 'إنشاء حساب';

  @override
  String get authInvalidAccess =>
      'أدخل بريداً إلكترونياً أو رقم جوال أو رقم هوية صحيح.';

  @override
  String get authRequiredField => 'هذا الحقل مطلوب';

  @override
  String get authInvalidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get authInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get authOtpTitle => 'رمز التحقق';

  @override
  String get authOtpSentTo => 'أرسلنا رمز التحقق إلى';

  @override
  String get authOtpInvalid => 'رمز التحقق غير صحيح.';

  @override
  String get otpVerifiedTitle => 'تم التحقق بنجاح';

  @override
  String otpValidFor(String time) {
    return 'الرمز صالح لمدة $time';
  }

  @override
  String get otpExpired => 'انتهت صلاحية الرمز — اطلب رمزًا جديدًا.';

  @override
  String get otpIncorrectTitle => 'الرمز غير صحيح';

  @override
  String get otpIncorrectHint => 'تحقق من الرمز واضغط للمحاولة مرة أخرى.';

  @override
  String get authOtpResend => 'إعادة إرسال الرمز';

  @override
  String get authBack => 'رجوع';

  @override
  String authDevOtpHint(String code) {
    return 'رمز التطوير: $code';
  }

  @override
  String get absherTitle => 'إنشاء حساب عبر أبشر';

  @override
  String get absherStep1 => 'خطوة 1 من 2 — إكمال التحقق عبر أبشر';

  @override
  String get absherStep2 => 'خطوة 2 من 2 — تأكيد رمز أبشر';

  @override
  String get absherLanguage => 'اللغة';

  @override
  String get absherArabic => 'العربية';

  @override
  String get absherEnglish => 'الإنجليزية';

  @override
  String get absherIdentity => 'رقم الهوية';

  @override
  String get absherMobile => 'رقم الجوال';

  @override
  String get absherBirthdate => 'تاريخ الميلاد';

  @override
  String get absherBirthdateHint => '1995-05';

  @override
  String get absherRegister => 'تسجيل';

  @override
  String get absherOtpSent => 'أرسلنا رمز التحقق عبر أبشر إلى جوالك المسجّل.';

  @override
  String get absherConfirm => 'تأكيد الرمز';

  @override
  String get absherInvalidIdentity => 'أدخل رقم هوية صحيح.';

  @override
  String get absherInvalidMobile =>
      'رقم الجوال يجب أن يكون 9 أرقام (مثال: 5xxxxxxxx).';

  @override
  String get absherInvalidBirthdate =>
      'تاريخ الميلاد بصيغة YYYY-MM (مثال: 1995-05).';

  @override
  String get absherFailed => 'تعذّر إكمال التسجيل عبر أبشر.';

  @override
  String get absherOtpInvalid => 'رمز التحقق غير صحيح أو منتهي.';

  @override
  String get absherSessionExpired => 'انتهت الجلسة، أعد المحاولة.';

  @override
  String get absherHaveAccount => 'عندي حساب — تسجيل دخول';

  @override
  String get authRegisteredNotice =>
      'تم إنشاء الحساب عبر أبشر — سجّل الدخول برقم جوالك.';

  @override
  String get authNotFoundNotice =>
      'لم نجد حساباً بهذه البيانات — أنشئ حساباً جديداً.';

  @override
  String get forgotTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotSubtitle => 'سنرسل رمز التحقق إلى جوالك';

  @override
  String get forgotPhone => 'رقم الجوال';

  @override
  String get forgotSendCode => 'إرسال الرمز';

  @override
  String get forgotSendFailed => 'تعذّر إرسال الرمز. تحقق من الرقم.';

  @override
  String get forgotNewPassword => 'كلمة المرور الجديدة';

  @override
  String get forgotConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get forgotSave => 'حفظ كلمة المرور';

  @override
  String get forgotFailed => 'تعذّر تحديث كلمة المرور.';

  @override
  String get forgotDoneNotice => 'تم تحديث كلمة المرور — سجّل الدخول.';

  @override
  String get authPasswordTooShort => 'كلمة المرور يجب ألا تقل عن 6 أحرف';

  @override
  String get authPasswordsDontMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get authInvalidPhone => 'أدخل رقم جوال سعودي صحيح (05xxxxxxxx)';

  @override
  String get authNetworkError => 'تعذّر الوصول إلى الخادم. تحقق من اتصالك.';

  @override
  String get authGenericError => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get homeWelcome => 'مرحباً';

  @override
  String get homeGuest => 'زائر';

  @override
  String get homeOnlineStore => 'المتجر الإلكتروني';

  @override
  String get homeOnlineStoreSub => 'احجز سيارتك أونلاين مع توصيل للمنزل';

  @override
  String get homeViewAll => 'عرض الكل';

  @override
  String get homeMeetTheModels => 'تعرف على الموديلات';

  @override
  String get homeAll => 'الكل';

  @override
  String get homeProtection => 'الحماية والتظليل';

  @override
  String get homeProtectionDesc =>
      'حافظ على لمعان سيارتك مع خدمات التظليل والحماية المتقدمة.';

  @override
  String get homeSelectCar => 'اختر السيارة';

  @override
  String get homeSelectModel => 'اختر الموديل';

  @override
  String get homeServiceType => 'نوع الخدمة';

  @override
  String get homeCheckAvailability => 'تحقق من التوفر';

  @override
  String get homeSpareParts => 'قطع الغيار الأصلية';

  @override
  String get homeSparePartsSub => 'اعثر على القطع المتوافقة مع سيارتك';

  @override
  String get homeAddToCart => 'أضف للسلة';

  @override
  String get homeUsedCars => 'سيارات مستعملة موثوقة';

  @override
  String get homeUsedCarsSub => 'بعضها مفحوص من حسن جميل';

  @override
  String get homeUsedCarsEmpty =>
      'لا توجد سيارات معروضة بعد — كن أول من يعرض سيارته.';

  @override
  String get homeListYourCar => 'اعرض سيارتك';

  @override
  String get homeInspected => 'مفحوصة من حسن جميل';

  @override
  String get homeMaintenanceSpecials => 'عروض الصيانة';

  @override
  String get homeMaintenanceSpecialsSub => 'حافظ على سيارتك بأفضل حال';

  @override
  String get homeVehicleOffers => 'اقتنِ سيارتك بعرض مميز';

  @override
  String get homeBuyNow => 'اشترِ الآن';

  @override
  String get homeBook => 'احجز';

  @override
  String get homeViewOffer => 'شاهد العرض';

  @override
  String get homeReserveNow => 'احجز الآن';

  @override
  String homeDaysLeft(int count) {
    return 'متبقي $count يوم';
  }

  @override
  String get homeFrom => 'يبدأ من';

  @override
  String get currency => 'ر.س';

  @override
  String get homeContactForPrice => 'تواصل لمعرفة السعر';

  @override
  String get homeComingSoonFeature => 'قريباً';

  @override
  String get homeErrorRetry => 'تعذّر تحميل الصفحة. اضغط لإعادة المحاولة.';

  @override
  String get stateErrorTitle => 'حدث خطأ ما';

  @override
  String get stateErrorBody => 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.';

  @override
  String get stateRetry => 'إعادة المحاولة';

  @override
  String get homeSignOut => 'تسجيل الخروج';

  @override
  String get homeThemeMode => 'الوضع الداكن';

  @override
  String get settingsLanguage => 'English';

  @override
  String get brandToyota => 'تويوتا';

  @override
  String get brandLexus => 'لكزس';

  @override
  String storeModelsCount(int count) {
    return '$count موديلاً متاحاً للحجز الفوري';
  }

  @override
  String get storeFilters => 'التصفية';

  @override
  String get storeSearch => 'ابحث عن موديل…';

  @override
  String osHeroGreeting(String name) {
    return 'مرحبًا $name 👋';
  }

  @override
  String get osHeroGreetingGuest => 'مرحبًا بك 👋';

  @override
  String get osHeroTitle => 'اعثر على سيارتك المثالية';

  @override
  String get storePriceUpTo => 'السعر حتى';

  @override
  String get storeCategories => 'الفئات';

  @override
  String get storeColor => 'اللون';

  @override
  String get storeAllColors => 'كل الألوان';

  @override
  String get storeClearFilters => 'مسح كل الفلاتر';

  @override
  String get storeApplyFilters => 'عرض النتائج';

  @override
  String get storeNoResults => 'لا توجد سيارات مطابقة للفلاتر.';

  @override
  String get storeAvailableOnline => 'متاحة أونلاين';

  @override
  String get storeFrom => 'يبدأ من';

  @override
  String get storeVatNote =>
      'شامل ضريبة القيمة المضافة 15% واللوحات ورسوم التسجيل';

  @override
  String get storeAddToCart => 'أضف للسلة';

  @override
  String get cartAdded => 'تمت الإضافة إلى السلة';

  @override
  String get cartTitle => 'سلتي';

  @override
  String get cartMakePayment => 'إتمام الدفع';

  @override
  String get cartEmpty => 'سلتك فارغة — تصفح المتجر الإلكتروني.';

  @override
  String get cartBrowse => 'تصفح السيارات';

  @override
  String get cartTabVehicles => 'سلة المركبات';

  @override
  String get cartTabParts => 'سلة قطع الغيار';

  @override
  String get favTitle => 'المفضلة';

  @override
  String get favEmpty => 'لا توجد مفضلات بعد — اضغط على القلب في أي سيارة.';

  @override
  String get profileTitle => 'حسابي';

  @override
  String get drawerSettings => 'الإعدادات';

  @override
  String get sheetPickColor => 'اختر اللون';

  @override
  String get sheetFinancingOptions => 'خيارات التمويل';

  @override
  String get sheetPickBank => 'اختر البنك';

  @override
  String sheetBanksCount(int count) {
    return '$count بنوك توفر تمويلاً لهذه السيارة.';
  }

  @override
  String get bankMonthly => 'شهرياً';

  @override
  String get bankDown => 'الدفعة الأولى';

  @override
  String get bankAdminFees => 'رسوم إدارية';

  @override
  String get bankTotal => 'الإجمالي';

  @override
  String bankMonths(int count) {
    return '$count شهراً';
  }

  @override
  String get sheetHowToBuy => 'كيف تود شراء هذه السيارة؟';

  @override
  String get sheetSelectYourCar => 'اختر سيارتك';

  @override
  String get sheetLearnMore => 'اعرف المزيد';

  @override
  String get sheetNext => 'التالي';

  @override
  String get ghHeroTitle => 'سيارتك الجديدة تبدأ من هنا';

  @override
  String get ghHeroSubtitle => 'اكتشف سيارات تويوتا ولكزس وعروض التمويل';

  @override
  String get ghBrowseCars => 'استعرض السيارات';

  @override
  String get ghCalcFinance => 'احسب التمويل';

  @override
  String get ghQuickActions => 'إجراءات سريعة';

  @override
  String get ghBookMaintenance => 'حجز صيانة';

  @override
  String get ghCarOffers => 'عروض السيارات';

  @override
  String get ghMaintOffers => 'عروض الصيانة';

  @override
  String get ghSpareParts => 'قطع الغيار';

  @override
  String get ghBrowseByType => 'استعرض السيارات';

  @override
  String ghCarsCount(int count) {
    return '$count سيارة';
  }

  @override
  String get ghFinanceOffers => 'عروض التمويل';

  @override
  String get ghServices => 'خدمات حسن جميل';

  @override
  String get ghSvcMaintenance => 'الصيانة';

  @override
  String get ghSvcProtection => 'الحماية والتظليل';

  @override
  String get ghSvcParts => 'قطع الغيار';

  @override
  String get ghSvcFinance => 'التمويل';

  @override
  String get ghLoginBenefit =>
      'سجّل دخولك لمتابعة سيارتك، حجوزاتك، فواتيرك وعروضك الخاصة.';

  @override
  String get ghLoginRequired =>
      'هذه الخدمة تحتاج تسجيل الدخول — سجّل لمتابعة حجوزاتك وطلباتك.';

  @override
  String get tabOverview => 'نظرة عامة';

  @override
  String get tabGallery => 'المعرض';

  @override
  String get tabSpecs => 'المواصفات';

  @override
  String get tabFeatures => 'المميزات';

  @override
  String get tabComparison => 'المقارنة';

  @override
  String get modelsPrice => 'السعر';

  @override
  String get modelsTrims => 'الفئات والأسعار';

  @override
  String get modelsNoData => 'لا توجد بيانات لهذا الموديل.';

  @override
  String get specYear => 'السنة';

  @override
  String get specHp => 'حصان';

  @override
  String get specFuel => 'الوقود';

  @override
  String get specSeats => 'المقاعد';

  @override
  String get specCylinders => 'الأسطوانات';

  @override
  String get methodReserveTitle => 'حجز سريع';

  @override
  String get methodReserveBadge => 'الاختيار الأفضل';

  @override
  String get methodSignIn => 'تسجيل دخول';

  @override
  String get methodRefundable => 'مستردة';

  @override
  String get methodFree => 'مجاناً';

  @override
  String get methodReserveB1 => 'أسرع طريقة لاستلام سيارتك';

  @override
  String get methodReserveB2 => 'تثبيت السعر حتى استكمال الشراء';

  @override
  String get methodReserveB3 => 'مدة حجز المركبة يوم عمل واحد';

  @override
  String get methodFinanceTitle => 'قدم طلب تمويل';

  @override
  String get methodFinanceB1 => 'احصل على موافقة مبدئية خلال دقائق';

  @override
  String get methodFinanceB2 => 'خيارات متنوعة تناسب دخلك';

  @override
  String get methodFinanceB3 => 'فريق تمويل متخصص يساعدك خطوة بخطوة';

  @override
  String get methodContactTitle => 'طلب تواصل';

  @override
  String get methodContactB1 =>
      'يتواصل معك مستشار مبيعات خلال دقائق (داخل أوقات العمل)';

  @override
  String get methodContactB2 => 'يساعدك بمعرفة تفاصيل السيارة وأنسب العروض';

  @override
  String get sheetTerms => 'لقد قرأت الشروط والأحكام وسياسة الموقع وأوافق.';

  @override
  String get sheetContinue => 'متابعة';

  @override
  String get formApplicant => 'نوع مقدم الطلب';

  @override
  String get formName => 'الاسم الكامل';

  @override
  String get formPhone => 'رقم الجوال';

  @override
  String get formEmail => 'البريد الإلكتروني';

  @override
  String get formCity => 'المدينة';

  @override
  String get formIdentity => 'رقم الهوية';

  @override
  String get formCN => 'السجل التجاري';

  @override
  String get formQuantity => 'الكمية';

  @override
  String get formNote => 'ملاحظة (اختياري)';

  @override
  String get formSend => 'إرسال الطلب';

  @override
  String get formNameAr => 'الاسم الكامل (عربي)';

  @override
  String get formNameEn => 'الاسم الكامل (إنجليزي)';

  @override
  String get formGender => 'الجنس';

  @override
  String get genderMale => 'ذكر';

  @override
  String get genderFemale => 'أنثى';

  @override
  String get formWhatsapp => 'استلام التحديثات عبر واتساب';

  @override
  String get stepPersonal => 'البيانات الشخصية';

  @override
  String get stepWork => 'العمل';

  @override
  String get stepDocuments => 'المستندات';

  @override
  String get formJob => 'المسمى الوظيفي';

  @override
  String get formIncome => 'الدخل الشهري';

  @override
  String get formFirstPayment => 'الدفعة الأولى (اختياري)';

  @override
  String get formMonthlyAmount => 'القسط الشهري المفضل (اختياري)';

  @override
  String get formPeriod => 'مدة التمويل (شهور)';

  @override
  String get formWorkType => 'قطاع العمل';

  @override
  String get workPrivate => 'خاص';

  @override
  String get workGovernmental => 'حكومي';

  @override
  String get formSalaryBank => 'بنك الراتب';

  @override
  String get financeQ1 => 'هل أنت مسجل في سمة؟';

  @override
  String get financeQ2 => 'هل لديك مخالفات مرورية؟';

  @override
  String get financeQ3 => 'هل لديك قرض عقاري؟';

  @override
  String get financeQ4 => 'هل لديك التزامات أخرى؟';

  @override
  String get answerYes => 'نعم';

  @override
  String get answerNo => 'لا';

  @override
  String get formViolationsAmount => 'قيمة المخالفات';

  @override
  String get formObligationsAmount => 'قيمة الالتزامات الشهرية';

  @override
  String get formFinanceBank => 'جهة التمويل';

  @override
  String get docIdentity => 'الهوية الوطنية / السجل';

  @override
  String get docLicense => 'رخصة القيادة';

  @override
  String get docInsurance => 'شهادة التأمينات';

  @override
  String get docAccount => 'كشف حساب بنكي';

  @override
  String get docSalary => 'خطاب تعريف بالراتب';

  @override
  String get docUpload => 'رفع';

  @override
  String get docReplace => 'استبدال';

  @override
  String get errIdentity => 'أدخل رقماً صحيحاً من 10 أرقام.';

  @override
  String get errDocTooBig => 'حجم الملف أكبر من 4MB.';

  @override
  String get errAnswerAll => 'فضلاً أجب على جميع الأسئلة.';

  @override
  String get formNext => 'التالي';

  @override
  String get successTitle => 'تم استلام طلبك!';

  @override
  String get successReserve =>
      'تم حجز سيارتك — سيتواصل معك فريقنا لإكمال الشراء.';

  @override
  String get successFinance =>
      'تم استلام طلب التمويل — سيتواصل معك مختص قريباً.';

  @override
  String get successContact =>
      'تم استلام الطلب — سيتصل بك مستشار المبيعات خلال أوقات العمل.';

  @override
  String get successRef => 'رقم المرجع';

  @override
  String get successClose => 'تم';

  @override
  String get reserveSignInFirst => 'سجّل الدخول لإكمال الحجز السريع.';

  @override
  String get sheetDownPayment => 'الدفعة الأولى';

  @override
  String get sheetAmountRequired => 'المبلغ المطلوب';

  @override
  String get offersTitle => 'العروض';

  @override
  String get offersEmpty => 'لا توجد عروض نشطة حاليًا.';

  @override
  String get offersView => 'عرض التفاصيل';

  @override
  String get offersEnded => 'انتهى';

  @override
  String get offersDay => 'يوم';

  @override
  String get offersHour => 'ساعة';

  @override
  String get offersMin => 'دقيقة';

  @override
  String get offersSec => 'ثانية';

  @override
  String get offersPackages => 'الباقات';

  @override
  String get offersSupportedVehicles => 'السيارات المشمولة';

  @override
  String get offersTerms => 'الشروط والأحكام';

  @override
  String get offersApplyFinance => 'قدّم طلب تمويل';

  @override
  String get offersReserve => 'احجز العرض';

  @override
  String get offersRequest => 'اطلب العرض';

  @override
  String offersRate(String rate) {
    return 'نسبة التمويل $rate';
  }

  @override
  String get offersSubmitted => 'تم استلام طلبك — سيتواصل معك فريقنا قريبًا.';

  @override
  String get offersSubmitFailed => 'حدث خطأ ما — حاول مرة أخرى.';

  @override
  String get offersVehicle => 'السيارة';

  @override
  String get offersPackage => 'الباقة';

  @override
  String get offersYear => 'سنة الصنع';

  @override
  String get offersMeter => 'قراءة العداد';

  @override
  String get offersVinOptional => 'رقم الهيكل (اختياري)';

  @override
  String get offersIncome => 'صافي الدخل الشهري';

  @override
  String get offersPeriod => 'مدة التمويل (أشهر)';

  @override
  String get commonDone => 'تم';

  @override
  String get commonSubmit => 'إرسال';

  @override
  String get formFullName => 'الاسم الكامل';

  @override
  String get formFirstName => 'الاسم الأول';

  @override
  String get formLastName => 'اسم العائلة';

  @override
  String get formEmailOptional => 'البريد الإلكتروني (اختياري)';

  @override
  String get formNoteOptional => 'ملاحظات (اختياري)';

  @override
  String get formCheckFields => 'فضلًا تحقق من الحقول المطلوبة.';

  @override
  String get finTitle => 'موّل سيارتك';

  @override
  String get finSubtitle =>
      'اختر البنك وحدّد ميزانيتك واحصل على قسط شهري فوري.';

  @override
  String get finModeMonthly => 'بالقسط';

  @override
  String get finModeModel => 'بالموديل';

  @override
  String get finModeBudget => 'بالميزانية';

  @override
  String get finMonthlyPayment => 'القسط الشهري';

  @override
  String get finPeriodMonths => 'المدة (أشهر)';

  @override
  String get finFinalPayment => 'الدفعة الأخيرة';

  @override
  String get finSar => 'ر.س';

  @override
  String get finMo => 'شهر';

  @override
  String get finMaxPrice => 'أقصى سعر';

  @override
  String get finRefine => 'تصفية';

  @override
  String get finNoCars => 'لا توجد سيارات مطابقة للفلاتر.';

  @override
  String finFromMonthly(String amount) {
    return 'يبدأ من $amount / شهريًا';
  }

  @override
  String get finApply => 'موّلها';

  @override
  String get finEstMonthly => 'القسط الشهري';

  @override
  String get finEstAdvance => 'الدفعة الأولى';

  @override
  String get finEstBalloon => 'الدفعة الأخيرة';

  @override
  String get finEstTotal => 'الإجمالي';

  @override
  String get finEstFees => 'رسوم إدارية (شاملة الضريبة)';

  @override
  String get finBuyingAs => 'الشراء بصفة';

  @override
  String get finCommercialReg => 'السجل التجاري';

  @override
  String get finAdvanceOptional => 'الدفعة الأولى (اختياري)';

  @override
  String get finCashPrice => 'سعر الكاش';

  @override
  String get finCalculate => 'احسب التمويل';

  @override
  String get finCalcSub => 'اختر سيارتك وقارن القسط الشهري بين كل البنوك.';

  @override
  String get finBestOffer => 'أفضل العروض لك';

  @override
  String get finDownPct => 'نسبة الدفعة الأولى';

  @override
  String get finBankDefault => 'حسب البنك';

  @override
  String get finPerMonth => 'شهريًا';

  @override
  String get partsTitle => 'قطع غيار أصلية';

  @override
  String get partsSubtitle => 'ابحث عن القطع المتوافقة مع سيارتك.';

  @override
  String get partsSearchHint => 'اسم القطعة أو رقمها...';

  @override
  String partsResults(int count) {
    return '$count قطعة';
  }

  @override
  String get partsInStockOnly => 'متوفر فقط';

  @override
  String get partsEmpty => 'لا توجد قطع — جرّب بحثًا مختلفًا.';

  @override
  String get partsSortPriceDesc => 'السعر: من الأعلى للأقل';

  @override
  String get partsSortPriceAsc => 'السعر: من الأقل للأعلى';

  @override
  String get partsSortNo => 'رقم القطعة';

  @override
  String get partsInStock => 'متوفر';

  @override
  String get partsOutOfStock => 'بالطلب';

  @override
  String get partsDetailHint =>
      'قطعة أصلية بضمان الوكيل. الدفع الإلكتروني قادم مع وحدة المدفوعات — وحاليًا يمكنك شراء القطعة من أي فرع من فروع حسن جميل.';

  @override
  String get protTitle => 'الحماية والتلميع';

  @override
  String get protSubtitle => 'اختر سيارتك لعرض الباقات المتاحة.';

  @override
  String get protPickToStart => 'اختر سيارتك للبدء';

  @override
  String get protNoPackages => 'لا توجد باقات لهذا الموديل حاليًا.';

  @override
  String get protVehicleType => 'فئة السيارة';

  @override
  String get protTierSilver => 'فضي';

  @override
  String get protTierGold => 'ذهبي';

  @override
  String get protTierPlatinum => 'بلاتيني';

  @override
  String get protTierDiamond => 'ماسي';

  @override
  String get protBookTitle => 'احجز الباقة';

  @override
  String get protBranch => 'الفرع';

  @override
  String get protPickDate => 'اختر التاريخ';

  @override
  String get protNoHours =>
      'لا توجد مواعيد متاحة في هذا اليوم — اختر يومًا آخر.';

  @override
  String get protBooked => 'تم استلام حجزك — سيتواصل معك فريق الصيانة للتأكيد.';

  @override
  String get protConfirmBooking => 'تأكيد الحجز';

  @override
  String get acGoodMorning => 'صباح الخير';

  @override
  String get acGoodAfternoon => 'مساء الخير';

  @override
  String get acGoodEvening => 'مساء الخير';

  @override
  String get acGreetingSub => 'سياراتك جاهزة لمشوارك القادم.';

  @override
  String get acCarInService => 'سيارتك قيد الصيانة';

  @override
  String get acCarReady => 'سيارتك جاهزة للاستلام 🎉';

  @override
  String get acStageReceived => 'الاستلام';

  @override
  String get acStageInProgress => 'التنفيذ';

  @override
  String get acStageQuality => 'فحص الجودة';

  @override
  String get acStageReady => 'جاهزة';

  @override
  String get acStagePayment => 'الدفع';

  @override
  String get acAmountDue => 'المبلغ المطلوب';

  @override
  String get acSadad => 'رقم سداد';

  @override
  String get acUpcomingBooking => 'موعد الصيانة القادم';

  @override
  String get acCarDetails => 'تفاصيل السيارة';

  @override
  String get acNoCarsTitle => 'أضف سيارتك وتابع كل ما يخصها';

  @override
  String get acNoCarsSub =>
      'الصيانة والحجوزات والفواتير والعروض المخصصة لسيارتك — في مكان واحد.';

  @override
  String get acMyGarage => 'سياراتي';

  @override
  String get acAddCarShort => 'أضف سيارة';

  @override
  String get acAddCarTitle => 'أضف سيارتك';

  @override
  String get acAddCarSub =>
      'عندك سيارة بالفعل؟ سجّلها برقم الهيكل. تدوّر على سيارة؟ استعرض المتجر.';

  @override
  String get acHaveCar => 'عندي سيارة — سجّلها';

  @override
  String get acNoCar => 'ما عندي سيارة — استعرض السيارات';

  @override
  String get acAddCarCta => 'أضف سيارتي';

  @override
  String get acAddCarDone => 'تمت إضافة سيارتك إلى سياراتك.';

  @override
  String get acVin => 'رقم الهيكل (VIN)';

  @override
  String get acVinHelp => '17 خانة — تجده في استمارة السيارة';

  @override
  String get acPlateOptional => 'رقم اللوحة (اختياري)';

  @override
  String get acAliasOptional => 'اسم السيارة (اختياري)';

  @override
  String get acDuplicateVin => 'رقم الهيكل هذا مسجّل بالفعل في سياراتك.';

  @override
  String get acInvalidVin => 'أكمل الحقول — رقم الهيكل يجب أن يكون 17 خانة.';

  @override
  String get acUpdateMeter => 'تحديث العداد';

  @override
  String get acCurrentKm => 'القراءة الحالية';

  @override
  String get acInvalidReading => 'أدخل قراءة صحيحة.';

  @override
  String acLowerReading(String latest) {
    return 'لا يمكن أن تكون القراءة أقل من آخر قراءة مسجلة ($latest كم).';
  }

  @override
  String acLastBranchReading(String km) {
    return 'آخر قراءة موثقة: $km كم';
  }

  @override
  String get acChipReady => 'جاهزة';

  @override
  String acNextShort(String km) {
    return 'الصيانة عند $km كم';
  }

  @override
  String acNextPm(String next, String remaining) {
    return 'الصيانة القادمة عند $next كم — متبقي تقريبًا $remaining كم';
  }

  @override
  String acPmOverdue(String next) {
    return 'الصيانة متأخرة — صيانة $next كم مستحقة الآن';
  }

  @override
  String get acPmNeedsReading => 'أدخل قراءة العداد لمعرفة الصيانة المناسبة';

  @override
  String get acPmNoPlan => 'لا تتوفر خطة صيانة لهذا الموديل حاليًا.';

  @override
  String acOdometerLine(String km, String source) {
    return 'العداد: $km كم ($source)';
  }

  @override
  String get acSourceBranch => 'موثقة من الفرع';

  @override
  String get acSourceCustomer => 'إدخالك';

  @override
  String get acBuyCar => 'شراء سيارة';

  @override
  String get acMyOrders => 'متابعة طلباتي';

  @override
  String get acAllServices => 'جميع الخدمات';

  @override
  String get acJourneys => 'متابعة طلباتك';

  @override
  String get acJourneyService => 'صيانة';

  @override
  String get acJourneyBooking => 'حجز';

  @override
  String get acJourneyOrder => 'طلب';

  @override
  String get acJourneyFinance => 'طلب تمويل';

  @override
  String get acActionNeeded => 'مطلوب إجراء';

  @override
  String get acOrderTracking => 'تتبع الطلب';

  @override
  String get acNoTracking => 'لا توجد تحديثات تتبع بعد.';

  @override
  String get acOffersForYou => 'عروض مختارة لك';

  @override
  String get acTabForYou => 'لك';

  @override
  String get acVinLabel => 'رقم الهيكل';

  @override
  String get acPlate => 'اللوحة';

  @override
  String get acModelCode => 'كود الموديل';

  @override
  String get acLastMaintenance => 'آخر صيانة';

  @override
  String get acMeter => 'العداد';

  @override
  String get mbTitle => 'حجز صيانة';

  @override
  String get mbService => 'الخدمة';

  @override
  String get mbPackage => 'باقة الصيانة';

  @override
  String get notifTitle => 'الإشعارات';

  @override
  String get notifClear => 'مسح الكل';

  @override
  String get notifEmpty => 'لا توجد إشعارات بعد.';

  @override
  String get newsTitle => 'الأخبار';

  @override
  String get newsSubtitle => 'آخر الإطلاقات والفعاليات والإعلانات.';

  @override
  String get newsEmpty => 'لا توجد أخبار بعد.';

  @override
  String get contactTitle => 'تواصل معنا';

  @override
  String get contactSubtitle => 'اختر الفرع وأرسل رسالتك وسيتواصل معك فريقنا.';

  @override
  String get contactOpenMaps => 'افتح في خرائط Google';

  @override
  String get contactFormTitle => 'أرسل رسالة';

  @override
  String get contactSent => 'تم استلام رسالتك — سيتواصل معك فريقنا.';

  @override
  String get contactSubject => 'الموضوع';

  @override
  String get contactMessage => 'رسالتك';

  @override
  String get contactBranches => 'فروعنا';

  @override
  String get finReqTitle => 'طلبات التمويل';

  @override
  String get finReqEmpty => 'لا توجد طلبات تمويل بعد.';

  @override
  String get finReqReason => 'السبب';

  @override
  String get finReqTimeline => 'سجل المتابعة';

  @override
  String get finStageReceived => 'تم استلام طلبك';

  @override
  String get finStageContacting => 'جارِ التواصل معك';

  @override
  String get finStageSentToBank => 'تم إرساله للبنك';

  @override
  String get finStageApproved => 'تمت الموافقة';

  @override
  String get finStageRejected => 'تعذّر القبول';

  @override
  String get trackTitle => 'تتبع الصيانة';

  @override
  String get trackLive => 'مباشر';

  @override
  String get trackReconnecting => 'جارِ إعادة الاتصال…';

  @override
  String get trackEmpty =>
      'لا توجد سيارات في الورشة حاليًا — عند استلام سيارتك ستتابعها هنا لحظة بلحظة.';

  @override
  String get acAllServicesSub => 'كل خدمات حسن جميل على بُعد ضغطة.';

  @override
  String get offersForMyCar => 'لسيارتي';

  @override
  String get offersAnotherCar => 'سيارة أخرى';

  @override
  String mbStepOf(int step) {
    return 'الخطوة $step من 3';
  }

  @override
  String get mbStep1Title => 'اختر الخدمة';

  @override
  String get mbStep1Sub => 'ما الذي تحتاج إليه سيارتك؟';

  @override
  String get mbStep2Title => 'بيانات السيارة';

  @override
  String get mbStep2Sub => 'احجز لإحدى سياراتك أو لسيارة أخرى.';

  @override
  String get mbStep3Title => 'الموعد وبيانات التواصل';

  @override
  String get mbStep3Sub => 'اختر اليوم والوقت وأكّد بياناتك.';

  @override
  String get mbForMyCar => 'حجز لإحدى سياراتي';

  @override
  String get mbForAnotherCar => 'حجز لسيارة أخرى';

  @override
  String get mbVinAuto => 'تمت تعبئته تلقائيًا';

  @override
  String get mbNext => 'التالي';

  @override
  String get mbBack => 'السابق';

  @override
  String get mbBadgeSecure => 'حجز آمن';

  @override
  String get mbBadgeWarranty => 'ضمان 12 شهر';

  @override
  String get mbBadgeFreeCancel => 'إلغاء مجاني';

  @override
  String get calSun => 'الأحد';

  @override
  String get calMon => 'الاثنين';

  @override
  String get calTue => 'الثلاثاء';

  @override
  String get calWed => 'الأربعاء';

  @override
  String get calThu => 'الخميس';

  @override
  String get calFri => 'الجمعة';

  @override
  String get calSat => 'السبت';

  @override
  String get calAvailable => 'متاح';

  @override
  String get calHoliday => 'إجازة';

  @override
  String get calUnavailable => 'غير متاح';

  @override
  String get mbSubService => 'الخدمة الفرعية';

  @override
  String get protBasePrice => 'السعر الأساسي';

  @override
  String get protVat => 'الضريبة (15%)';

  @override
  String get protTotal => 'السعر الإجمالي';

  @override
  String get protReservePay => 'احجز وادفع بأمان';

  @override
  String get protMyCars => 'سياراتي';

  @override
  String get payMethodTitle => 'طريقة الدفع';

  @override
  String get payTinting => 'درجة التظليل';

  @override
  String get payConfirm => 'تأكيد ومتابعة الدفع';

  @override
  String get paySuccess => 'تم تأكيد الدفع — حجزك مؤكد. 🎉';

  @override
  String get payFailed => 'لم يكتمل الدفع — يمكنك المحاولة مرة أخرى.';

  @override
  String get paySadad => 'ادفع عبر سداد بهذا الرقم:';

  @override
  String get payGatewayTitle => 'دفع آمن';

  @override
  String get payMyfatoorahTag => 'بطاقة / Apple Pay / STC Pay';

  @override
  String get payTabbyTag => 'قسّمها على 4 — بدون فوائد';

  @override
  String get payTamaraTag => 'قسّمها حتى 12 — متوافقة مع الشريعة';

  @override
  String get homeProtForCar => 'باقات الحماية لسيارتك';

  @override
  String get offersForYourCar => 'لسيارتك';

  @override
  String get offersPickTime => 'اختر الوقت';

  @override
  String get profileAccount => 'الحساب والملف الشخصي';

  @override
  String get profileVehiclesSub => 'سياراتك وتفاصيلها';

  @override
  String get profileOrdersSub => 'تابع طلباتك وخدماتك';

  @override
  String get profileFinanceSub => 'تابع طلبات التمويل';

  @override
  String get profileFavoritesSub => 'سياراتك المحفوظة';

  @override
  String get profileNotifSub => 'صندوق إشعاراتك';

  @override
  String get profileContactSub => 'الفروع والدعم';

  @override
  String get profilePrefs => 'التفضيلات';

  @override
  String get profileDarkMode => 'الوضع الداكن';

  @override
  String get profileLanguage => 'اللغة';

  @override
  String get profileOn => 'مفعّل';

  @override
  String get profileOff => 'متوقف';

  @override
  String get profilePersonal => 'البيانات الشخصية';

  @override
  String get acActiveBadge => 'نشطة';

  @override
  String get svcProtectionSub => 'أفلام حماية وتظليل بجودة متميزة لسيارتك.';

  @override
  String get svcFinanceSub => 'خطط تمويل مرنة لترقيتك القادمة.';

  @override
  String get svcOffersSub => 'أحدث عروض السيارات والصيانة.';

  @override
  String get svcStoreSub => 'اطلب سيارتك أونلاين بخطوات بسيطة.';

  @override
  String get svcModelsSub => 'استكشف كل الموديلات والفئات.';

  @override
  String get svcFavoritesSub => 'السيارات التي أعجبتك في مكان واحد.';

  @override
  String get svcFinReqSub => 'تابع حالة طلبات التمويل الخاصة بك.';

  @override
  String get svcNewsSub => 'آخر أخبار حسن جميل والإصدارات.';

  @override
  String get svcContactSub => 'فروعنا وقنوات التواصل معنا.';

  @override
  String get svcTrackingSub => 'تابع سيارتك في الورشة لحظة بلحظة.';

  @override
  String get protPopular => 'الأكثر طلبًا';

  @override
  String get protSelectPackage => 'اختر الباقة';

  @override
  String get offersClaim => 'احصل على العرض الآن';

  @override
  String get protChoose => 'اختيار';

  @override
  String get protWhyTitle => 'لماذا تختار خدماتنا؟';

  @override
  String get protWhyUv => 'حماية UV';

  @override
  String get protWhyUvSub => 'حماية من أشعة الشمس.';

  @override
  String get protWhyWater => 'طارد للمياه';

  @override
  String get protWhyWaterSub => 'تقنية النانو الهايدروفوبية.';

  @override
  String get protWhyInstall => 'تركيب احترافي';

  @override
  String get protWhyInstallSub => 'على يد فنيين معتمدين.';

  @override
  String get protWhyWarranty => 'جودة مضمونة';

  @override
  String get protWhyWarrantySub => 'ضمان على جميع الخدمات.';

  @override
  String get protBookNow => 'احجز موعد الآن';

  @override
  String get protSelectedCar => 'السيارة المختارة';

  @override
  String get protPlate => 'رقم اللوحة';

  @override
  String get protOtherModel => 'اختيار موديل آخر';

  @override
  String get contactCallNow => 'اتصل الآن';

  @override
  String get partsSortRelevance => 'الأنسب';

  @override
  String get jdStatus => 'الحالة';

  @override
  String get jdReference => 'رقم المرجع';

  @override
  String get jdDate => 'التاريخ';

  @override
  String get jdTotal => 'الإجمالي';

  @override
  String get jdPayNow => 'ادفع الآن';

  @override
  String get jdDetailsTitle => 'تفاصيل الطلب';

  @override
  String get pcTitle => 'سلة قطع الغيار';

  @override
  String get pcEmpty => 'سلتك فارغة';

  @override
  String get pcSummary => 'الملخص';

  @override
  String get pcCoupon => 'كود الخصم';

  @override
  String get pcApply => 'تطبيق';

  @override
  String get pcCouponInvalid => 'الكود غير صالح';

  @override
  String get pcSubtotal => 'الإجمالي الفرعي';

  @override
  String get pcDiscount => 'الخصم';

  @override
  String get pcVat => 'ضريبة القيمة المضافة (15%)';

  @override
  String get pcTotal => 'الإجمالي';

  @override
  String get pcCheckout => 'إتمام الطلب';

  @override
  String get pcContinue => 'متابعة التسوق';

  @override
  String get pcRemove => 'إزالة';

  @override
  String get pcAddToCart => 'أضف إلى السلة';

  @override
  String get pcInCart => 'في السلة';

  @override
  String get pcQty => 'الكمية';

  @override
  String get pcCheckoutTitle => 'إتمام الطلب والدفع';

  @override
  String get pcPickup => 'استلام من الفرع';

  @override
  String get pcPickupMethod => 'طريقة الاستلام';

  @override
  String get pcChooseBranch => 'اختر الفرع';

  @override
  String get pcContact => 'بيانات التواصل';

  @override
  String get pcPayMethod => 'طريقة الدفع';

  @override
  String get pcOrder => 'الطلب';

  @override
  String get pcPayMyfatoorah => 'بطاقة ائتمان (ماي فاتورة)';

  @override
  String get pcPayTabby => 'تابي — قسّمها على 4 دفعات';

  @override
  String get pcPayTamara => 'تمارا — قسط حتى 12 دفعة';

  @override
  String get pcPaySadad => 'سداد';

  @override
  String get pcSadadTitle => 'رقم سداد';

  @override
  String get pcSadadHint => 'ادفع عبر سداد باستخدام هذا الرقم.';

  @override
  String get pcSuccess => 'تم استلام طلبك بنجاح!';

  @override
  String get pcOrderNo => 'رقم الطلب';

  @override
  String get pcPayFailed => 'لم يكتمل الدفع. حاول مرة أخرى.';

  @override
  String get pcAdded => 'تمت الإضافة إلى السلة';

  @override
  String get pcViewCart => 'عرض السلة';

  @override
  String get ucTitle => 'سيارات مستعملة موثوقة';

  @override
  String get ucSubtitle =>
      'سيارات معروضة من ملّاكها، وبعضها مفحوص بواسطة حسن جميل لراحة بالك.';

  @override
  String get ucSellCta => 'اعرض سيارتك';

  @override
  String get ucEmpty => 'لا توجد سيارات معروضة حالياً.';

  @override
  String get ucInspected => 'مفحوصة بواسطة حسن جميل';

  @override
  String get ucPriceOnContact => 'السعر عند التواصل';

  @override
  String get ucKm => 'كم';

  @override
  String get ucWhatsapp => 'تواصل للشراء عبر واتساب';

  @override
  String get ucCarInfo => 'معلومات السيارة';

  @override
  String get ucInspectionTitle => 'فحص السيارة الشامل';

  @override
  String get ucInspectionSub => 'فحص دقيق لكل أجزاء السيارة.';

  @override
  String get ucSafety => 'الأمان';

  @override
  String get ucComfort => 'الراحة';

  @override
  String get ucTech => 'تقنيات';

  @override
  String get ucExterior => 'تجهيزات خارجية';

  @override
  String get ucYear => 'السنة';

  @override
  String get ucMileage => 'الممشى';

  @override
  String get ucFuel => 'الوقود';

  @override
  String get ucGearbox => 'الجير';

  @override
  String get ucDrive => 'الدفع';

  @override
  String get ucCondition => 'الحالة';

  @override
  String get ucSeats => 'المقاعد';

  @override
  String get ucDoors => 'الأبواب';

  @override
  String get ucExtColor => 'اللون الخارجي';

  @override
  String get ucIntColor => 'اللون الداخلي';

  @override
  String get ucOrigin => 'الوارد';

  @override
  String get ucLicenseDuration => 'مدة الرخصة';

  @override
  String get ucNotes => 'ملاحظات';

  @override
  String get ucAddTitle => 'أضف سيارتك المستعملة';

  @override
  String get ucStepOwner => 'المالك';

  @override
  String get ucStepCar => 'السيارة';

  @override
  String get ucStepSpecs => 'المواصفات';

  @override
  String get ucStepLicense => 'الرخصة والملاحظات';

  @override
  String get ucStepPhotos => 'الصور';

  @override
  String get ucStepReview => 'المراجعة';

  @override
  String get ucBrand => 'العلامة';

  @override
  String get ucCarName => 'اسم السيارة';

  @override
  String get ucModelName => 'الموديل / الفئة';

  @override
  String get ucBodyType => 'نوع الهيكل';

  @override
  String get ucPrice => 'السعر (اختياري)';

  @override
  String get ucChassis => 'رقم الهيكل';

  @override
  String get ucLicenseNo => 'رقم اللوحة / الرخصة';

  @override
  String get ucLicenseExpiry => 'تاريخ انتهاء الرخصة';

  @override
  String get ucReqInspection => 'أطلب فحص حسن جميل لسيارتي';

  @override
  String get ucAddPhotos => 'أضف صور السيارة';

  @override
  String get ucSubmit => 'إرسال الطلب';

  @override
  String get ucSubmitted =>
      'تم استلام طلبك! سنراجع البيانات ونتواصل معك عند الموافقة.';

  @override
  String get trkHubTitle => 'متابعة الطلبات';

  @override
  String get trkAll => 'الكل';

  @override
  String get trkKindMaintenance => 'الصيانة';

  @override
  String get trkKindProtection => 'الحماية والتلميع';

  @override
  String get trkKindOrders => 'طلباتي';

  @override
  String get trkHubEmpty => 'لا توجد طلبات للمتابعة.';

  @override
  String get mbuyType => 'نوع الشراء';

  @override
  String get mbuyOnline => 'أونلاين';

  @override
  String get mbuyOrder => 'أمر شراء';

  @override
  String get mbuyFastReserve => 'حجز سريع';

  @override
  String get mbuyCash => 'كاش';

  @override
  String get mbuyDelivery => 'طريقة الاستلام';

  @override
  String get mbuyBranch => 'استلام من الفرع';

  @override
  String get mbuyAddress => 'توصيل لعنوان';

  @override
  String get mbuyAddressHint => 'اكتب عنوان التوصيل';

  @override
  String get mbuySwipe => 'اسحب لإتمام الطلب';

  @override
  String get mbuySelect => 'اختر...';

  @override
  String get onboardingHello => 'أهلاً';

  @override
  String get modelsAvailableTrims => 'الفئات المتوفرة';

  @override
  String get modelsChooseTrim => 'اختر الفئة';

  @override
  String get modelsChosen => 'تم الاختيار';

  @override
  String get modelsDiffsOnly => 'إظهار الاختلافات فقط';

  @override
  String get modelsCompareHint => 'اختر فئتين للمقارنة جنبًا إلى جنب';

  @override
  String get modelsColorsTitle => 'الألوان المتاحة';

  @override
  String get modelsSpecsFor => 'مواصفات الفئة';

  @override
  String get pfTitle => 'حسابي';

  @override
  String get pfMyData => 'بياناتي';

  @override
  String get pfMyCars => 'سياراتي';

  @override
  String get pfMyOrders => 'طلباتي';

  @override
  String get pfMyBookings => 'حجوزاتي';

  @override
  String get pfFinanceRequests => 'طلبات التمويل';

  @override
  String get pfFavorites => 'المفضلة';

  @override
  String get pfNotifications => 'الإشعارات';

  @override
  String get pfContactData => 'بيانات الاتصال';

  @override
  String get pfPassword => 'كلمة المرور';

  @override
  String get pfDeleteAccount => 'حذف الحساب';

  @override
  String get pfSave => 'حفظ التغييرات';

  @override
  String get pfSaved => 'تم الحفظ بنجاح';

  @override
  String get pfSaveFailed => 'تعذّر حفظ بعض البيانات';

  @override
  String get pfNameAr => 'الاسم بالعربية';

  @override
  String get pfNameEn => 'الاسم بالإنجليزية';

  @override
  String get pfFirstName => 'الاسم الأول';

  @override
  String get pfMiddleName => 'اسم الأب';

  @override
  String get pfLastName => 'اسم العائلة';

  @override
  String get pfGender => 'الجنس';

  @override
  String get pfCountry => 'الدولة';

  @override
  String get pfCity => 'المدينة';

  @override
  String get pfAddress => 'العنوان';

  @override
  String get pfIdentity => 'رقم الهوية';

  @override
  String get pfCr => 'السجل التجاري';

  @override
  String get pfAccountType => 'صفة الحساب';

  @override
  String get pfPhone => 'رقم الجوال';

  @override
  String get pfEmail => 'البريد الإلكتروني';

  @override
  String get pfPhoneExists => 'رقم الجوال مستخدم بالفعل';

  @override
  String get pfEmailExists => 'البريد الإلكتروني مستخدم بالفعل';

  @override
  String get pfIdentityExists => 'رقم الهوية مستخدم بالفعل';

  @override
  String get pfOldPassword => 'كلمة المرور الحالية';

  @override
  String get pfNewPassword => 'كلمة المرور الجديدة';

  @override
  String get pfConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get pfPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get pfPasswordShort => '٦ أحرف على الأقل';

  @override
  String get pfWrongOldPassword => 'كلمة المرور الحالية غير صحيحة';

  @override
  String get pfChangePassword => 'تغيير كلمة المرور';

  @override
  String get pfDeleteWarning =>
      'سيتم تعطيل حسابك وإخفاء بياناتك من التطبيق. لا يمكن التراجع عن هذا الإجراء من التطبيق.';

  @override
  String get pfDeleteConfirmHint => 'اكتب \"حذف\" للتأكيد';

  @override
  String get pfDeleteWord => 'حذف';

  @override
  String get pfSignedInAs => 'مسجّل الدخول باسم';

  @override
  String get pfChangePhoto => 'تغيير الصورة';

  @override
  String get pfViewPhoto => 'عرض الصورة';

  @override
  String get pfPhotoUpdated => 'تم تحديث الصورة';

  @override
  String get pfPhotoFailed => 'تعذّر تحديث الصورة — حاول مرة أخرى.';

  @override
  String get pfGuest => 'زائر';

  @override
  String get pfSignIn => 'تسجيل الدخول';

  @override
  String get pfNoNotifications => 'لا توجد إشعارات بعد';

  @override
  String get pfNoFavorites => 'لا توجد عناصر في المفضلة';

  @override
  String get cmpTitle => 'الشكاوى';

  @override
  String get cmpSubmit => 'تقديم شكوى';

  @override
  String get cmpSubmitSub => 'أخبرنا بما حدث وسيتابع فريقنا شكواك خطوة بخطوة';

  @override
  String get cmpTrack => 'متابعة الشكاوى';

  @override
  String get cmpTrackSub => 'تابع حالة شكاواك وردود فريقنا خطوة بخطوة';

  @override
  String get cmpType => 'نوع الشكوى';

  @override
  String get cmpTypeSales => 'المبيعات';

  @override
  String get cmpTypeParts => 'قطع الغيار';

  @override
  String get cmpTypeMaintenance => 'الصيانة';

  @override
  String get cmpTypeOther => 'أخرى';

  @override
  String get cmpName => 'الاسم';

  @override
  String get cmpPhone => 'الهاتف';

  @override
  String get cmpEmail => 'البريد الإلكتروني (اختياري)';

  @override
  String get cmpSubject => 'الموضوع (اختياري)';

  @override
  String get cmpBody => 'تفاصيل الشكوى';

  @override
  String get cmpBodyHint => 'اشرح لنا ما حدث بالتفصيل…';

  @override
  String get cmpAttach => 'صور مرفقة (اختياري)';

  @override
  String get cmpAttachHint =>
      'يمكنك إرفاق حتى 6 صور (بحد أقصى 4 ميجابايت للصورة)';

  @override
  String get cmpConsent => 'أوافق على سياسة الخصوصية ومعالجة بياناتي الشخصية';

  @override
  String get cmpSend => 'إرسال الشكوى';

  @override
  String get cmpSent => 'تم استلام شكواك';

  @override
  String get cmpRef => 'رقم الشكوى';

  @override
  String get cmpStageReceived => 'تم استلام الشكوى';

  @override
  String get cmpStageUpdated => 'تحديث / رد';

  @override
  String get cmpStageSolved => 'تم الحل';

  @override
  String get cmpStatusNew => 'تم الاستلام';

  @override
  String get cmpStatusUpdated => 'يوجد رد جديد';

  @override
  String get cmpStatusSolved => 'تم الحل';

  @override
  String get cmpConversation => 'المحادثة';

  @override
  String get cmpYou => 'أنت';

  @override
  String get cmpStaff => 'فريق خدمة العملاء';

  @override
  String get cmpReplyHint => 'اكتب ردك…';

  @override
  String get cmpReplySend => 'إرسال الرد';

  @override
  String get cmpEmpty => 'لا توجد شكاوى بعد';

  @override
  String get cmpBodyText => 'نص الشكوى';

  @override
  String get finReqSub => 'امتلك سيارتك مع عروض تمويل لا تفوتك';

  @override
  String get finAbsher => 'تعبئة البيانات من أبشر';

  @override
  String get finAbsherOtp => 'رمز التحقق';

  @override
  String get finAbsherId => 'رقم الهوية';

  @override
  String get finAbsherMobile => 'رقم الجوال (5xxxxxxxx)';

  @override
  String get finAbsherBirth => 'تاريخ الميلاد';

  @override
  String get finAbsherSend => 'إرسال رمز التحقق';

  @override
  String get finAbsherConfirm => 'تأكيد';

  @override
  String get finAbsherFilled => 'تمت تعبئة البيانات من أبشر';

  @override
  String get finDocs => 'المستندات المطلوبة';

  @override
  String get finDocsHint =>
      'اختياري الآن — يمكنك إرفاقها لتسريع طلبك، أو سيتواصل معك فريقنا لاستلامها';

  @override
  String get finWorkSector => 'جهة العمل';

  @override
  String get finGov => 'حكومي';

  @override
  String get finPrivate => 'قطاع خاص';

  @override
  String get finIdDoc => 'الهوية الوطنية';

  @override
  String get finLicenseDoc => 'رخصة القيادة';

  @override
  String get finSalaryDoc => 'تعريف بالراتب';

  @override
  String get finInsuranceDoc => 'برنت التأمينات';

  @override
  String get finStatementDoc => 'كشف حساب بنكي';

  @override
  String get finUpload => 'رفع';

  @override
  String get finUploaded => 'تم الإرفاق';

  @override
  String get finPickFile => 'اختر ملفًا (صورة أو PDF)';

  @override
  String get finFileTooBig => 'الحد الأقصى 4 ميجابايت';

  @override
  String get finIncome => 'صافي الدخل الشهري';

  @override
  String get finFirstPayOptional => 'الدفعة الأولى (اختياري)';

  @override
  String get finLastPay => 'الدفعة الأخيرة';

  @override
  String get finMonthly => 'القسط الشهري';

  @override
  String get finFinalPrice => 'السعر النهائي';

  @override
  String get finPeriodTitle => 'مدة التمويل';

  @override
  String get finMonths => 'شهر';

  @override
  String get finNotes => 'ملاحظات';

  @override
  String get finFullName => 'الاسم الكامل';

  @override
  String get finSendReq => 'إرسال الطلب';

  @override
  String get finReqSent => 'تم استلام طلبك';

  @override
  String get finReqRef => 'رقم الطلب';

  @override
  String get finTrackCta => 'تابع الطلب';

  @override
  String get finBankRate => 'جهة التمويل';

  @override
  String get finIncomeRequired => 'أدخل صافي الدخل';

  @override
  String get trkKindFinance => 'التمويل';

  @override
  String get acJobCard => 'بطاقة العمل';

  @override
  String get acTabMyCars => 'سياراتي';

  @override
  String get acStoreToyota => 'متجر تويوتا';

  @override
  String get acStoreLexus => 'متجر لكزس';

  @override
  String get acKm => 'كم';

  @override
  String get acQuickTitle => 'خدمات سريعة';

  @override
  String get cpnExclusive => 'عرض حصري';

  @override
  String get cpnCopied => 'تم نسخ الكود';

  @override
  String get cpnRemove => 'إزالة';

  @override
  String get cpnCouponDiscount => 'خصم الكوبون';

  @override
  String get svcPartsSub => 'قطع غيار أصلية لسيارتك — استلام من الفرع';

  @override
  String get mhTitle => 'خدمات الصيانة';

  @override
  String get mhHeroBadge => 'مركز الصيانة';

  @override
  String get mhHeroTitle => 'احجز صيانتك';

  @override
  String get mhHeroAccent => 'في 10 ثوانٍ';

  @override
  String get mhHeroSub =>
      'مركز صيانة معتمد بخبرة تتجاوز 60 عامًا. قطع غيار أصلية وفنيون معتمدون من المصنع.';

  @override
  String get mhBadgeCertified => 'صيانة معتمدة رسميًا';

  @override
  String get mhBadgeSaso => 'معتمد من SASO';

  @override
  String get mhReserveNow => 'احجز الآن';

  @override
  String get mhPeriodic => 'الجدول الدوري';

  @override
  String get mhYears => 'عام خبرة';

  @override
  String get mhCars => 'سيارة خُدمت';

  @override
  String get mhSatisfaction => 'رضا الضيوف';

  @override
  String get mhBranches => 'فرع';

  @override
  String get mhJourney => 'رحلة صيانتك';

  @override
  String get mhJourneySub => 'أربع خطوات بسيطة فقط من الحجز إلى الاستلام.';

  @override
  String get mhStep1 => 'حجز موعد';

  @override
  String get mhStep1Sub => 'اختر الخدمة والوقت المناسب لك';

  @override
  String get mhStep2 => 'فحص السيارة';

  @override
  String get mhStep2Sub => 'يقوم خبراؤنا بفحص دقيق وشامل';

  @override
  String get mhStep3 => 'تنفيذ الصيانة';

  @override
  String get mhStep3Sub => 'تتم الصيانة بأعلى معايير الجودة';

  @override
  String get mhStep4 => 'استلام السيارة';

  @override
  String get mhStep4Sub => 'استلم سيارتك جاهزة وبأفضل حال';

  @override
  String get mhOffers => 'عروض الصيانة';

  @override
  String get mhWhyTitle => 'لماذا تختار حسن جميل؟';

  @override
  String get mhWhySub => 'أرقام وحقائق تتحدث عن نفسها.';

  @override
  String get mhFeatures => 'المزايا';

  @override
  String get mhUs => 'نحن';

  @override
  String get mhOthers => 'غيرنا';

  @override
  String get mhRowParts => 'قطع غيار أصلية 100%';

  @override
  String get mhRowDiag => 'أجهزة فحص معتمدة من المصنع';

  @override
  String get mhRowTeam => 'فريق عمل متخصص';

  @override
  String get mhRowReport => 'تقرير فني رقمي بالصور';

  @override
  String get mhRowTech => 'فنيون معتمدون من المصنع';

  @override
  String get mhFeedback => 'آراء الضيوف';

  @override
  String get mhVerified => 'ضيف موثّق';

  @override
  String get mhPeriodicTitle => 'جدول الصيانة الدورية';

  @override
  String get mhPeriodicSub => 'اختر المسافة لعرض بنود الصيانة المجدولة.';

  @override
  String get mhPeriodicEmpty => 'لا توجد بيانات صيانة دورية حالياً.';

  @override
  String get mhImportant => 'ملاحظة هامة';

  @override
  String get mhReady => 'جاهز للحجز؟';

  @override
  String get mhReadySub => 'احجز موعدك خلال ثوانٍ واستلم سيارتك بأفضل حال.';

  @override
  String get mhBookService => 'احجز خدمة';

  @override
  String get mhWhatsApp => 'تحدث عبر واتساب';

  @override
  String get alNickname => 'الاسم المستعار';

  @override
  String get alRename => 'تغيير الاسم';

  @override
  String get alSaved => 'تم حفظ الاسم';

  @override
  String get contactPopTitle => 'خدمة العملاء';

  @override
  String get contactPopOnline => 'متصل الآن';

  @override
  String get contactPopWhatsApp => 'محادثة واتساب';

  @override
  String get contactPopCall => 'اتصل بنا';

  @override
  String get osOrderDetails => 'تفاصيل الطلب';

  @override
  String get osInclVat => 'شامل ضريبة القيمة المضافة';

  @override
  String get osExteriorColor => 'اللون الخارجي';

  @override
  String get osInnerColor => 'اللون الداخلي';

  @override
  String get osTotal => 'الإجمالي';

  @override
  String get osAmountRequired => 'المبلغ المطلوب دفعه';

  @override
  String get osHowYouPay => 'طريقة الدفع';

  @override
  String get osPayHint =>
      'تُدفع الدفعة الأولى عبر فيزا أو مدى، والمبلغ المتبقي عبر سداد.';

  @override
  String get formPayConfirm => 'ادفع وأكّد الحجز';

  @override
  String get reserveWillPay => 'ستدفع الآن';

  @override
  String get linkTerms => 'الشروط والأحكام';

  @override
  String get linkPrivacy => 'سياسة الموقع';

  @override
  String get termsPrefix => 'لقد قرأت ';

  @override
  String get termsJoin => ' و';

  @override
  String get termsSuffix => ' وأوافق.';

  @override
  String get finReqLearnTitle => 'ما هي متطلبات التمويل والوثائق المطلوبة؟';

  @override
  String get finReqLearnMore => 'اعرف أكثر';

  @override
  String get finReqDialogReqs => 'متطلبات التمويل:';

  @override
  String get finReqDialogDocs => 'الوثائق المطلوبة:';

  @override
  String get finReqSaudi => 'سعودي';

  @override
  String get finReqResident => 'مقيم';

  @override
  String get finReqAge => 'عمر الضيف يبدأ من ٢١ سنة';

  @override
  String get finReqWorkDuration => 'مدة العمل ٩٥ يومًا';

  @override
  String get finReqSalarySaudi => 'الراتب يبدأ من ٣٠٠٠ ريال';

  @override
  String get finReqSalaryResident => 'الراتب يبدأ من ٥٠٠٠ ريال';

  @override
  String get finReqDoc1 => 'الهوية الشخصية سارية المفعول';

  @override
  String get finReqDoc2 => 'رخصة قيادة سارية المفعول';

  @override
  String get finReqDoc3 => 'برنت تأمينات حديث لا تتجاوز مدته ١٠ أيام';

  @override
  String get finReqDoc4 =>
      'تعريف بالراتب مصدّق من الغرفة التجارية لا تتجاوز مدته شهرين';

  @override
  String get finReqDoc5 => 'كشف حساب آخر ٣ أشهر';

  @override
  String get cpcTitle => 'أكمل شراء سيارتك';

  @override
  String get cpcDepositBanner =>
      'تم استلام العربون وتأكيد حجز سيارتك. أكمل خطوات الشراء أدناه.';

  @override
  String get cpcYourCar => 'سيارتك';

  @override
  String get cpcStepProtection => 'الحماية والتظليل';

  @override
  String get cpcStepContract => 'العقد والتوقيع';

  @override
  String get cpcStepDelivery => 'جدولة التسليم';

  @override
  String get cpcStepPayment => 'المبلغ المتبقي';

  @override
  String get cpcProtectionHint =>
      'اختر باقات الحماية والتظليل التي ترغب بإضافتها لسيارتك (اختياري).';

  @override
  String get cpcNoPackages =>
      'لا توجد باقات حماية متاحة لهذه المركبة. يمكنك المتابعة بدون إضافة.';

  @override
  String get cpcNoneSelected => 'لم تختر أي باقة';

  @override
  String cpcSelectedCount(int count) {
    return '$count باقة مختارة';
  }

  @override
  String get cpcByChoice => 'حسب الاختيار';

  @override
  String get cpcConfirmSelection => 'تأكيد الاختيار';

  @override
  String get cpcContinueWithout => 'متابعة بدون إضافة';

  @override
  String get cpcLockedStep =>
      'هذه الخطوة قريبًا في التطبيق — سيتواصل معك فريقنا لإكمالها.';

  @override
  String get cpcNotFound => 'تعذّر العثور على حجز السيارة المرتبط بهذا الرابط.';

  @override
  String get cpcResumeBanner => 'أكمل عملية شراء سيارتك';

  @override
  String get cpcSelectionDone =>
      'تم تسجيل اختيارك — سيتم إكمال الخطوات التالية مع فريقنا.';

  @override
  String get cpcCompletePurchase => 'أكمل الشراء';

  @override
  String get cpcBack => 'السابق';

  @override
  String get cpcSignInFirst => 'سجّل الدخول لمتابعة خطوات شراء سيارتك.';

  @override
  String get cpcContractTitle => 'عقد البيع والتوقيع';

  @override
  String get cpcAddons => 'الإضافات:';

  @override
  String get cpcContractPreparing =>
      'جارٍ إنشاء أمر البيع وتجهيز العقد، من فضلك لا تغلق الشاشة…';

  @override
  String get cpcContractFailed => 'تعذّر إنشاء أمر البيع.';

  @override
  String get cpcContractReady => 'عقد البيع الخاص بك جاهز.';

  @override
  String get cpcViewContract => 'عرض العقد (PDF)';

  @override
  String get cpcAgreeContract => 'أوافق على شروط وأحكام عقد البيع.';

  @override
  String get cpcAgreeFirst => 'يجب الموافقة على الشروط أولاً.';

  @override
  String get cpcNoIdentity => 'رقم الهوية غير متوفر في حسابك.';

  @override
  String get cpcSignAbsher => 'التوقيع عبر أبشر';

  @override
  String get cpcSignOtpHint => 'أدخل رمز التحقق المرسل إلى جوالك عبر أبشر';

  @override
  String get cpcSignConfirm => 'تأكيد التوقيع';

  @override
  String get cpcSignResend => 'إعادة إرسال الرمز';

  @override
  String get cpcSignSendFailed => 'تعذّر إرسال رمز التوثيق، حاول مجددًا.';

  @override
  String get cpcSignInvalidOtp => 'رمز التحقق غير صحيح.';

  @override
  String get cpcTestModeSign => 'وضع الاختبار: يتم التوقيع بدون أبشر.';

  @override
  String get cpcSignTest => 'توقيع العقد (اختبار)';

  @override
  String get cpcAlreadySigned => 'تم توقيع العقد.';

  @override
  String get cpcContinue => 'متابعة';

  @override
  String get cpcDeliveryHint => 'اختر تاريخ ووقت استلام سيارتك.';

  @override
  String get cpcDeliveryLoading => 'جارٍ تحميل جدولة التسليم…';

  @override
  String get cpcDeliveryNotReady =>
      'سيتم تفعيل جدولة التسليم بعد تأكيد أمر البيع (عادةً خلال يوم عمل واحد). يمكنك متابعة الدفع الآن وجدولة التسليم لاحقًا.';

  @override
  String get cpcDeliveryDate => 'التاريخ';

  @override
  String get cpcDeliveryTimes => 'الأوقات المتاحة';

  @override
  String get cpcDeliveryNoSlots =>
      'لا توجد أوقات متاحة في هذا اليوم. جرّب تاريخًا آخر.';

  @override
  String get cpcDeliveryBooked => 'تم حجز موعد التسليم';

  @override
  String get cpcDeliveryBookFailed => 'تعذّر حجز الموعد، حاول مجددًا.';

  @override
  String get cpcDeliveryConfirm => 'تأكيد الموعد';

  @override
  String get cpcDeliveryLater => 'جدولة لاحقًا';

  @override
  String get cpcContinuePayment => 'متابعة للدفع';

  @override
  String get cpcPayTitle => 'سداد المبلغ المتبقي';

  @override
  String get cpcPayCar => 'سعر السيارة (شامل الضريبة)';

  @override
  String get cpcPayAddons => 'الإضافات (حماية وتظليل)';

  @override
  String get cpcPayDeposit => 'العربون المدفوع';

  @override
  String get cpcPayRemaining => 'المبلغ المتبقي';

  @override
  String get cpcPayProceed => 'إتمام الدفع';

  @override
  String get cpcSadadOpenBank =>
      'افتح تطبيق البنك ← سداد وأدخل الرقم لإتمام الدفع.';

  @override
  String get cpcPayDone => 'تم إتمام شراء سيارتك بنجاح';

  @override
  String get cpcPayProcessing => 'عملية الدفع قيد المعالجة';

  @override
  String get cpcPayThanks =>
      'شكرًا لاختيارك حسن جميل. ستصلك تفاصيل التسليم قريبًا.';

  @override
  String get cpcPayConfirming => 'جارٍ التحقق من حالة الدفع…';

  @override
  String get cpcTestModePay =>
      'وضع الاختبار: يتم اعتبار الدفع مكتملًا بدون التوجه لبوابة الدفع.';

  @override
  String get cpcPayTest => 'إتمام الشراء (اختبار)';

  @override
  String get cpcTestPaid => 'تم إتمام الشراء (وضع الاختبار)';

  @override
  String get cpcTestPaidHint => 'تم اجتياز جميع الخطوات بنجاح بدون دفع فعلي.';

  @override
  String get offersFinancingBy => 'جهة التمويل';

  @override
  String get pfDeleteNote =>
      'تنبيه: هذا الإجراء سيحذف حسابك ويخفي جميع بياناتك نهائيًا ولا يمكن التراجع عنه من التطبيق.';

  @override
  String get pfDeleteDialogTitle => 'حذف الحساب؟';

  @override
  String get pfDeleteDialogBody =>
      'هل أنت متأكد أنك تريد حذف حسابك؟ سيتم إخفاء بياناتك من التطبيق ولا يمكن التراجع عن هذا الإجراء.';

  @override
  String get pfCancel => 'إلغاء';
}
