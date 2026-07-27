import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/domain/app_user.dart';
import '../data/protection_repository.dart';
import '../domain/protection_models.dart';

enum ProtectionBookingPhase { editing, busy, done, failed }

final class ProtectionBookingState extends Equatable {
  const ProtectionBookingState({
    this.phase = ProtectionBookingPhase.editing,
    this.branches = const [],
    this.branchId,
    this.date,
    this.hours = const [],
    this.hoursLoading = false,
    this.hour,
    this.error = false,
  });

  final ProtectionBookingPhase phase;
  final List<MaintBranch> branches;
  final String? branchId;
  final DateTime? date;
  final List<String> hours;
  final bool hoursLoading;
  final String? hour;
  final bool error;

  ProtectionBookingState copyWith({
    ProtectionBookingPhase? phase,
    List<MaintBranch>? branches,
    String? Function()? branchId,
    DateTime? Function()? date,
    List<String>? hours,
    bool? hoursLoading,
    String? Function()? hour,
    bool? error,
  }) =>
      ProtectionBookingState(
        phase: phase ?? this.phase,
        branches: branches ?? this.branches,
        branchId: branchId == null ? this.branchId : branchId(),
        date: date == null ? this.date : date(),
        hours: hours ?? this.hours,
        hoursLoading: hoursLoading ?? this.hoursLoading,
        hour: hour == null ? this.hour : hour(),
        error: error ?? this.error,
      );

  @override
  List<Object?> get props =>
      [phase, branches, branchId, date, hours, hoursLoading, hour, error];
}

/// Books a protection package through the website's ERP flow
/// (POST /maintenance/bookings → App_ServiceRequestAdd): branch, date, live
/// hour grid, contact from the signed-in account.
final class ProtectionBookingCubit extends Cubit<ProtectionBookingState> {
  ProtectionBookingCubit({
    required ProtectionRepository repo,
    required this.package,
    required this.model,
    required this.groupId,
    required this.brandDbId,
    required this.user,
    required String lang,
  })  : _repo = repo,
        super(const ProtectionBookingState()) {
    firstName.text = (lang == 'ar'
            ? user?.firstNameAr ?? user?.firstNameEn
            : user?.firstNameEn ?? user?.firstNameAr) ??
        '';
    lastName.text = (lang == 'ar'
            ? user?.lastNameAr ?? user?.lastNameEn
            : user?.lastNameEn ?? user?.lastNameAr) ??
        '';
    phone.text = user?.phone ?? '';
    email.text = user?.email ?? '';
    _load();
  }

  final ProtectionRepository _repo;
  final ProtectionPackage package;
  final MaintModel model;
  final String? groupId;
  final String brandDbId;
  final AppUser? user;

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final meter = TextEditingController();
  final vin = TextEditingController();
  final note = TextEditingController();

  Future<void> _load() async {
    final branches = await _repo.branches();
    if (isClosed) return;
    emit(state.copyWith(
      branches: branches,
      branchId: () => branches.length == 1 ? branches.first.id : null,
    ));
  }

  void selectBranch(String? id) => emit(state.copyWith(branchId: () => id));

  Future<void> selectDate(DateTime date) async {
    emit(state.copyWith(
        date: () => date, hour: () => null, hoursLoading: true));
    final hours = await _repo.hours(date);
    if (isClosed) return;
    emit(state.copyWith(hours: hours, hoursLoading: false));
  }

  void selectHour(String? h) => emit(state.copyWith(hour: () => h));

  String _fullPhone(String raw) {
    var p = raw.trim().replaceAll(RegExp(r'\s'), '');
    if (p.startsWith('+')) return p;
    if (p.startsWith('00')) return '+${p.substring(2)}';
    if (p.startsWith('0')) p = p.substring(1);
    return '+966$p';
  }

  Future<bool> submit() async {
    final ok = firstName.text.trim().isNotEmpty &&
        phone.text.trim().length >= 8 &&
        state.date != null &&
        (state.hour ?? '').isNotEmpty &&
        (state.branchId ?? '').isNotEmpty;
    if (!ok) {
      emit(state.copyWith(error: true));
      return false;
    }
    emit(state.copyWith(phase: ProtectionBookingPhase.busy, error: false));
    final d = state.date!;
    final hour = state.hour!;
    final booked = await _repo.book({
      'serviceId': package.id,
      'serviceNameEn': package.nameEn,
      'brandId': brandDbId,
      'groupId': groupId,
      'productTypeId': model.id,
      'year': model.year,
      'vin': vin.text.trim().isEmpty ? null : vin.text.trim(),
      'siteId': state.branchId,
      'orderdate':
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      'orderTime': hour.length == 5 ? '$hour:00' : hour,
      'firstName': firstName.text.trim(),
      'lastName': lastName.text.trim(),
      'phone': _fullPhone(phone.text),
      'email': email.text.trim().isEmpty ? null : email.text.trim(),
      'meterReading': int.tryParse(meter.text.trim()),
      'note': note.text.trim().isEmpty ? null : note.text.trim(),
      // CustID (not Web_UserID) — App_ServiceRequestAdd resolves the customer
      // and the ops email carries name+phone, like the website.
      'userId': user?.custId,
    });
    if (isClosed) return booked;
    emit(state.copyWith(
        phase:
            booked ? ProtectionBookingPhase.done : ProtectionBookingPhase.failed));
    return booked;
  }

  @override
  Future<void> close() {
    for (final c in [firstName, lastName, phone, email, meter, vin, note]) {
      c.dispose();
    }
    return super.close();
  }
}
