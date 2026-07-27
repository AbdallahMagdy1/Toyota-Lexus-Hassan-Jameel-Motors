part of 'theme_cubit.dart';

final class ThemeState extends Equatable {
  const ThemeState({
    required this.brandKey,
    required this.themes,
    required this.mode,
  });

  final String brandKey; // toyota | lexus
  final Map<String, AppBrand> themes;
  final ThemeMode mode;

  AppBrand get brand =>
      themes[brandKey] ?? kFallbackBrands[brandKey] ?? kFallbackBrands['toyota']!;

  ThemeState copyWith({
    String? brandKey,
    Map<String, AppBrand>? themes,
    ThemeMode? mode,
  }) =>
      ThemeState(
        brandKey: brandKey ?? this.brandKey,
        themes: themes ?? this.themes,
        mode: mode ?? this.mode,
      );

  @override
  List<Object?> get props => [brandKey, themes, mode];
}
