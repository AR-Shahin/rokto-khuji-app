import 'blood_request.dart';
import 'json.dart';
import 'user.dart';

/// Everything the Home screen needs, from one call (GET /dashboard).
class Dashboard {
  const Dashboard({
    required this.user,
    required this.overdue,
    required this.newRequests,
    required this.unreadNotifications,
  });

  factory Dashboard.fromJson(Json json) {
    return Dashboard(
      user: User.fromJson(asJson(json['user']) ?? const {}),
      overdue: OverdueDonations.fromJson(asJson(json['overdue']) ?? const {}),
      newRequests: asList(json['new_requests'], BloodRequest.fromJson),
      unreadNotifications: asInt(json['unread_notifications']),
    );
  }

  final User user;
  final OverdueDonations overdue;
  final List<BloodRequest> newRequests;
  final int unreadNotifications;
}

/// Accepted donations whose time has passed but nobody completed or cancelled.
class OverdueDonations {
  const OverdueDonations({required this.total, required this.asDonor, required this.asRequester});

  factory OverdueDonations.fromJson(Json json) {
    return OverdueDonations(
      total: asInt(json['total']),
      asDonor: asList(json['as_donor'], BloodRequest.fromJson),
      asRequester: asList(json['as_requester'], BloodRequest.fromJson),
    );
  }

  final int total;
  final List<BloodRequest> asDonor;
  final List<BloodRequest> asRequester;

  List<BloodRequest> get all => [...asDonor, ...asRequester];
}
