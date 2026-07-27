import 'package:equatable/equatable.dart';

/// One onboarding slide — dashboard-managed via dbo.App_Onboarding_Slides
/// (same control cycle as the website's Home Hero tabs).
final class OnboardingSlide extends Equatable {
  const OnboardingSlide({
    required this.id,
    this.brandKey,
    this.titleAr,
    this.titleEn,
    this.subtitleAr,
    this.subtitleEn,
    this.badgeAr,
    this.badgeEn,
    this.mediaType = 'image',
    this.mediaUrl,
    this.overlay = true,
    this.sortOrder = 0,
  });

  final int id;
  final String? brandKey;
  final String? titleAr;
  final String? titleEn;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? badgeAr;
  final String? badgeEn;
  final String mediaType;
  final String? mediaUrl;
  final bool overlay;
  final int sortOrder;

  String title(String lang) => (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';
  String subtitle(String lang) =>
      (lang == 'ar' ? subtitleAr : subtitleEn) ?? subtitleEn ?? subtitleAr ?? '';
  String badge(String lang) => (lang == 'ar' ? badgeAr : badgeEn) ?? badgeEn ?? badgeAr ?? '';

  factory OnboardingSlide.fromJson(Map<String, dynamic> json) => OnboardingSlide(
        id: (json['id'] as num?)?.toInt() ?? 0,
        brandKey: json['brandKey'] as String?,
        titleAr: json['titleAr'] as String?,
        titleEn: json['titleEn'] as String?,
        subtitleAr: json['subtitleAr'] as String?,
        subtitleEn: json['subtitleEn'] as String?,
        badgeAr: json['badgeAr'] as String?,
        badgeEn: json['badgeEn'] as String?,
        mediaType: json['mediaType'] as String? ?? 'image',
        mediaUrl: json['mediaUrl'] as String?,
        overlay: json['overlay'] as bool? ?? true,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [id, titleEn, mediaUrl, sortOrder];
}

/// Bundled sign-in/up banner (placement 'auth') fallback — no media, the
/// screens draw the brand gradient instead.
const kAuthFallback = [
  OnboardingSlide(id: -20, titleEn: 'Welcome', titleAr: 'مرحباً بك'),
];

/// Bundled pre-sign-in welcome banner (placement 'welcome') fallback.
const kWelcomeFallback = [
  OnboardingSlide(
    id: -10,
    titleEn: 'Find Your Perfect Car',
    titleAr: 'اعثر على سيارتك المثالية',
    subtitleEn:
        'The most trusted place to buy Toyota & Lexus vehicles in Saudi Arabia.',
    subtitleAr: 'المنصة الأكثر موثوقية لشراء سيارات تويوتا ولكزس في المملكة.',
  ),
];

/// Bundled slides shown until the dashboard table has content (or offline).
const kDefaultSlides = [
  OnboardingSlide(
    id: -1,
    titleEn: 'Drive the Future of Performance',
    titleAr: 'انطلق نحو مستقبل الأداء',
    subtitleEn:
        'Browse the latest Toyota & Lexus vehicles and reserve yours online in a few simple steps.',
    subtitleAr: 'تصفح أحدث سيارات تويوتا ولكزس، واحجز سيارتك أونلاين بخطوات بسيطة.',
    badgeEn: 'HASSAN JAMEEL • TOYOTA & LEXUS',
    badgeAr: 'حسن جميل • تويوتا ولكزس',
    sortOrder: 1,
  ),
  OnboardingSlide(
    id: -2,
    titleEn: 'Maintenance Made Effortless',
    titleAr: 'صيانة أسهل، بدون انتظار',
    subtitleEn:
        'Book maintenance appointments and track your vehicle and orders — all in one place.',
    subtitleAr: 'احجز مواعيد الصيانة، وتابع سيارتك وطلباتك من مكان واحد.',
    badgeEn: 'BOOK SERVICE IN UNDER A MINUTE',
    badgeAr: 'حجز الصيانة خلال دقيقة',
    sortOrder: 2,
  ),
  OnboardingSlide(
    id: -3,
    titleEn: 'Offers & Finance Built for You',
    titleAr: 'عروض وتمويل يناسبك',
    subtitleEn:
        'Discover exclusive offers and compare finance plans from certified banks.',
    subtitleAr: 'اكتشف العروض الحصرية وقارن حلول التمويل من البنوك المعتمدة.',
    badgeEn: 'EXCLUSIVE IN-APP OFFERS',
    badgeAr: 'عروض حصرية داخل التطبيق',
    sortOrder: 3,
  ),
];
