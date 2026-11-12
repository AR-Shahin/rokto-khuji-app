import 'area.dart';
import 'blood_group.dart';
import 'json.dart';

/// The logged-in user (GET /me).
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.role,
    required this.isDonor,
    required this.isConsumer,
    required this.isAvailable,
    required this.canDonateNow,
    required this.totalDonations,
    required this.ratingAsDonor,
    required this.ratingAsRequester,
    required this.profileCompletion,
    required this.missingFields,
    required this.telegramLinked,
    this.phone,
    this.secondaryPhone,
    this.whatsappNumber,
    this.telegramNumber,
    this.bloodGroup,
    this.area,
    this.gender,
    this.dateOfBirth,
    this.photoUrl,
    this.lastDonationDate,
    this.nextDonationDate,
    this.badge,
    this.telegramConnectUrl,
    this.social = const {},
  });

  factory User.fromJson(Json json) {
    final role = asJson(json['role']) ?? const {};
    final donation = asJson(json['donation']) ?? const {};
    final rating = asJson(json['rating']) ?? const {};
    final completion = asJson(json['profile_completion']) ?? const {};
    final telegram = asJson(json['telegram']) ?? const {};
    final bloodGroup = asJson(json['blood_group']);
    final area = asJson(json['area']);
    final missing = completion['missing'];

    return User(
      id: asInt(json['id']),
      name: asString(json['name']) ?? '',
      email: asString(json['email']) ?? '',
      emailVerified: asBool(json['email_verified']),
      phone: asString(json['phone']),
      secondaryPhone: asString(json['secondary_phone']),
      whatsappNumber: asString(json['whatsapp_number']),
      telegramNumber: asString(json['telegram_number']),
      role: asString(role['value']) ?? 'both',
      isDonor: asBool(role['is_donor']),
      isConsumer: asBool(role['is_consumer']),
      bloodGroup: bloodGroup == null ? null : BloodGroup.fromJson(bloodGroup),
      area: area == null ? null : Area.fromJson(area),
      gender: asString(json['gender']),
      dateOfBirth: asDate(json['date_of_birth']),
      photoUrl: asString(json['profile_photo_url']),
      isAvailable: asBool(donation['is_available']),
      lastDonationDate: asDate(donation['last_donation_date']),
      nextDonationDate: asDate(donation['next_donation_date']),
      canDonateNow: asBool(donation['can_donate_now']),
      totalDonations: asInt(donation['total_donations']),
      badge: asString(donation['badge']),
      ratingAsDonor: asDouble(rating['as_donor']) ?? 0,
      ratingAsRequester: asDouble(rating['as_requester']) ?? 0,
      profileCompletion: asInt(completion['percentage']),
      missingFields: missing is List ? missing.map((item) => item.toString()).toList() : const [],
      telegramLinked: asBool(telegram['linked']),
      telegramConnectUrl: asString(telegram['connect_url']),
      social: asJson(json['social']) ?? const {},
    );
  }

  final int id;
  final String name;
  final String email;
  final bool emailVerified;
  final String? phone;
  final String? secondaryPhone;
  final String? whatsappNumber;
  final String? telegramNumber;

  /// donor / consumer / both
  final String role;
  final bool isDonor;
  final bool isConsumer;

  final BloodGroup? bloodGroup;
  final Area? area;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? photoUrl;

  final bool isAvailable;
  final DateTime? lastDonationDate;
  final DateTime? nextDonationDate;
  final bool canDonateNow;
  final int totalDonations;
  final String? badge;

  final double ratingAsDonor;
  final double ratingAsRequester;

  final int profileCompletion;
  final List<String> missingFields;

  final bool telegramLinked;
  final String? telegramConnectUrl;

  /// bio, facebook, instagram, twitter, linkedin, youtube, website
  final Json social;
}

/// Short user info that comes inside requests, reviews and donor lists.
class UserSummary {
  const UserSummary({required this.id, required this.name, this.phone, this.photoUrl, this.bloodGroup});

  factory UserSummary.fromJson(Json json) {
    return UserSummary(
      id: asInt(json['id']),
      name: asString(json['name']) ?? '',
      phone: asString(json['phone']),
      photoUrl: asString(json['profile_photo_url']),
      bloodGroup: asString(json['blood_group']),
    );
  }

  final int id;
  final String name;
  final String? phone;
  final String? photoUrl;
  final String? bloodGroup;
}
