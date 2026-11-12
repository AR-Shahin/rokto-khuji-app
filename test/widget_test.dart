import 'package:flutter_test/flutter_test.dart';
import 'package:rokto_khuji_app/core/l10n/app_strings.dart';
import 'package:rokto_khuji_app/core/utils/formatters.dart';

void main() {
  test('Bangla is the default language', () {
    expect(AppStrings.languageCode, 'bn');
    expect(tr('app.name'), 'রক্ত খুঁজি');
  });

  test('digits follow the language', () {
    AppStrings.languageCode = 'bn';
    expect(localizeDigits('24'), '২৪');
    AppStrings.languageCode = 'en';
    expect(localizeDigits('24'), '24');
    AppStrings.languageCode = 'bn';
  });

  test('initials use the first letters of the name', () {
    expect(initials('Rakib Hasan'), 'RH');
    expect(initials(''), '?');
  });
}
