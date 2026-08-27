import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class TermsPage extends StatefulWidget {
  final StorageService storageService;
  const TermsPage({super.key, required this.storageService});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool _accepted = false;
  bool _saving = false;

  static const _storageKey = 'terms_accepted';

  @override
  void initState() {
    super.initState();
    _loadAccepted();
  }

  Future<void> _loadAccepted() async {
    try {
      final v = await widget.storageService.read(key: _storageKey);
      setState(() => _accepted = v == '1');
    } catch (_) {}
  }

  Future<void> _accept() async {
    setState(() => _saving = true);
    try {
      await widget.storageService.write(key: _storageKey, value: '1');
      if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/landing');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar aceite: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Termos de Uso', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            'Ao utilizar o aplicativo La Bomba você concorda com os termos e condições.\n\n' 
            'Este é um texto de exemplo — substitua pelo texto oficial de Termos de Uso e Política de Privacidade do produto.\n\n'
            'Coleta de dados: armazenamos memórias localmente e, quando autorizado, dados em backend.\n\n'
            'Privacidade: respeitamos sua privacidade. Consulte a Política de Privacidade completa.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 18),
          Text('Política de Privacidade', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            'A Política de Privacidade descreve como coletamos, usamos e protegemos os dados do usuário.\n\n' 
            'Este é um texto de exemplo — substitua pelo texto oficial.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Checkbox(value: _accepted, onChanged: (v) => setState(() => _accepted = v ?? false)),
            const Expanded(child: Text('Eu li e concordo com os Termos de Uso e a Política de Privacidade.')),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _accepted && !_saving ? _accept : null,
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : const Text('Aceitar e Continuar'),
            ),
          )
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Termos e Privacidade')),
      body: SafeArea(child: content),
    );
  }
}

// A small gateway that checks the storage key and either pushes to LandingPage or shows TermsPage
class TermsGate extends StatefulWidget {
  final StorageService storageService;
  const TermsGate({super.key, required this.storageService});

  @override
  State<TermsGate> createState() => _TermsGateState();
}

class _TermsGateState extends State<TermsGate> {
  bool _checked = false;
  bool _accepted = false;

  static const _storageKey = 'terms_accepted';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final v = await widget.storageService.read(key: _storageKey);
      setState(() {
        _accepted = v == '1';
        _checked = true;
      });
      if (_accepted) {
        // Navigate to landing page replacing this gate
        if (mounted) Navigator.pushReplacementNamed(context, '/landing');
      }
    } catch (_) {
      setState(() => _checked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_accepted) return const SizedBox.shrink();
    return TermsPage(storageService: widget.storageService);
  }
}
