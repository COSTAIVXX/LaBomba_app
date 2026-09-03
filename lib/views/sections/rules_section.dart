import 'package:flutter/material.dart';

class RulesSection extends StatelessWidget {
  const RulesSection({super.key});

  static const _rules = <String>[
    'Uso exclusivo e intransferível de abadás, pulseiras e canecas oficiais!',
    'Proibido Compartilhar Bebida: Passível de expulsão. Servidores do bloco têm autoridade para cortar a pulseira em caso de descumprimento.',
    'Proibido Fumar: Dentro da área de concentração.',
    'Tolerância Zero para Brigas: Passível de expulsão.',
    'Respeito Obrigatório: Aos garçons, seguranças e servidores do bloco.',
    'Entrada na concentração apenas com abadá, pulseira e caneca oficiais.',
    'Responsabilidade do Material: A organização não se responsabiliza pela troca de materiais perdidos (caneca, pulseira ou abadá).',
    'Banheiro do Bloco: Exclusivo para mulheres.',
    'Gelo Saborizado Inteligente: Monitoramento digital e visual por garçons e organizadores. O gelo permanece inteiro por 3 a 4 rodadas, sem necessidade de reposição neste intervalo.',
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: const Color(0xFF120B25),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8D42FF).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _RulesHeading(),
                const SizedBox(height: 24),
                ..._rules.map((rule) => _RuleItem(text: rule)),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 190,
                  child: _RulesHeading(),
                ),
                const SizedBox(width: 26),
                Expanded(
                  child: Wrap(
                    spacing: 22,
                    runSpacing: 18,
                    children: [
                      for (var index = 0; index < _rules.length; index++)
                        SizedBox(
                          width: (MediaQuery.sizeOf(context).width < 900
                              ? 280
                              : 210),
                          child: _RuleItem(text: _rules[index]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _RulesHeading extends StatelessWidget {
  const _RulesHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          color: Color(0xFFF8C15A),
          size: 38,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'REGRAS\nDO BLOCO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 9),
            child: Icon(
              Icons.check_circle,
              color: Color(0xFF8D42FF),
              size: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
