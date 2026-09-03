import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/event_config_provider.dart';
import '../providers/shop_provider.dart';
import 'sections/header_section.dart';
import 'sections/animated_banner.dart';
import 'sections/event_info_section.dart';
import 'sections/neon_info_components.dart';
import 'sections/footer_section.dart';
import 'sections/abadahistory_section.dart';
import 'sections/purchase_section.dart';
import 'sections/rules_section.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // Admin/Provider integration will toggle this value when availability changes.
  bool isWarningActive = false;
  final ValueNotifier<Offset> _pointerPositionNotifier =
      ValueNotifier<Offset>(Offset.zero);

  @override
  void dispose() {
    _pointerPositionNotifier.dispose();
    super.dispose();
  }

  Future<void> _openHeaderSupport() async {
    final message = context.read<EventConfigProvider>().whatsappSupportMessage;
    final launched =
        await context.read<ShopProvider>().launchWhatsApp(message: message);
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
    );
  }

  Future<void> _openInstagram() async {
    final uri = Uri.parse('https://www.instagram.com/bloco_labomba/');
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o Instagram.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final contentMaxWidth = isCompact ? 560.0 : 980.0;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A061C).withValues(alpha: 0.84),
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: isCompact ? 68 : 78,
            leadingWidth: isCompact ? 132 : 176,
            leading: Padding(
              padding:
                  EdgeInsets.only(left: isCompact ? 16 : 24, top: 8, bottom: 8),
              child: Image.asset(
                'assets/images/reference_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/admin/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                      color: const Color(0xFF655CFF).withValues(alpha: 0.85)),
                  minimumSize: Size(isCompact ? 68 : 72, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  shadowColor: const Color(0xFF5046E5),
                  elevation: 4,
                ),
                child: const Text('Entrar'),
              ),
              IconButton(
                tooltip: 'Instagram',
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: _openInstagram,
              ),
              IconButton(
                tooltip: 'WhatsApp',
                icon: const Icon(Icons.chat_outlined, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: _openHeaderSupport,
              ),
              SizedBox(width: isCompact ? 4 : 16),
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
                        isCompact ? 16 : 0,
                        isCompact ? 84 : 104,
                        isCompact ? 16 : 0,
                        60,
                      ),
                      child: Column(
                        children: [
                          const AnimatedBanner(),
                          SizedBox(height: isCompact ? 20 : 28),
                          const HeaderSection(),
                          SizedBox(height: isCompact ? 24 : 34),
                          NeonCountdown(
                            eventDate:
                                context.watch<EventConfigProvider>().eventDate,
                            unitWidth: isCompact ? 68 : 82,
                          ),
                          SizedBox(height: isCompact ? 28 : 36),
                          const EventInfoSection(),
                          SizedBox(height: isCompact ? 26 : 34),
                          const PurchaseSection(),
                          SizedBox(height: isCompact ? 42 : 64),
                          const AbadaHistorySection(),
                          SizedBox(height: isCompact ? 42 : 64),
                          const RulesSection(),
                          Visibility(
                            visible: isWarningActive,
                            child: const WarningBox(),
                          ),
                          SizedBox(height: isCompact ? 30 : 42),
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
    final baseGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0A061C),
        Color(0xFF160A38),
        Color(0xFF09051D),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = baseGradient);

    final pointerCenter = Offset(
      size.width / 2 + (pointerOffset.dx - size.width / 2) * 0.03,
      size.height * 0.28 + (pointerOffset.dy - size.height / 2) * 0.02,
    );
    final radius = max(size.width, size.height) * 0.7;
    final heroLight = RadialGradient(
      colors: [
        const Color(0xFF5426A8).withValues(alpha: 0.3),
        const Color(0xFF5426A8).withValues(alpha: 0.08),
        Colors.transparent,
      ],
      stops: const [0, 0.48, 1],
    ).createShader(
      Rect.fromCircle(center: pointerCenter, radius: radius),
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = heroLight);

    final lowerLight = RadialGradient(
      center: const Alignment(0.7, 0.9),
      radius: 0.8,
      colors: [
        const Color(0xFF3F1A91).withValues(alpha: 0.2),
        Colors.transparent,
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = lowerLight);
  }

  @override
  bool shouldRepaint(covariant _CarnivalBackgroundPainter oldDelegate) =>
      oldDelegate.pointerOffset != pointerOffset;
}
