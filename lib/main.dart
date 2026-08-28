import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

import 'services/storage_service.dart';
import 'services/storage_platform.dart';

import 'features/memories/services/storage_memory_service.dart';

import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'services/observability_service.dart';
import 'services/auth_service.dart';
import 'services/street_mode_service.dart';

import 'theme/app_theme.dart';

import 'providers/admin_auth_provider.dart' as admin_provider;
import 'providers/client_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/google_auth_provider.dart';
import 'providers/event_config_provider.dart';

import 'features/memories/memories_module.dart';
import 'features/memories/views/block_gallery_page.dart';

import 'features/chat/providers/chat_provider.dart';
import 'features/chat/views/chat_page.dart';

import 'views/landing_page.dart';
import 'views/client_registration_page.dart';
import 'views/admin/admin_login_page.dart';
import 'views/admin/admin_dashboard_page.dart';
import 'views/admin/client_base_page.dart';
import 'views/terms_page.dart';
import 'views/privacy_page.dart';
import 'views/settings_page.dart';
import 'providers/theme_provider.dart';
import 'views/user_profile_page.dart';
import 'views/notifications_page.dart';
import 'views/onboarding_page.dart';
import 'views/settings_hub_page.dart';
import 'views/privacy_data_management_page.dart';
import 'views/sound_alerts_settings_page.dart';
import 'views/street_mode_settings_page.dart';
import 'views/about_and_terms_page.dart';
import 'views/admin/admin_moderation_page.dart';
import 'views/badge_generator_page.dart';
import 'views/foliao_directory_page.dart';
import 'views/splash_page.dart';
import 'widgets/member_access_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ObservabilityService.logEvent('app_starting');

  try {
    await ObservabilityService.logEvent('firebase_initialization_start');
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await ObservabilityService.logEvent('firebase_initialization_success');
  } catch (e, s) {
    debugPrint('Erro ao inicializar o Firebase: $e');
    // Report initialization error to Crashlytics/Observability if available
    try {
      await ObservabilityService.reportError(e, s, reason: 'Main.firebaseInitialize');
      await ObservabilityService.logEvent('firebase_initialization_failure', parameters: {'error': e.toString()});
    } catch (_) {}
  }

  // Initialize observability (Analytics, Crashlytics)
  try {
    await ObservabilityService.logEvent('observability_init_start');
    await ObservabilityService.init();

    // Route Flutter framework errors to Crashlytics
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // Report to Crashlytics
      try {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      } catch (_) {}
    };
    await ObservabilityService.logEvent('observability_init_success');
  } catch (e, s) {
    debugPrint('Observability init failed: $e');
    try {
      await ObservabilityService.reportError(e, s, reason: 'Main.observabilityInit');
    } catch (_) {}
  }

  // Initialize Google Sign-In singleton once at app bootstrap to avoid double initialization
  try {
    await ObservabilityService.logEvent('google_signin_init_start');
    await GoogleSignIn.instance.initialize();
    await ObservabilityService.logEvent('google_signin_init_success');
  } catch (e, s) {
    debugPrint('GoogleSignIn initialization failed: $e');
    try {
      await ObservabilityService.reportError(e, s, reason: 'Main.googleSignInInit');
    } catch (_) {}
  }

  final secureStorage = PlatformStorageService();
  await ObservabilityService.logEvent('secure_storage_created');

  final clientRepository = SecureClientRepository(secureStorage);
  await ObservabilityService.logEvent('client_repository_created');

  runZonedGuarded(() {
      runApp(LaBombaApp(repository: clientRepository, storageService: secureStorage));
  }, (Object error, StackTrace stack) async {
    // Report uncaught errors to Crashlytics as fatal
    try {
      await ObservabilityService.reportError(error, stack, reason: 'Main.uncaughtError');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {}
  });
}


class LaBombaApp extends StatelessWidget {
  // Recebe o repositório criado lá no main()
  final IClientRepository repository;
  final StorageService storageService;

  // Exige o repositório e storage no construtor
  const LaBombaApp({super.key, required this.repository, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Central AuthService provided first so other providers can consume it
        Provider<AuthService>(create: (_) => AuthService()),
        // Expose configured StorageService so pages/services can read/write persistent flags (e.g., terms acceptance)
        Provider<StorageService>(create: (_) => storageService),

        ChangeNotifierProvider(
          create: (context) => admin_provider.AdminAuthProvider(authService: context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          // 4. Injeta o repositório pronto para o ClientProvider usar!
          create: (_) => ClientProvider(repository: repository),
        ),
        ChangeNotifierProvider(
          create: (_) => ShopProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => GoogleAuthProvider(authService: context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => EventConfigProvider(authService: context.read<AuthService>()),
        ),
        // Memories provider (storage-backed)
        ChangeNotifierProvider(
          create: (context) => MemoryProvider(service: StorageMemoryService(storageService)),
        ),
        // Chat provider (real-time)
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
        // Theme provider (observes persisted preference)
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => StreetModeService(storageService),
        ),
      ],
      child: Consumer<ThemeProvider>(builder: (context, themeProv, _) {
        return MaterialApp(
          title: 'La Bomba 2027',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProv.themeMode,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) =>
                SplashPage(storageService: storageService),
            '/': (context) => TermsGate(storageService: storageService),
            '/landing': (context) => const LandingPage(),
            '/register': (context) => const ClientRegistrationPage(),
            '/admin/login': (context) => const AdminLoginPage(),
            '/admin/dashboard': (context) => const AdminDashboardPage(),
            '/admin/clients': (context) => const ClientBasePage(),
            '/memories': (context) => const MemberAccessGate(
                  child: MemoriesListPage(),
                ),
            '/gallery': (context) => const MemberAccessGate(
                  child: BlockGalleryPage(),
                ),
            '/chat': (context) => MemberAccessGate(
                  child: ChatPage(
                  privateUserId:
                      ModalRoute.of(context)?.settings.arguments as String?,
                ),
            ),
            '/foliaos': (context) => const MemberAccessGate(
                  child: FoliaoDirectoryPage(),
                ),
            '/settings': (context) => const MemberAccessGate(child: SettingsHubPage()),
            '/settings/profile': (context) => const MemberAccessGate(child: SettingsPage()),
            '/settings/theme': (context) => const MemberAccessGate(child: SettingsThemePage()),
            '/settings/privacy': (context) => const MemberAccessGate(child: SettingsPrivacyPage()),
            '/settings/privacy/data': (context) => const MemberAccessGate(child: PrivacyDataManagementPage()),
            '/settings/sound-alerts': (context) => const MemberAccessGate(child: SoundAlertsSettingsPage()),
            '/settings/street-mode': (context) => const MemberAccessGate(child: StreetModeSettingsPage()),
            '/about': (context) => const AboutAndTermsPage(),
            '/profile': (context) => const MemberAccessGate(
                  child: UserProfilePage(),
                ),
            '/notifications': (context) => const MemberAccessGate(
                  child: NotificationsPage(),
                ),
            '/onboarding': (context) =>
                OnboardingPage(storageService: storageService),
            '/admin/moderation': (context) => const AdminModerationPage(),
            '/badge': (context) => const BadgeGeneratorPage(),
            '/terms': (context) => TermsPage(storageService: storageService),
            '/privacy': (context) => const PrivacyPage(),
          },
        );
      }),
    );
  }
}