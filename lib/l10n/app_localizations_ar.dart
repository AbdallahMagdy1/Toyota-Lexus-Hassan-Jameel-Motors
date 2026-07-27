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
}
