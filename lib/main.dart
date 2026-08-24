import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Configurações e Temas
import 'theme/app_theme.dart';

// Providers com apelido (prefixo) para evitar conflitos de nome
import 'providers/admin_auth_provider.dart' as admin_provider;
import 'providers/client_provider.dart';
import 'providers/shop_provider.dart';

// Views e Páginas do Aplicativo
import 'views/landing_page.dart';
import 'views/client_registration_page.dart';
import 'views/admin/admin_login_page.dart';
import 'views/admin/client_base_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LaBombaApp());
}

class LaBombaApp extends StatelessWidget {
  const LaBombaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => admin_provider.AdminAuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ClientProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ShopProvider(),
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
          '/admin/dashboard': (context) => const ClientBasePage(),
          '/admin/clients': (context) => const ClientBasePage(),
        },
      ),
    );
  }
}
