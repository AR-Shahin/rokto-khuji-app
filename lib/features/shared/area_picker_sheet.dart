import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/state_views.dart';
import '../../models/area.dart';
import '../../services/meta_service.dart';

/// Opens the area picker. Returns the chosen area, or null when closed.
///
/// The user can either search by name or go down level by level
/// (division > district > upazila > union ...).
Future<Area?> showAreaPicker(BuildContext context) {
  return showModalBottomSheet<Area>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      // Move up with the keyboard while searching.
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: const FractionallySizedBox(heightFactor: 0.9, child: _AreaPicker()),
    ),
  );
}

class _AreaPicker extends StatefulWidget {
  const _AreaPicker();

  @override
  State<_AreaPicker> createState() => _AreaPickerState();
}

class _AreaPickerState extends State<_AreaPicker> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  /// Levels opened so far, e.g. [Chattogram, Chandpur, Kachua].
  final List<Area> _path = [];
  late Future<List<Area>> _areas;

  bool get _isSearching => _search.text.trim().length >= 2;

  @override
  void initState() {
    super.initState();
    _areas = _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<List<Area>> _load() {
    final service = context.read<MetaService>();
    if (_isSearching) return service.searchAreas(_search.text.trim());
    return service.areas(parentId: _path.isEmpty ? null : _path.last.id);
  }

  void _reload() {
    setState(() {
      _areas = _load();
    });
  }

  /// Wait until the user stops typing before calling the API.
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _reload);
  }

  void _open(Area area) {
    _path.add(area);
    _reload();
  }

  void _goToLevel(int count) {
    _path.removeRange(count, _path.length);
    _reload();
  }

  void _select(Area area) {
    if (area.breadcrumb != null) {
      Navigator.pop(context, area);
      return;
    }
    // Build "Palakhal, Kachua, Chandpur" from the opened levels.
    final names = [..._path.map((a) => a.name), if (_path.isEmpty || _path.last.id != area.id) area.name];
    Navigator.pop(context, area.withBreadcrumb(names.reversed.join(', ')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
          child: Row(
            children: [
              Expanded(child: Text(tr('area.pick'), style: AppFonts.heading(size: 21))),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                tooltip: tr('common.close'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            style: AppFonts.body(),
            decoration: InputDecoration(
              hintText: tr('area.search_hint'),
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        if (!_isSearching && _path.isNotEmpty) _breadcrumb(),
        Expanded(
          child: FutureView<List<Area>>(
            future: _areas,
            onRetry: _reload,
            builder: (context, areas) {
              if (areas.isEmpty) {
                return MessageView(icon: Icons.place_outlined, title: tr('area.empty'), iconColor: AppColors.muted);
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: areas.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, index) => _row(areas[index]),
              );
            },
          ),
        ),
        if (!_isSearching && _path.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: AppButton(
              label: tr('area.select_whole', {'name': _path.last.name}),
              onPressed: () => _select(_path.last),
            ),
          ),
      ],
    );
  }

  Widget _breadcrumb() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          ActionChip(label: Text(tr('area.all')), onPressed: () => _goToLevel(0)),
          for (var i = 0; i < _path.length; i++) ...[
            const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
            ActionChip(label: Text(_path[i].name), onPressed: () => _goToLevel(i + 1)),
          ],
        ],
      ),
    );
  }

  Widget _row(Area area) {
    // Search results are final choices; while browsing, a row with children opens the next level.
    final opensNextLevel = !_isSearching && area.hasChildren;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(area.name, style: AppFonts.body(weight: FontWeight.w600)),
      subtitle: area.breadcrumb == null
          ? null
          : Text(area.breadcrumb!, style: AppFonts.body(size: 13, color: AppColors.muted)),
      trailing: opensNextLevel ? const Icon(Icons.chevron_right, color: AppColors.muted) : null,
      onTap: () => opensNextLevel ? _open(area) : _select(area),
    );
  }
}
