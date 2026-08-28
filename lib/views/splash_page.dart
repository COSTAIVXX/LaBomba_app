import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  final StorageService storageService;

  const SplashPage({super.key, required this.storageService});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _continue();
  }

  Future<void> _continue() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final accepted = await widget.storageService.read(key: 'terms_accepted');
    final onboarding =
        await widget.storageService.read(key: 'onboarding_completed');
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      accepted != '1'
          ? '/'
          : onboarding == '1'
              ? '/landing'
              : '/onboarding',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, Color(0xFF102A72)],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOutBack,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.white54,
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 58,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'LA BOMBA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A folia começa aqui',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 34),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
