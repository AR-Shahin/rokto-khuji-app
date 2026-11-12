import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Label on top, rounded input below (design guide: 52 dp high, 14 dp radius).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.icon,
    this.helper,
    this.errorText,
    this.isRequired = false,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.suffix,
    this.onTap,
    this.onChanged,
    this.validator,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final String? helper;

  /// Error from the API for this field (shown under the input).
  final String? errorText;
  final bool isRequired;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: 1.5),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          style: AppFonts.body(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppFonts.body(color: AppColors.muted),
            helperText: helper,
            helperStyle: AppFonts.body(size: 12.5, color: AppColors.muted),
            helperMaxLines: 2,
            errorText: errorText,
            errorStyle: AppFonts.body(size: 12.5, color: AppColors.redDark),
            errorMaxLines: 2,
            prefixIcon: icon == null ? null : Icon(icon, size: 20, color: AppColors.muted),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: border(AppColors.border),
            enabledBorder: border(AppColors.border),
            focusedBorder: border(AppColors.red),
            errorBorder: border(AppColors.redDark),
            focusedErrorBorder: border(AppColors.redDark),
          ),
        ),
      ],
    );
  }
}

/// Small bold label used above inputs and pickers.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.isRequired = false});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: AppFonts.body(size: 14, weight: FontWeight.w600, color: AppColors.ink2),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.red),
            ),
        ],
      ),
    );
  }
}

/// A field that opens a picker instead of the keyboard (date, time, area).
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
    this.icon,
    this.errorText,
    this.isRequired = false,
  });

  final String label;

  /// Text of the chosen value, or null when nothing is chosen.
  final String? value;
  final VoidCallback onTap;
  final String? hint;
  final IconData? icon;
  final String? errorText;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: hasError ? AppColors.redDark : AppColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                if (icon != null) ...[Icon(icon, size: 20, color: AppColors.muted), const SizedBox(width: 12)],
                Expanded(
                  child: Text(
                    value ?? hint ?? '',
                    style: AppFonts.body(color: value == null ? AppColors.muted : AppColors.text),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 14),
            child: Text(errorText!, style: AppFonts.body(size: 12.5, color: AppColors.redDark)),
          ),
      ],
    );
  }
}
