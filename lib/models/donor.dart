import 'area.dart';
import 'json.dart';

/// A donor in search results and on the donor profile screen.
class Donor {
  const Donor({
    required this.id,
    required this.name,
    required this.isVerified,
    required this.isAvailable,
    required this.totalDonations,
    required this.reviewCount,
    this.photoUrl,
    this.bloodGroup,
    this.area,
    this.gender,
    this.age,
    this.lastDonationDate,
    this.rating,
    this.phone,
    this.whatsappNumber,
  });

  factory Donor.fromJson(Json json) {
    final area = asJson(json['area']);
    final rating = asJson(json['rating']) ?? const {};
    final contact = asJson(json['contact']) ?? const {};

    return Donor(
      id: asInt(json['id']),
      name: asString(json['name']) ?? '',
      photoUrl: asString(json['profile_photo_url']),
      bloodGroup: asString(asJson(json['blood_group'])?['name']),
      area: area == null ? null : Area.fromJson(area),
      gender: asString(json['gender']),
      age: json['age'] == null ? null : asInt(json['age']),
      isVerified: asBool(json['is_verified']),
      isAvailable: asBool(json['is_available']),
      lastDonationDate: asDate(json['last_donation_date']),
      totalDonations: asInt(json['total_donations']),
      rating: asDouble(rating['average']),
      reviewCount: asInt(rating['count']),
      phone: asString(contact['phone']),
      whatsappNumber: asString(contact['whatsapp_number']),
    );
  }

  final int id;
  final String name;
  final String? photoUrl;
  final String? bloodGroup;
  final Area? area;
  final String? gender;
  final int? age;
  final bool isVerified;
  final bool isAvailable;
  final DateTime? lastDonationDate;
  final int totalDonations;

  /// Null when the donor has no reviews yet.
  final double? rating;
  final int reviewCount;
  final String? phone;
  final String? whatsappNumber;
}
