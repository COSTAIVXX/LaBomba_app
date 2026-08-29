import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'sections/animated_banner.dart';
import 'sections/countdown_section.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AnimatedBanner(),
                          const SizedBox(height: 24),
                          const CountdownSection(),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pushNamed(context, '/login'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Entrar',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pushNamed(context, '/register'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryLight,
                                    foregroundColor: const Color(0xFF0B1020),
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Criar conta',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/admin/login'),
                              child: const Text(
                                'Administrador',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                            child: const Text(
                              'Revisar guia da festa',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/terms'),
                          child: const Text(
                            'Termos de Uso',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/privacy'),
                          child: const Text(
                            'Política de Privacidade',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedCarnivalBackground extends StatelessWidget {
  const AnimatedCarnivalBackground({
    required this.pointerOffset,
    required this.child,
    super.key,
  });

  final Offset pointerOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CarnivalBackgroundPainter(pointerOffset),
      child: child,
    );
  }
}

class _CarnivalBackgroundPainter extends CustomPainter {
  const _CarnivalBackgroundPainter(this.pointerOffset);

  final Offset pointerOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2 + (pointerOffset.dx - size.width / 2) * 0.03,
      size.height / 2 + (pointerOffset.dy - size.height / 2) * 0.03,
    );
    final radius = (size.width > size.height ? size.width : size.height) * 0.8;
    final gradient = RadialGradient(
      colors: [Colors.deepPurple.shade900, Colors.black],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawRect(Offset.zero & size, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(covariant _CarnivalBackgroundPainter oldDelegate) =>
      oldDelegate.pointerOffset != pointerOffset;
}
