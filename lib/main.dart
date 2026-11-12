import 'package:material_ui/material_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/meta_provider.dart';
import 'services/auth_service.dart';
import 'services/blood_request_service.dart';
import 'services/dashboard_service.dart';
import 'services/donor_service.dart';
import 'services/meta_service.dart';
import 'services/notification_service.dart';
import 'services/profile_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  final localeProvider = LocaleProvider();
  await localeProvider.load();

  // One API client for the whole app; every service uses it.
  final tokenStorage = TokenStorage();
  final api = ApiClient(tokenStorage: tokenStorage);
  final authService = AuthService(api);
  final metaService = MetaService(api);

  runApp(
    MultiProvider(
      providers: [
        // Services: screens get them with context.read<DonorService>().
        Provider<AuthService>.value(value: authService),
        Provider<MetaService>.value(value: metaService),
        Provider<DashboardService>(create: (_) => DashboardService(api)),
        Provider<DonorService>(create: (_) => DonorService(api)),
        Provider<BloodRequestService>(create: (_) => BloodRequestService(api)),
        Provider<NotificationService>(create: (_) => NotificationService(api)),
        Provider<ProfileService>(create: (_) => ProfileService(api)),

        // App-wide state.
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService: authService, tokenStorage: tokenStorage, apiClient: api),
        ),
        ChangeNotifierProvider<MetaProvider>(create: (_) => MetaProvider(metaService)),
      ],
      child: const RoktoKhujiApp(),
    ),
  );
}
