import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final maxWidth = 900.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Política de Privacidade')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Política de Privacidade', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  const Text(
                    'A sua privacidade é importante para nós. Esta política descreve como coletamos, usamos e protegemos os dados dos usuários do aplicativo La Bomba.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  const Text('Dados que coletamos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text(
                    '- Informações fornecidas pelo usuário: nome, e-mail e conteúdo enviado (memórias, fotos e vídeos).
- Dados de uso: eventos agregados de uso para melhorar a experiência.
- Dados técnicos: identificadores de dispositivo e logs para diagnóstico.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  const Text('Como usamos os dados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text(
                    '- Armazenar memórias e mídia quando o usuário autoriza.
- Melhorar o serviço, enviar notificações relevantes e prevenir abusos.
- Não vendemos dados de usuários a terceiros.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  const Text('Compartilhamento e terceiros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text(
                    'Podemos compartilhar dados com provedores de serviços (por exemplo, Firebase) para armazenar e entregar conteúdo. Esses provedores processam dados conforme contratos e não os utilizam para outros fins.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  const Text('Segurança', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text(
                    'Aplicamos práticas padrão da indústria para proteger dados em trânsito e em repouso. Entretanto, nenhum sistema é 100% seguro — contacte-nos em caso de suspeita de violação.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  const Text('Contato', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Para dúvidas sobre privacidade, envie um e-mail para privacy@labomba.example.com.', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar', style: TextStyle(color: Color(0xFF2563EB))),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
