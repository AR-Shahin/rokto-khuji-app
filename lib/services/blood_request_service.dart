import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/utils/formatters.dart';
import '../models/blood_request.dart';
import '../models/json.dart';
import '../models/paged.dart';

class CreatedRequest {
  const CreatedRequest({required this.request, required this.notifiedDonors});

  final BloodRequest request;
  final int notifiedDonors;
}

/// Result of an action on a request: the fresh request and a message to show.
class RequestUpdate {
  const RequestUpdate({required this.request, this.message});

  final BloodRequest request;
  final String? message;
}

class BloodRequestService {
  const BloodRequestService(this._api);

  final ApiClient _api;

  // ---- Shared --------------------------------------------------------------

  Future<BloodRequest> details(int id) async {
    final result = await _api.get('/blood-requests/$id');
    return BloodRequest.fromJson(result.map);
  }

  // ---- As requester ----------------------------------------------------------

  Future<CreatedRequest> create(Json body) async {
    final data = (await _api.post('/blood-requests', body: body)).map;
    return CreatedRequest(
      request: BloodRequest.fromJson(asJson(data['blood_request']) ?? const {}),
      notifiedDonors: asInt(data['notified_donors']),
    );
  }

  /// [status]: active / closed / canceled
  Future<Paged<BloodRequest>> mine({required String status, int page = 1}) async {
    final result = await _api.get(
      '/me/blood-requests',
      query: {'status': status, 'page': page, 'per_page': AppConfig.pageSize},
    );
    return Paged.fromApi(result.list, result.meta, BloodRequest.fromJson);
  }

  Future<RequestUpdate> cancel(int id) async {
    return _update(await _api.post('/blood-requests/$id/cancel'));
  }

  /// [donorIds] = donors who really donated (may be empty).
  Future<RequestUpdate> close(int id, {required DateTime donationDate, required List<int> donorIds}) async {
    return _update(
      await _api.post(
        '/blood-requests/$id/close',
        body: {'donation_date': apiDate(donationDate), 'donor_ids': donorIds},
      ),
    );
  }

  Future<String?> reviewDonor(int id, int donorId, {required int rating, String? remarks}) async {
    final result = await _api.post(
      '/blood-requests/$id/donors/$donorId/review',
      body: {'rating': rating, 'remarks': remarks},
    );
    return result.message;
  }

  // ---- As donor ---------------------------------------------------------------

  /// [status]: pending / accepted / completed / declined (null = all)
  Future<Paged<BloodRequest>> incoming({String? status, int page = 1}) async {
    final result = await _api.get(
      '/me/incoming-requests',
      query: {'status': status, 'page': page, 'per_page': AppConfig.pageSize},
    );
    return Paged.fromApi(result.list, result.meta, BloodRequest.fromJson);
  }

  /// Declining after accepting cancels the acceptance.
  Future<RequestUpdate> respond(int id, {required bool accept}) async {
    return _update(await _api.post('/blood-requests/$id/respond', body: {'status': accept ? 'accepted' : 'declined'}));
  }

  Future<RequestUpdate> complete(int id, {required DateTime donationDate, required bool didDonate}) async {
    return _update(
      await _api.post(
        '/blood-requests/$id/complete',
        body: {'donation_date': apiDate(donationDate), 'did_donate': didDonate},
      ),
    );
  }

  Future<String?> reviewRequester(int id, {required int rating, String? remarks}) async {
    final result = await _api.post(
      '/blood-requests/$id/requester-review',
      body: {'rating': rating, 'remarks': remarks},
    );
    return result.message;
  }

  RequestUpdate _update(ApiResult result) {
    return RequestUpdate(request: BloodRequest.fromJson(result.map), message: result.message);
  }
}
