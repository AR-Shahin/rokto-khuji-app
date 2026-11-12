import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/donor.dart';
import '../models/json.dart';
import '../models/paged.dart';
import '../models/review.dart';

class DonorDetails {
  const DonorDetails({required this.donor, required this.recentReviews});

  final Donor donor;
  final List<Review> recentReviews;
}

class DonorService {
  const DonorService(this._api);

  final ApiClient _api;

  /// Donors who can donate now in the area and all its sub-areas.
  Future<Paged<Donor>> search({required int bloodGroupId, required int areaId, int page = 1}) async {
    final result = await _api.get(
      '/donors',
      query: {'blood_group_id': bloodGroupId, 'area_id': areaId, 'page': page, 'per_page': AppConfig.pageSize},
    );
    return Paged.fromApi(result.list, result.meta, Donor.fromJson);
  }

  Future<DonorDetails> details(int id) async {
    final data = (await _api.get('/donors/$id')).map;
    return DonorDetails(
      donor: Donor.fromJson(asJson(data['donor']) ?? const {}),
      recentReviews: asList(data['recent_reviews'], Review.fromJson),
    );
  }
}
