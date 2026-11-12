import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/l10n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/home/home_shell.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/meta_provider.dart';

/// Lets code outside the widget tree reset navigation (logout, language change).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class RoktoKhujiApp extends StatelessWidget {
  const RoktoKhujiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: tr('app.name'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: locale,
      supportedLocales: const [Locale('bn'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AppRoot(),
    );
  }
}

/// Rebuilds every screen from the start. Called after the language changes
/// so all texts are drawn again in the new language.
void restartNavigation() {
  appNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const AppRoot()),
    (_) => false,
  );
}

/// Decides the first screen: splash, welcome (guest) or the app (logged in).
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    _auth.addListener(_onAuthChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_auth.status == AuthStatus.unknown) _auth.bootstrap();
      context.read<MetaProvider>().load();
    });
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// When the session ends, close every open screen so only Welcome is left.
  void _onAuthChanged() {
    if (_auth.status == AuthStatus.guest) {
      appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.unknown => const SplashScreen(),
      AuthStatus.offline => SplashScreen(onRetry: _auth.bootstrap),
      AuthStatus.guest => const WelcomeScreen(),
      AuthStatus.loggedIn => const HomeShell(),
    };
  }
}
