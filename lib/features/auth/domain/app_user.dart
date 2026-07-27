import 'package:equatable/equatable.dart';

/// The signed-in user — wire-identical to the website backend's UserDto,
/// persisted to SharedPreferences the way the website keeps it in localStorage.
final class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.guid,
    required this.userId,
    this.firstNameAr,
    this.lastNameAr,
    this.firstNameEn,
    this.lastNameEn,
    this.email,
    this.phone,
    this.custId,
    this.phoneNumberConfirmed = false,
    this.emailConfirmed = false,
  });

  final String id; // "<guid>_<userId>"
  final String guid;
  final int userId;
  final String? firstNameAr;
  final String? lastNameAr;
  final String? firstNameEn;
  final String? lastNameEn;
  final String? email;
  final String? phone;
  final String? custId;
  final bool phoneNumberConfirmed;
  final bool emailConfirmed;

  String displayName(String lang) {
    final first = (lang == 'ar' ? firstNameAr : firstNameEn) ?? firstNameEn ?? firstNameAr;
    final last = (lang == 'ar' ? lastNameAr : lastNameEn) ?? lastNameEn ?? lastNameAr;
    return [first, last].whereType<String>().join(' ').trim();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? '',
        guid: json['guid'] as String? ?? '',
        userId: (json['userId'] as num?)?.toInt() ?? 0,
        firstNameAr: json['firstNameAr'] as String?,
        lastNameAr: json['lastNameAr'] as String?,
        firstNameEn: json['firstNameEn'] as String?,
        lastNameEn: json['lastNameEn'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        custId: json['custId'] as String?,
        phoneNumberConfirmed: json['phoneNumberConfirmed'] as bool? ?? false,
        emailConfirmed: json['emailConfirmed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'guid': guid,
        'userId': userId,
        'firstNameAr': firstNameAr,
        'lastNameAr': lastNameAr,
        'firstNameEn': firstNameEn,
        'lastNameEn': lastNameEn,
        'email': email,
        'phone': phone,
        'custId': custId,
        'phoneNumberConfirmed': phoneNumberConfirmed,
        'emailConfirmed': emailConfirmed,
      };

  @override
  List<Object?> get props => [id];
}
