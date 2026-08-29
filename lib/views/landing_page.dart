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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnimatedBanner(),
                const SizedBox(height: 24),
                const CountdownSection(),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/memories'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Acessar Memórias',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/admin/login'),
                    child: const Text(
                      'Acesso Admin',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
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
              ],
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
