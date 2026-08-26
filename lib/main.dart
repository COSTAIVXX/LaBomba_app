import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// NOVO: Import do armazenamento seguro
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

// Views e Páginas do Aplicativo
import 'views/landing_page.dart';
import 'views/client_registration_page.dart';
import 'views/admin/admin_login_page.dart';
import 'views/admin/admin_dashboard_page.dart';
import 'views/admin/client_base_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Erro ao inicializar o Firebase: $e');
  }

  // Initialize observability (Analytics, Crashlytics)
  try {
    await ObservabilityService.init();

    // Route Flutter framework errors to Crashlytics
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // Report to Crashlytics
      try {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      } catch (_) {}
    };
  } catch (e) {
    debugPrint('Observability init failed: $e');
  }

  // Initialize Google Sign-In singleton once at app bootstrap to avoid double initialization
  try {
    await GoogleSignIn.instance.initialize();
  } catch (e) {
    debugPrint('GoogleSignIn initialization failed: $e');
  }

  // 1. Instancia o armazenamento seguro nativo (O Cofre)
  const secureStorage = FlutterSecureStorage();

  // 2. Injeta o armazenamento dentro do nosso Repositório
  final clientRepository = SecureClientRepository(secureStorage);

  // 3. Inicia o App injetando o repositório configurado dentro de runZonedGuarded
  runZonedGuarded(() {
    runApp(LaBombaApp(repository: clientRepository));
  }, (Object error, StackTrace stack) {
    // Report uncaught errors to Crashlytics as fatal
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {}
  });
}

class LaBombaApp extends StatelessWidget {
  // Recebe o repositório criado lá no main()
  final IClientRepository repository;

  // Exige o repositório no construtor
  const LaBombaApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Central AuthService provided first so other providers can consume it
        Provider<AuthService>(create: (_) => AuthService()),

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
          create: (_) => EventConfigProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'La Bomba 2027',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const LandingPage(),
          '/register': (context) => const ClientRegistrationPage(),
          '/admin/login': (context) => const AdminLoginPage(),
          '/admin/dashboard': (context) => const AdminDashboardPage(),
          '/admin/clients': (context) => const ClientBasePage(),
        },
      ),
    );
  }
}