part of 'onboarding_cubit.dart';

final class OnboardingState extends Equatable {
  const OnboardingState({required this.slides, this.index = 0});

  final List<OnboardingSlide> slides;
  final int index;

  bool get isLast => index >= slides.length - 1;

  OnboardingState copyWith({List<OnboardingSlide>? slides, int? index}) =>
      OnboardingState(slides: slides ?? this.slides, index: index ?? this.index);

  @override
  List<Object?> get props => [slides, index];
}
