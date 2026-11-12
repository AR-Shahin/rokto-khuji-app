import 'json.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.isRead,
    this.title,
    this.body,
    this.bloodRequestId,
    this.createdAt,
  });

  factory AppNotification.fromJson(Json json) {
    return AppNotification(
      id: json['id'].toString(),
      type: asString(json['type']) ?? '',
      title: asString(json['title']),
      body: asString(json['body']),
      bloodRequestId: json['blood_request_id'] == null ? null : asInt(json['blood_request_id']),
      isRead: asBool(json['is_read']),
      createdAt: asDate(json['created_at']),
    );
  }

  final String id;

  /// new_blood_request, donor_accepted, donation_overdue, search_widened, search_exhausted ...
  final String type;
  final String? title;
  final String? body;
  final int? bloodRequestId;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification markedRead() {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      bloodRequestId: bloodRequestId,
      isRead: true,
      createdAt: createdAt,
    );
  }
}
