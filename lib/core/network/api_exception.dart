/// Any failed API call ends up as this one exception type,
/// so screens only need `on ApiException catch (e)`.
class ApiException implements Exception {
  const ApiException({required this.message, this.code, this.statusCode, this.errors = const {}});

  /// Text that is safe to show to the user.
  final String message;

  /// Machine code from the API, e.g. `email_not_verified`, `business_rule`.
  final String? code;
  final int? statusCode;

  /// Validation errors: field name -> first message.
  final Map<String, String> errors;

  bool get isNetwork => code == 'network';
  bool get isUnauthenticated => statusCode == 401;
  bool get isEmailNotVerified => code == 'email_not_verified';

  @override
  String toString() => message;
}
