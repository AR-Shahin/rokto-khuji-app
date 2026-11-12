import 'strings_bn.dart';
import 'strings_en.dart';

/// Very small translation layer: two maps (Bangla, English) and one function.
///
/// Use it anywhere, no BuildContext needed:
///   tr('login.title')
///   tr('donors.found', {'n': 24})
///
/// To add a text: add the same key to `strings_bn.dart` and `strings_en.dart`.
class AppStrings {
  const AppStrings._();

  static const List<String> supported = ['bn', 'en'];

  /// Current language. Changed through `LocaleProvider`.
  static String languageCode = 'bn';

  static String get(String key, [Map<String, Object?> args = const {}]) {
    final table = languageCode == 'en' ? stringsEn : stringsBn;
    var text = table[key] ?? stringsBn[key] ?? key;
    args.forEach((name, value) => text = text.replaceAll('{$name}', '$value'));
    return text;
  }
}

/// Shortcut for [AppStrings.get].
String tr(String key, [Map<String, Object?> args = const {}]) => AppStrings.get(key, args);
