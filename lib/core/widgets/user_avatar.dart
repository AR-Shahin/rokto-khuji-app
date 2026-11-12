import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Profile photo, or the name's initials on a colored circle when there is no photo.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.photoUrl, this.size = 44});

  final String name;
  final String? photoUrl;
  final double size;

  static const List<Color> _colors = [
    AppColors.blue,
    Color(0xFF7B3FA0),
    Color(0xFF0F7B6C),
    Color(0xFFB5541C),
    AppColors.red,
  ];

  @override
  Widget build(BuildContext context) {
    // Same name -> same color every time.
    final color = _colors[name.hashCode.abs() % _colors.length];

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initials(name),
        style: AppFonts.heading(size: size * 0.38, color: Colors.white),
      ),
    );

    final url = photoUrl;
    if (url == null || url.isEmpty) return fallback;

    return ClipOval(
      child: Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback),
    );
  }
}
