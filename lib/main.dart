import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

// Storage service (platform implementations)
import 'services/storage_service.dart';
import 'services/storage_platform.dart';

// Memories storage-backed service
import 'features/memories/services/storage_memory_service.dart';

import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'services/observability_service.dart';
import 'services/auth_service.dart';

// Configurações e Temas
import 'theme/app_theme.dart';

// NOVO: Adicione o import de onde você salvou a interface e a classe do repositório
// import 'repositories/client_repository.dart'; // <-- Descomente e ajuste o caminho da pasta!

// Providers com apelido (prefixo) para evitar conflitos de nome
import 'providers/admin_auth_provider.dart' as admin_provider;
import 'providers/client_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/google_auth_provider.dart';
import 'providers/event_config_provider.dart';

// Memories feature
import 'features/memories/memories_module.dart';

// Chat feature (views/providers)
import 'features/chat/providers/chat_provider.dart';
import 'features/chat/views/chat_page.dart';

// Views e Páginas do Aplicativo
import 'views/landing_page.dart';
import 'views/client_registration_page.dart';
import 'views/admin/admin_login_page.dart';
import 'views/admin/admin_dashboard_page.dart';
import 'views/admin/client_base_page.dart';
import 'views/terms_page.dart';
import 'views/settings_page.dart';
import 'providers/theme_provider.dart';
import 'views/user_profile_page.dart';
import 'views/notifications_page.dart';
import 'views/onboarding_page.dart';
import 'views/settings_hub_page.dart';
import 'views/admin/admin_moderation_page.dart';
import 'views/badge_generator_page.dart';
import 'views/foliao_directory_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('main: after WidgetsFlutterBinding.ensureInitialized');
  await ObservabilityService.logEvent('app_starting');

  try {
    debugPrint('main: initializing Firebase...');
    await ObservabilityService.logEvent('firebase_initialization_start');
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint('main: firebase initialized');
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
    debugPrint('main: initializing ObservabilityService');
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
    debugPrint('main: ObservabilityService initialized');
    await ObservabilityService.logEvent('observability_init_success');
  } catch (e, s) {
    debugPrint('Observability init failed: $e');
    try {
      await ObservabilityService.reportError(e, s, reason: 'Main.observabilityInit');
    } catch (_) {}
  }

  // Initialize Google Sign-In singleton once at app bootstrap to avoid double initialization
  try {
    debugPrint('main: initializing GoogleSignIn');
    await ObservabilityService.logEvent('google_signin_init_start');
    await GoogleSignIn.instance.initialize();
    debugPrint('main: GoogleSignIn initialized');
    await ObservabilityService.logEvent('google_signin_init_success');
  } catch (e, s) {
    debugPrint('GoogleSignIn initialization failed: $e');
    try {
      await ObservabilityService.reportError(e, s, reason: 'Main.googleSignInInit');
    } catch (_) {}
  }

  // 1. Instancia o armazenamento seguro nativo (O Cofre)
  debugPrint('main: creating secure storage');
  final secureStorage = PlatformStorageService();
  await ObservabilityService.logEvent('secure_storage_created');

  // 2. Injeta o armazenamento dentro do nosso Repositório
  debugPrint('main: creating client repository');
  final clientRepository = SecureClientRepository(secureStorage);
  await ObservabilityService.logEvent('client_repository_created');

  // 3. Inicia o App injetando o repositório configurado dentro de runZonedGuarded
  debugPrint('main: entering runZonedGuarded');
  runZonedGuarded(() {
    debugPrint('main: before runApp');
      runApp(LaBombaApp(repository: clientRepository, storageService: secureStorage));
    debugPrint('main: runApp completed');
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
      ],
      child: Consumer<ThemeProvider>(builder: (context, themeProv, _) {
        return MaterialApp(
          title: 'La Bomba 2027',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProv.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => TermsGate(storageService: storageService),
            '/landing': (context) => const LandingPage(),
            '/register': (context) => const ClientRegistrationPage(),
            '/admin/login': (context) => const AdminLoginPage(),
            '/admin/dashboard': (context) => const AdminDashboardPage(),
            '/admin/clients': (context) => const ClientBasePage(),
            // Memories route
            '/memories': (context) => const MemoriesListPage(),
            '/chat': (context) => ChatPage(
                  privateUserId:
                      ModalRoute.of(context)?.settings.arguments as String?,
                ),
            '/foliaos': (context) => const FoliaoDirectoryPage(),
            '/settings': (context) => const SettingsHubPage(),
            '/settings/profile': (context) => const SettingsPage(),
            '/settings/theme': (context) => const SettingsThemePage(),
            '/settings/privacy': (context) => const SettingsPrivacyPage(),
            '/profile': (context) => const UserProfilePage(),
            '/notifications': (context) => const NotificationsPage(),
            '/onboarding': (context) =>
                OnboardingPage(storageService: storageService),
            '/admin/moderation': (context) => const AdminModerationPage(),
            '/badge': (context) => const BadgeGeneratorPage(),
            '/terms': (context) => TermsPage(storageService: storageService),
          },
        );
      }),
    );
  }
}