import 'area.dart';
import 'json.dart';
import 'user.dart';

/// A blood request. The same object is used for "sent to me" and "my requests".
class BloodRequest {
  const BloodRequest({
    required this.id,
    required this.patientName,
    required this.hospitalName,
    required this.bags,
    required this.status,
    required this.statusLabel,
    required this.priority,
    required this.priorityLabel,
    required this.isOverdue,
    required this.isMine,
    required this.acceptedCount,
    required this.completedCount,
    required this.notifiedCount,
    required this.escalationLevel,
    required this.escalationExhausted,
    required this.reviewedRequester,
    this.location,
    this.contactNumber,
    this.reason,
    this.note,
    this.bloodGroup,
    this.area,
    this.neededAt,
    this.hasTime = false,
    this.searchArea,
    this.requester,
    this.myStatus,
    this.targets = const [],
    this.createdAt,
  });

  factory BloodRequest.fromJson(Json json) {
    final status = asJson(json['status']) ?? const {};
    final priority = asJson(json['priority']) ?? const {};
    final counts = asJson(json['counts']) ?? const {};
    final escalation = asJson(json['escalation']) ?? const {};
    final myResponse = asJson(json['my_response']);
    final area = asJson(json['area']);
    final searchArea = asJson(escalation['search_area']);
    final requester = asJson(json['requester']);

    return BloodRequest(
      id: asInt(json['id']),
      patientName: asString(json['patient_name']) ?? '',
      hospitalName: asString(json['hospital_name']) ?? '',
      location: asString(json['location']),
      contactNumber: asString(json['contact_number']),
      reason: asString(json['reason']),
      note: asString(json['note']),
      bags: asInt(json['bags'], 1),
      bloodGroup: asString(asJson(json['blood_group'])?['name']),
      area: area == null ? null : Area.fromJson(area),
      status: asString(status['value']) ?? 'pending',
      statusLabel: asString(status['label']) ?? '',
      priority: asString(priority['value']) ?? 'regular',
      priorityLabel: asString(priority['label']) ?? '',
      neededAt: asDate(json['needed_at']) ?? asDate(json['needed_date']),
      hasTime: json['needed_time'] != null,
      isOverdue: asBool(json['is_overdue']),
      acceptedCount: asInt(counts['accepted']),
      completedCount: asInt(counts['completed']),
      notifiedCount: asInt(counts['notified']),
      escalationLevel: asInt(escalation['level']),
      searchArea: searchArea == null ? null : Area.fromJson(searchArea),
      escalationExhausted: asBool(escalation['exhausted']),
      isMine: asBool(json['is_mine']),
      requester: requester == null ? null : UserSummary.fromJson(requester),
      myStatus: asString(myResponse?['status']),
      reviewedRequester: asBool(myResponse?['reviewed_requester']),
      targets: asList(json['targets'], RequestTarget.fromJson),
      createdAt: asDate(json['created_at']),
    );
  }

  final int id;
  final String patientName;
  final String hospitalName;
  final String? location;
  final String? contactNumber;
  final String? reason;
  final String? note;
  final int bags;
  final String? bloodGroup;
  final Area? area;

  /// pending -> resolved -> closed, or canceled
  final String status;
  final String statusLabel;

  /// regular / urgent / critical
  final String priority;
  final String priorityLabel;

  final DateTime? neededAt;
  final bool hasTime;
  final bool isOverdue;

  final int acceptedCount;
  final int completedCount;
  final int notifiedCount;

  /// 0 = not widened yet. Above 0 the search moved to a bigger area.
  final int escalationLevel;
  final Area? searchArea;
  final bool escalationExhausted;

  final bool isMine;
  final UserSummary? requester;

  /// My answer as a donor: pending / accepted / declined / completed. Null for my own requests.
  final String? myStatus;
  final bool reviewedRequester;

  /// Every donor's answer. Only filled for the requester on the detail screen.
  final List<RequestTarget> targets;
  final DateTime? createdAt;

  bool get isActive => status == 'pending' || status == 'resolved';

  /// Donors who said yes (accepted or already completed).
  List<RequestTarget> get confirmedTargets {
    return targets.where((t) => t.status == 'accepted' || t.status == 'completed').toList();
  }
}

/// One donor's answer to a request.
class RequestTarget {
  const RequestTarget({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.reviewed,
    this.donor,
  });

  factory RequestTarget.fromJson(Json json) {
    final donor = asJson(json['donor']);
    return RequestTarget(
      id: asInt(json['id']),
      status: asString(json['status']) ?? 'pending',
      statusLabel: asString(json['status_label']) ?? '',
      reviewed: asBool(json['reviewed']),
      donor: donor == null ? null : UserSummary.fromJson(donor),
    );
  }

  final int id;
  final String status;
  final String statusLabel;

  /// True when the requester already rated this donor.
  final bool reviewed;
  final UserSummary? donor;
}
