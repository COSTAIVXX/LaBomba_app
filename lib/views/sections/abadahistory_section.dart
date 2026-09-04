import 'package:flutter/material.dart';

class AbadaEdition {
  const AbadaEdition({
    required this.year,
    required this.images,
  });

  final int year;
  final List<String> images;
}

class AbadaHistorySection extends StatefulWidget {
  const AbadaHistorySection({
    this.upcomingImages = const [],
    super.key,
  });

  final List<String> upcomingImages;

  static const editions = <AbadaEdition>[
    AbadaEdition(
      year: 2019,
      images: [
        'assets/images/LaBomba2019.jpeg',
        'assets/images/LaBomba2019.2.jpeg'
      ],
    ),
    AbadaEdition(
      year: 2020,
      images: [
        'assets/images/LaBomba2020.png',
        'assets/images/LaBomba2020.2.png'
      ],
    ),
    AbadaEdition(
      year: 2023,
      images: [
        'assets/images/LaBomba2023.jpeg',
        'assets/images/LaBomba2023.2.jpeg'
      ],
    ),
    AbadaEdition(year: 2024, images: []),
    AbadaEdition(
      year: 2025,
      images: [
        'assets/images/LaBomba2025.png',
        'assets/images/LaBomba2025.2.png'
      ],
    ),
    AbadaEdition(
      year: 2026,
      images: [
        'assets/images/LaBomba2026.jpeg',
        'assets/images/LaBomba2026.2.jpeg'
      ],
    ),
  ];

  @override
  State<AbadaHistorySection> createState() => _AbadaHistorySectionState();
}

class _AbadaHistorySectionState extends State<AbadaHistorySection> {
  final _scrollController = ScrollController();
  int _selectedEdition = AbadaHistorySection.editions.length - 1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerEdition(int index, double cardWidth) {
    final viewport = _scrollController.position.viewportDimension;
    final target = index * (cardWidth + 16) + 24 - (viewport - cardWidth) / 2;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent).toDouble(),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final cardWidth = isMobile ? 232.0 : 276.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'A TRADIÇÃO LABOMBA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Uma história vestida de cor, música e memória.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 26),
        const _TraditionCopy(),
        const SizedBox(height: 32),
        const Text(
          'EDIÇÕES ANTERIORES',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFF8C15A),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: isMobile ? 264 : 286,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            itemCount: AbadaHistorySection.editions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final edition = AbadaHistorySection.editions[index];
              return _HistoricalEditionCard(
                edition: edition,
                width: cardWidth,
                selected: index == _selectedEdition,
                onTap: () {
                  setState(() => _selectedEdition = index);
                  _centerEdition(index, cardWidth);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TraditionCopy extends StatelessWidget {
  const _TraditionCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'O NOVO CICLO\nCOMEÇA AQUI.',
          style: TextStyle(
            color: Color(0xFFF8C15A),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Cada batida conta uma história.\n'
          'Cada abadá carrega uma memória.\n'
          'E a próxima vem para marcar uma nova história.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 15,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '🔒  AGUARDE. ALGO NOVO VEM AÍ.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _MysteryEditionCard extends StatefulWidget {
  const _MysteryEditionCard({required this.images});

  final List<String> images;

  @override
  State<_MysteryEditionCard> createState() => _MysteryEditionCardState();
}

class _MysteryEditionCardState extends State<_MysteryEditionCard> {
  late final PageController _pageController;
  int _currentPage = 0;

  List<String> get _images => widget.images.take(4).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changePage(int delta) {
    if (_images.isEmpty) return;
    final target = (_currentPage + delta).clamp(0, _images.length - 1);
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    return Semantics(
      label: images.isEmpty
          ? 'Próximo abadá, em breve'
          : 'Imagens do próximo abadá, imagem ${_currentPage + 1} de ${images.length}',
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF21103E), Color(0xFF10091F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB000).withValues(alpha: 0.22),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: images.isEmpty
            ? const _ComingSoonContent()
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(27),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) => Image.asset(
                        images[index],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const _ComingSoonContent(),
                      ),
                    ),
                  ),
                  if (images.length > 1) ...[
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: _CarouselButton(
                        tooltip: 'Imagem anterior',
                        icon: Icons.chevron_left,
                        onPressed:
                            _currentPage == 0 ? null : () => _changePage(-1),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: _CarouselButton(
                        tooltip: 'Próxima imagem',
                        icon: Icons.chevron_right,
                        onPressed: _currentPage == images.length - 1
                            ? null
                            : () => _changePage(1),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var index = 0; index < images.length; index++)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: Semantics(
                                label:
                                    'Imagem ${index + 1} de ${images.length}',
                                selected: index == _currentPage,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == _currentPage
                                        ? const Color(0xFFFFD700)
                                        : Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ComingSoonContent extends StatelessWidget {
  const _ComingSoonContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_outlined,
              color: const Color(0xFFFFD700).withValues(alpha: 0.9), size: 44),
          const SizedBox(height: 14),
          const Text(
            'EM BREVE',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O próximo capítulo está chegando.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CarouselButton extends StatelessWidget {
  const _CarouselButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        color: Colors.white,
        disabledColor: Colors.white24,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black45,
          minimumSize: const Size(44, 44),
        ),
      ),
    );
  }
}

class _HistoricalEditionCard extends StatefulWidget {
  const _HistoricalEditionCard({
    required this.edition,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final AbadaEdition edition;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_HistoricalEditionCard> createState() => _HistoricalEditionCardState();
}

class _HistoricalEditionCardState extends State<_HistoricalEditionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.selected || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: highlighted ? 1.018 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: widget.width,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF120B21),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: highlighted
                      ? const Color(0xFFF8C15A)
                      : Colors.white.withValues(alpha: 0.14),
                  width: highlighted ? 1.1 : 0.8,
                ),
                boxShadow: highlighted
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF8C15A).withValues(alpha: 0.2),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.edition.year}',
                          style: const TextStyle(
                            color: Color(0xFFF8C15A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (widget.edition.images.length > 1)
                          Text(
                            '${widget.edition.images.length} VISTAS',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: widget.edition.images.isEmpty
                            ? const _UnavailableEditionImage()
                            : _EditionImageStack(images: widget.edition.images),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.edition.images.isEmpty
                          ? 'ARQUIVO HISTÓRICO'
                          : 'TOQUE PARA EXPLORAR',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnavailableEditionImage extends StatelessWidget {
  const _UnavailableEditionImage();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF21113D),
      child: Center(
        child: Icon(
          Icons.photo_library_outlined,
          color: Colors.white.withValues(alpha: 0.48),
          size: 38,
        ),
      ),
    );
  }
}

class _EditionImageStack extends StatelessWidget {
  const _EditionImageStack({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) => Image.asset(
        images[index],
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const _UnavailableEditionImage(),
      ),
    );
  }
}
