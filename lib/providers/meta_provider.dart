import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/blood_group.dart';
import '../services/meta_service.dart';

/// Blood groups are needed on many screens, so they are loaded once and kept.
class MetaProvider extends ChangeNotifier {
  MetaProvider(this._service);

  final MetaService _service;

  List<BloodGroup> bloodGroups = const [];
  bool _loading = false;

  bool get isReady => bloodGroups.isNotEmpty;

  /// Safe to call many times: it only hits the API until the data is there.
  Future<void> load() async {
    if (isReady || _loading) return;
    _loading = true;
    try {
      bloodGroups = await _service.bloodGroups();
      notifyListeners();
    } on ApiException {
      // Stay empty. Screens call load() again when they open.
    } finally {
      _loading = false;
    }
  }
}
