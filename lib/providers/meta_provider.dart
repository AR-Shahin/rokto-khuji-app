import 'package:flutter/foundation.dart';

import '../models/blood_group.dart';
import '../services/meta_service.dart';

/// Blood groups are needed on many screens, so they are loaded once and kept.
class MetaProvider extends ChangeNotifier {
  MetaProvider(this._service);

  final MetaService _service;

  List<BloodGroup> bloodGroups = const [];
  bool isLoading = false;

  /// The last load failure (no internet, server down, wrong API address...).
  Object? error;

  bool get isReady => bloodGroups.isNotEmpty;

  /// Safe to call many times: it only hits the API until the data is there.
  Future<void> load() async {
    if (isReady || isLoading) return;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      bloodGroups = await _service.bloodGroups();
    } catch (e) {
      error = e;
      debugPrint('MetaProvider: could not load blood groups: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
