import 'dart:math';
import 'package:flutter/material.dart';

import 'sections/header_section.dart';
import 'sections/animated_banner.dart';
import 'sections/countdown_section.dart';
import 'sections/ticket_section.dart';
import 'sections/event_info_section.dart';
import 'sections/gallery_section.dart';
import 'sections/rules_section.dart';
import 'sections/footer_section.dart';
import 'package:labomba_app/widgets/user_appbar_actions.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ValueNotifier<Offset> _pointerPositionNotifier =
      ValueNotifier<Offset>(Offset.zero);

  @override
  void dispose() {
    _pointerPositionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final contentMaxWidth = isCompact ? 560.0 : 850.0;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                tooltip: 'Abrir navegação',
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text(
              'LABOMBA 2027',
              style: labombaTextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: isCompact ? 2 : 4,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Configurações',
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
              const SizedBox(width: 8),
              // User info and quick actions (includes profile/admin access)
              UserAppBarActions(),
            ],
          ),
          body: Listener(
            onPointerHover: (event) {
              _pointerPositionNotifier.value = event.position;
            },
            onPointerMove: (event) {
              _pointerPositionNotifier.value = event.position;
            },
            child: ValueListenableBuilder<Offset>(
              valueListenable: _pointerPositionNotifier,
              builder: (context, pointerOffset, child) {
                return AnimatedCarnivalBackground(
                  pointerOffset: pointerOffset,
                  child: child!,
                );
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: contentMaxWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isCompact ? 16 : 20,
                        isCompact ? 90 : 120,
                        isCompact ? 16 : 20,
                        60,
                      ),
                      child: Column(
                        children: [
                          AnimatedBanner(),
                          const SizedBox(height: 24),
                          // Prominent Memories button
                          SizedBox(
                            width: isCompact ? double.infinity : 320,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/memories'),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Memórias'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          SizedBox(height: 26),
                          HeaderSection(),
                          SizedBox(height: 50),
                          EventInfoSection(),
                          SizedBox(height: 50),
                          CountdownSection(),
                          SizedBox(height: 80),
                          GallerySection(),
                          SizedBox(height: 80),
                          TicketSection(),
                          SizedBox(height: 50),
                          RulesSection(),
                          SizedBox(height: 80),
                          FooterSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    final radius = max(size.width, size.height) * 0.8;
    final gradient = RadialGradient(
      colors: [Colors.deepPurple.shade900, Colors.black],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawRect(Offset.zero & size, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(covariant _CarnivalBackgroundPainter oldDelegate) =>
      oldDelegate.pointerOffset != pointerOffset;
}
