import 'json.dart';
import 'user.dart';

class Review {
  const Review({required this.id, required this.rating, this.remarks, this.reviewer, this.patientName, this.createdAt});

  factory Review.fromJson(Json json) {
    final reviewer = asJson(json['reviewer']);
    return Review(
      id: asInt(json['id']),
      rating: asInt(json['rating']),
      remarks: asString(json['remarks']),
      reviewer: reviewer == null ? null : UserSummary.fromJson(reviewer),
      patientName: asString(asJson(json['blood_request'])?['patient_name']),
      createdAt: asDate(json['created_at']),
    );
  }

  final int id;
  final int rating;
  final String? remarks;
  final UserSummary? reviewer;
  final String? patientName;
  final DateTime? createdAt;
}

/// Totals shown at the top of "My reviews" (comes in `meta.summary`).
class ReviewSummary {
  const ReviewSummary({
    required this.total,
    required this.distribution,
    required this.asDonorCount,
    required this.asRequesterCount,
    this.average,
  });

  factory ReviewSummary.fromJson(Json json) {
    final raw = asJson(json['distribution']) ?? const {};
    return ReviewSummary(
      average: asDouble(json['average']),
      total: asInt(json['total']),
      distribution: {for (var star = 5; star >= 1; star--) star: asInt(raw['$star'])},
      asDonorCount: asInt(json['as_donor_count']),
      asRequesterCount: asInt(json['as_requester_count']),
    );
  }

  final double? average;
  final int total;

  /// star (5..1) -> number of reviews
  final Map<int, int> distribution;
  final int asDonorCount;
  final int asRequesterCount;
}
