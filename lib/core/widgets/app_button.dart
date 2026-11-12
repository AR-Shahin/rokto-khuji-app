import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppButtonKind { primary, outline, neutral, success, tonal, ghost }

/// The one button used in the whole app (design guide: 52 dp high, fully rounded).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AppButtonKind.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final IconData? icon;

  /// Shows a spinner and blocks taps while a request is running.
  final bool loading;

  /// Full width when true.
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, Color? border) = switch (kind) {
      AppButtonKind.primary => (AppColors.red, Colors.white, null),
      AppButtonKind.outline => (Colors.white, AppColors.red, AppColors.red),
      AppButtonKind.neutral => (Colors.white, AppColors.text, AppColors.border),
      AppButtonKind.success => (AppColors.green, Colors.white, null),
      AppButtonKind.tonal => (AppColors.redTint, AppColors.redDark, null),
      AppButtonKind.ghost => (Colors.transparent, AppColors.red, null),
    };

    final content = loading
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: foreground), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(size: 16, weight: FontWeight.w600, color: foreground),
                ),
              ),
            ],
          );

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background,
        disabledForegroundColor: foreground,
        elevation: 0,
        minimumSize: Size(0, height),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: StadiumBorder(side: border == null ? BorderSide.none : BorderSide(color: border, width: 1.5)),
      ),
      child: content,
    );

    final disabled = onPressed == null && !loading;
    final sized = expand ? SizedBox(width: double.infinity, child: button) : button;
    return disabled ? Opacity(opacity: 0.5, child: sized) : sized;
  }
}
