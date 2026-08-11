import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/maintenance_hub_repository.dart';
import '../domain/maintenance_hub_models.dart';

enum PeriodicStatus { loading, ready, error }

final class MaintenanceHubState extends Equatable {
  const MaintenanceHubState({
    this.status = PeriodicStatus.loading,
    this.details = const [],
    this.notes = const [],
    this.testimonials = const [],
    this.tabIndex = 0,
    this.openSection = 0,
  });

  final PeriodicStatus status;
  final List<PeriodicRow> details;
  final List<PeriodicRow> notes;
  final List<Testimonial> testimonials;

  /// Selected km tab (index into [details]).
  final int tabIndex;

  /// The one expanded panel of the active tab (-1 = all collapsed).
  final int openSection;

  PeriodicRow? get activeTab =>
      tabIndex >= 0 && tabIndex < details.length ? details[tabIndex] : null;

  MaintenanceHubState copyWith({
    PeriodicStatus? status,
    List<PeriodicRow>? details,
    List<PeriodicRow>? notes,
    List<Testimonial>? testimonials,
    int? tabIndex,
    int? openSection,
  }) =>
      MaintenanceHubState(
        status: status ?? this.status,
        details: details ?? this.details,
        notes: notes ?? this.notes,
        testimonials: testimonials ?? this.testimonials,
        tabIndex: tabIndex ?? this.tabIndex,
        openSection: openSection ?? this.openSection,
      );

  @override
  List<Object?> get props =>
      [status, details, notes, testimonials, tabIndex, openSection];
}

/// Loads the periodic schedule + guest testimonials in parallel. Testimonial
/// failures never fail the screen — the feedback pager just hides.
final class MaintenanceHubCubit extends Cubit<MaintenanceHubState> {
  MaintenanceHubCubit(this._repo) : super(const MaintenanceHubState()) {
    load();
  }

  final MaintenanceHubRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: PeriodicStatus.loading));
    final results =
        await Future.wait([_repo.periodic(), _repo.testimonials()]);
    if (isClosed) return;
    final periodic = results[0] as PeriodicData?;
    final reviews = results[1] as List<Testimonial>;
    if (periodic == null) {
      emit(state.copyWith(
          status: PeriodicStatus.error, testimonials: reviews));
      return;
    }
    emit(state.copyWith(
      status: PeriodicStatus.ready,
      details: periodic.details,
      notes: periodic.notes,
      testimonials: reviews,
      tabIndex: 0,
      openSection: 0,
    ));
  }

  /// Switching tabs resets the accordion to its first panel (website parity).
  void selectTab(int i) => emit(state.copyWith(tabIndex: i, openSection: 0));

  void toggleSection(int i) =>
      emit(state.copyWith(openSection: state.openSection == i ? -1 : i));
}
