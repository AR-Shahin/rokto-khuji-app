import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../l10n/app_strings.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// What every successful call returns: `{ data, message, meta }`.
class ApiResult {
  const ApiResult({this.data, this.message, this.meta = const {}});

  final dynamic data;
  final String? message;
  final Map<String, dynamic> meta;

  /// `data` as an object. Empty map when the API sent nothing.
  Map<String, dynamic> get map {
    final value = data;
    return value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
  }

  /// `data` as a list. Empty list when the API sent nothing.
  List<dynamic> get list {
    final value = data;
    return value is List ? value : const [];
  }
}

/// The only class that talks HTTP. It adds the token and language to each
/// request and turns every failure into an [ApiException].
class ApiClient {
  ApiClient({required TokenStorage tokenStorage, Dio? dio})
    : _tokens = tokenStorage,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.requestTimeout,
              receiveTimeout: AppConfig.requestTimeout,
              sendTimeout: AppConfig.requestTimeout,
              headers: {'Accept': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _addHeaders));
  }

  final TokenStorage _tokens;
  final Dio _dio;

  /// Called when the server says the token is no longer valid (401).
  void Function()? onUnauthorized;

  Future<ApiResult> get(String path, {Map<String, dynamic>? query}) {
    return _send(() => _dio.get<dynamic>(path, queryParameters: _clean(query)));
  }

  Future<ApiResult> post(String path, {Object? body}) {
    return _send(() => _dio.post<dynamic>(path, data: body));
  }

  Future<ApiResult> put(String path, {Object? body}) {
    return _send(() => _dio.put<dynamic>(path, data: body));
  }

  Future<ApiResult> patch(String path, {Object? body}) {
    return _send(() => _dio.patch<dynamic>(path, data: body));
  }

  Future<ApiResult> delete(String path, {Object? body}) {
    return _send(() => _dio.delete<dynamic>(path, data: body));
  }

  /// multipart/form-data upload of one file.
  Future<ApiResult> upload(String path, {required String field, required String filePath}) {
    return _send(() async {
      final form = FormData.fromMap({field: await MultipartFile.fromFile(filePath)});
      return _dio.post<dynamic>(path, data: form);
    });
  }

  Future<void> _addHeaders(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept-Language'] = AppStrings.languageCode;
    handler.next(options);
  }

  Future<ApiResult> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is Map) {
        final meta = body['meta'];
        return ApiResult(
          data: body['data'],
          message: body['message']?.toString(),
          meta: meta is Map ? meta.cast<String, dynamic>() : const {},
        );
      }
      return ApiResult(data: body);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException(message: tr('error.network'), code: 'network');
    }

    final body = response.data;
    final status = response.statusCode;
    String? message;
    String? code;
    final errors = <String, String>{};

    if (body is Map) {
      message = body['message']?.toString();
      code = body['code']?.toString();
      final rawErrors = body['errors'];
      if (rawErrors is Map) {
        rawErrors.forEach((field, value) {
          final first = value is List && value.isNotEmpty ? value.first : value;
          if (first != null) errors[field.toString()] = first.toString();
        });
      }
    }

    if (status == 401 && e.requestOptions.headers.containsKey('Authorization')) {
      onUnauthorized?.call();
    }

    return ApiException(message: message ?? tr('error.generic'), code: code, statusCode: status, errors: errors);
  }

  /// Drops null and empty values so they are not sent as `?key=`.
  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final cleaned = Map<String, dynamic>.of(query);
    cleaned.removeWhere((_, value) => value == null || value == '');
    return cleaned;
  }
}
