import 'package:flutter/material.dart';

class PurchaseSection extends StatefulWidget {
  const PurchaseSection({super.key});

  @override
  State<PurchaseSection> createState() => _PurchaseSectionState();
}

class _PurchaseSectionState extends State<PurchaseSection> {
  int _quantity = 1;
  bool _isHovered = false;

  void _changeQuantity(int delta) {
    setState(() => _quantity = (_quantity + delta).clamp(1, 5));
  }

  void _showFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sua seleção está pronta para a próxima etapa.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final cardWidth = isMobile ? double.infinity : 430.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'QUERO MEU ABADÁ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Vista a energia do bloco antes mesmo da primeira batida.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 26),
        isMobile
            ? _buildProductColumn(cardWidth)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildProductCard(cardWidth)),
                  const SizedBox(width: 18),
                  Expanded(child: _buildDetailsCard()),
                ],
              ),
      ],
    );
  }

  Widget _buildProductColumn(double width) {
    return Column(
      children: [
        _buildProductCard(width),
        const SizedBox(height: 16),
        _buildDetailsCard(),
      ],
    );
  }

  Widget _buildProductCard(double width) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: width,
        height: 330,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF120B25),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFFF8C15A)
                : Colors.white.withValues(alpha: 0.14),
            width: _isHovered ? 1.4 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8D42FF)
                  .withValues(alpha: _isHovered ? 0.24 : 0.1),
              blurRadius: _isHovered ? 24 : 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EDIÇÃO OFICIAL',
                  style: TextStyle(
                    color: Color(0xFFF8C15A),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'PRÉ-VENDA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: const _ComingSoonContent(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ABADÁ OFICIAL LABOMBA',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final total = 129 * _quantity;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0920).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'GARANTA O SEU',
            style: TextStyle(
              color: Color(0xFFF8C15A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Pré-venda VIP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Acesso ao bloco + abadá oficial',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: _InfoLine(label: 'LOTE', value: 'Pré-venda VIP'),
              ),
              _QuantityControl(
                quantity: _quantity,
                onDecrease: _quantity == 1 ? null : () => _changeQuantity(-1),
                onIncrease: _quantity == 5 ? null : () => _changeQuantity(1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'R\$',
                style: TextStyle(
                  color: Color(0xFFF8C15A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 5, left: 3),
                child: Text(',00', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Semantics(
            button: true,
            label: 'Quero meu abadá',
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _showFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8C15A),
                  foregroundColor: const Color(0xFF170B2D),
                  elevation: 8,
                  shadowColor: const Color(0xFFF8C15A).withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'QUERO MEU ABADÁ',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Seleção visual demonstrativa • compra será conectada depois',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 10,
            ),
          ),
        ],
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
          Icon(
            Icons.workspace_premium_outlined,
            color: const Color(0xFFFFD700).withValues(alpha: 0.9),
            size: 44,
          ),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quantidade: $quantity',
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Diminuir quantidade',
              onPressed: onDecrease,
              icon: const Icon(Icons.remove, size: 16),
              color: Colors.white,
              disabledColor: Colors.white24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 34),
            ),
            Text(
              '$quantity',
              style: const TextStyle(
                color: Color(0xFFF8C15A),
                fontWeight: FontWeight.w900,
              ),
            ),
            IconButton(
              tooltip: 'Aumentar quantidade',
              onPressed: onIncrease,
              icon: const Icon(Icons.add, size: 16),
              color: Colors.white,
              disabledColor: Colors.white24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 34),
            ),
          ],
        ),
      ),
    );
  }
}
