import 'package:material_ui/material_ui.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Red start screen. With [onRetry] it shows "no internet, try again"
/// (a token is saved but the server could not be reached).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.red,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.water_drop, size: 56, color: AppColors.red),
                ),
                const SizedBox(height: 20),
                Text(
                  tr('app.name'),
                  style: AppFonts.heading(size: 34, weight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(tr('app.tagline'), style: AppFonts.body(size: 17, color: Colors.white)),
                const SizedBox(height: 32),
                if (onRetry == null)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                  )
                else ...[
                  Text(
                    tr('error.no_internet'),
                    textAlign: TextAlign.center,
                    style: AppFonts.body(size: 15, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: Text(
                      tr('common.retry'),
                      style: AppFonts.body(weight: FontWeight.w600, color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
