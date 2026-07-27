import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/local_store.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_slide.dart';

part 'onboarding_state.dart';

/// Owns the slides + the PageController so every widget stays stateless.
final class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._repo, this._store, {required String brandKey})
      : super(const OnboardingState(slides: kDefaultSlides)) {
    _load(brandKey);
  }

  final OnboardingRepository _repo;
  final LocalStore _store;
  final PageController pageController = PageController();

  Future<void> _load(String brandKey) async {
    final slides = await _repo.fetch(brandKey);
    if (!isClosed) emit(state.copyWith(slides: slides));
  }

  void onPageChanged(int index) => emit(state.copyWith(index: index));

  void next() {
    if (state.index >= state.slides.length - 1) return;
    pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  /// Persist the "seen" flag so the router never shows onboarding again.
  Future<void> complete() => _store.setOnboardingDone();

  @override
  Future<void> close() {
    pageController.dispose();
    return super.close();
  }
}
