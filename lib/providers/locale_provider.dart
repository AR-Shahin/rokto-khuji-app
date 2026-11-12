import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n/app_strings.dart';

/// Remembers the chosen language (Bangla by default).
class LocaleProvider extends ChangeNotifier {
  static const String _key = 'language_code';

  Locale get locale => Locale(AppStrings.languageCode);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && AppStrings.supported.contains(saved)) {
      AppStrings.languageCode = saved;
    }
  }

  Future<void> change(String languageCode) async {
    if (languageCode == AppStrings.languageCode) return;
    AppStrings.languageCode = languageCode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
  }
}
