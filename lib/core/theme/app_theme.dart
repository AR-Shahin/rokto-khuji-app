import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles from the design guide.
/// heading = Anek Bangla, body = Hind Siliguri, latin = Space Grotesk (blood groups).
class AppFonts {
  const AppFonts._();

  static TextStyle heading({double size = 18, FontWeight weight = FontWeight.w700, Color color = AppColors.text}) {
    return GoogleFonts.anekBangla(fontSize: size, fontWeight: weight, color: color, height: 1.25);
  }

  static TextStyle body({double size = 16, FontWeight weight = FontWeight.w400, Color color = AppColors.text}) {
    return GoogleFonts.hindSiliguri(fontSize: size, fontWeight: weight, color: color, height: 1.4);
  }

  static TextStyle latin({double size = 15, FontWeight weight = FontWeight.w700, Color color = AppColors.text}) {
    return GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: weight, color: color);
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.red,
      primary: AppColors.red,
      onPrimary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.text,
      error: AppColors.redDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.hindSiliguriTextTheme().apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      dividerColor: AppColors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: AppFonts.heading(size: 21),
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: AppFonts.body(size: 15, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      ),
    );
  }
}
