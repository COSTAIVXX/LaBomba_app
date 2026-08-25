import 'package:flutter/material.dart';
import 'package:labomba_app/services/api_service.dart';
import 'package:labomba_app/core/theme/app_theme.dart';

class ContentDashboardPage extends StatefulWidget {
  final bool embedded;
  const ContentDashboardPage({super.key, this.embedded = false});

  @override
  State<ContentDashboardPage> createState() => _ContentDashboardPageState();
}

class _ContentDashboardPageState extends State<ContentDashboardPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final _bannerTitleController = TextEditingController(text: 'LA BOMBA 2027 • O MAIOR CARNAVAL');
  final _eventDateController = TextEditingController(text: '05 de Fevereiro de 2027');
  final _locationController = TextEditingController(text: 'Peçanha - MG');

  final List<Map<String, String>> _galleryItems = [
    {'year': '2026', 'tag': 'Edição Lendária', 'url': 'assets/images/2026.png'},
    {'year': '2025', 'tag': 'Histórico', 'url': 'assets/images/2025.png'},
    {'year': '2024', 'tag': 'Eletrizante', 'url': 'assets/images/2024.png'},
    {'year': '2023', 'tag': 'Inesquecível', 'url': 'assets/images/2023.png'},
  ];

  @override
  void dispose() {
    _bannerTitleController.dispose();
    _eventDateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _uploadMedia(String category) async {
    setState(() => _isLoading = true);
    try {
      // Simulação / Integração de upload de bytes
      final fakeBytes = <int>[0, 1, 2];
      final url = await _apiService.uploadMedia(fakeBytes, '${category}_novo.png');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[800],
          content: Text('Upload para $category concluído: $url'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Erro no upload: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTextChanges() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.updateEventConfig({
        'title': _bannerTitleController.text.trim(),
        'date': _eventDateController.text.trim(),
        'location': _locationController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Configurações salvas com sucesso!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Erro ao salvar: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      title: 'Banners & Identidade Visual',
                      subtitle: 'Altere o banner principal e as mídias em destaque da Landing Page.',
                      icon: Icons.image_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildBannerCard(),
                    const SizedBox(height: 32),

                    _buildSectionHeader(
                      title: 'Textos Dinâmicos & Informações do Evento',
                      subtitle: 'Edite os títulos, datas e locais exibidos em tempo real no site.',
                      icon: Icons.edit_note_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextEditorCard(),
                    const SizedBox(height: 32),

                    _buildSectionHeader(
                      title: 'Galeria de Fotos (Edições Anteriores)',
                      subtitle: 'Gerencie as fotos dos eventos anteriores.',
                      icon: Icons.photo_library_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildGalleryManager(),
                  ],
                ),
              ),
            ),
          );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Conteúdo (CMS)')),
      body: content,
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white60)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard() {
    return Card(
      color: Colors.white.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black38,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/labomba_banner.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white30),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Banner Principal Ativo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Dimensão recomendada: 1920x1080 (PNG ou WebP, máx 2MB)', style: TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _uploadMedia('banner_principal'),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Substituir Banner'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextEditorCard() {
    return Card(
      color: Colors.white.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _bannerTitleController,
              decoration: const InputDecoration(
                labelText: 'Título Principal do Evento',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _eventDateController,
                    decoration: const InputDecoration(
                      labelText: 'Data do Evento',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Local do Evento',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saveTextChanges,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar Alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryManager() {
    return Card(
      color: Colors.white.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: _galleryItems.length,
              itemBuilder: (context, index) {
                final item = _galleryItems[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.asset(
                            item['url']!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.photo, color: Colors.white24, size: 40),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['year']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.upload_file, size: 18),
                              tooltip: 'Alterar Imagem',
                              onPressed: () => _uploadMedia('galeria_${item['year']}'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
