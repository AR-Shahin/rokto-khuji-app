import 'json.dart';

class Testimonial {
  const Testimonial({required this.id, required this.content, required this.status});

  factory Testimonial.fromJson(Json json) {
    return Testimonial(
      id: asInt(json['id']),
      content: asString(json['content']) ?? '',
      status: asString(json['status']) ?? 'pending',
    );
  }

  final int id;
  final String content;

  /// pending / approved
  final String status;

  bool get isApproved => status == 'approved';
}
