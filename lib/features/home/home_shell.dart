import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../donors/find_donors_screen.dart';
import '../profile/profile_screen.dart';
import '../requests/create_request_screen.dart';
import '../requests/requests_screen.dart';
import 'home_screen.dart';

/// Main screen after login: 4 tabs + the red "+ Request" button in the middle.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  /// Tabs are built the first time they are opened, so the app does not
  /// call every API at start-up.
  final Set<int> _opened = {0};

  /// Changing this key rebuilds the Home tab, so it loads fresh data.
  Key _homeKey = UniqueKey();

  void _openTab(int index) {
    setState(() {
      if (index == 0 && _tab == 0) _homeKey = UniqueKey();
      _tab = index;
      _opened.add(index);
    });
  }

  Future<void> _createRequest() async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CreateRequestScreen()));
    if (mounted) setState(() => _homeKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canRequest = user?.isConsumer ?? true;

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(key: _homeKey, onOpenTab: _openTab),
          _opened.contains(1) ? const FindDonorsScreen() : const SizedBox.shrink(),
          _opened.contains(2) ? const RequestsScreen() : const SizedBox.shrink(),
          _opened.contains(3) ? const ProfileScreen() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        showRequestButton: canRequest,
        onTab: _openTab,
        onRequest: _createRequest,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.current,
    required this.showRequestButton,
    required this.onTab,
    required this.onRequest,
  });

  final int current;
  final bool showRequestButton;
  final ValueChanged<int> onTab;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.home_outlined, Icons.home, tr('nav.home'), 0),
      _NavItem(Icons.search, Icons.search, tr('nav.find'), 1),
      _NavItem(Icons.inbox_outlined, Icons.inbox, tr('nav.requests'), 2),
      _NavItem(Icons.person_outline, Icons.person, tr('nav.profile'), 3),
    ];

    Widget tab(_NavItem item) {
      final active = item.index == current;
      final color = active ? AppColors.red : AppColors.muted;
      return Expanded(
        child: InkWell(
          onTap: () => onTab(item.index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 30,
                decoration: BoxDecoration(
                  color: active ? AppColors.redTint : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(active ? item.activeIcon : item.icon, size: 22, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.body(size: 12, weight: active ? FontWeight.w600 : FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              tab(items[0]),
              tab(items[1]),
              if (showRequestButton) Expanded(child: _RequestButton(onTap: onRequest)),
              tab(items[2]),
              tab(items[3]),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label, this.index);

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
}

class _RequestButton extends StatelessWidget {
  const _RequestButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tr('request.new'),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: AppColors.redShadow, blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: const Icon(Icons.add, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 3),
            Text(
              tr('nav.request'),
              style: AppFonts.body(size: 12, weight: FontWeight.w600, color: AppColors.red),
            ),
          ],
        ),
      ),
    );
  }
}
