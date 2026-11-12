import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/paged_list_view.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../models/area.dart';
import '../../models/donor.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meta_provider.dart';
import '../../services/donor_service.dart';
import '../requests/create_request_screen.dart';
import '../shared/area_picker_sheet.dart';
import 'donor_profile_screen.dart';
import 'widgets/donor_tile.dart';

/// Search donors who can give blood now, by blood group and area.
class FindDonorsScreen extends StatefulWidget {
  const FindDonorsScreen({super.key});

  @override
  State<FindDonorsScreen> createState() => _FindDonorsScreenState();
}

class _FindDonorsScreenState extends State<FindDonorsScreen> {
  Area? _area;
  int? _bloodGroupId;
  int? _total;

  @override
  void initState() {
    super.initState();
    // Start with the user's own area and blood group.
    final user = context.read<AuthProvider>().user;
    _area = user?.area;
    _bloodGroupId = user?.bloodGroup?.id;
    context.read<MetaProvider>().load();
  }

  Future<void> _pickArea() async {
    final area = await showAreaPicker(context);
    if (area != null) {
      setState(() {
        _area = area;
        _total = null;
      });
    }
  }

  void _pickGroup(int id) {
    setState(() {
      _bloodGroupId = id;
      _total = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<MetaProvider>().bloodGroups;
    final canRequest = context.watch<AuthProvider>().user?.isConsumer ?? false;
    final service = context.read<DonorService>();
    final area = _area;
    final groupId = _bloodGroupId;

    return Scaffold(
      appBar: AppBar(title: Text(tr('nav.find'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppCard(
              onTap: _pickArea,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, color: AppColors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('field.area'), style: AppFonts.body(size: 13, color: AppColors.muted)),
                        Text(
                          area?.label ?? tr('register.pick_area'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.body(weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    tr('common.change'),
                    style: AppFonts.body(size: 14, weight: FontWeight.w600, color: AppColors.red),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                for (final g in groups)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SelectChip(
                      label: g.name,
                      latin: true,
                      selected: g.id == groupId,
                      onTap: () => _pickGroup(g.id),
                    ),
                  ),
              ],
            ),
          ),
          if (_total != null && area != null && groupId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('donors.found', {'n': localizeDigits(_total!)}),
                  style: AppFonts.body(weight: FontWeight.w700),
                ),
              ),
            ),
          Expanded(
            child: area == null || groupId == null
                ? Center(
                    child: Text(tr('donors.pick_first'), style: AppFonts.body(color: AppColors.muted)),
                  )
                : PagedListView<Donor>(
                    key: ValueKey('${area.id}-$groupId'),
                    fetch: (page) => service.search(bloodGroupId: groupId, areaId: area.id, page: page),
                    onFirstPage: (page) => setState(() => _total = page.total),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    spacing: 10,
                    emptyIcon: Icons.person_search_outlined,
                    emptyTitle: tr('donors.empty'),
                    emptyMessage: canRequest ? tr('donors.empty_text') : null,
                    itemBuilder: (context, donor) => DonorTile(
                      donor: donor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => DonorProfileScreen(donorId: donor.id)),
                      ),
                    ),
                  ),
          ),
          if (canRequest && area != null && groupId != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: AppButton(
                  label: tr('donors.send_request'),
                  icon: Icons.send_outlined,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CreateRequestScreen(bloodGroupId: groupId, area: area),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
