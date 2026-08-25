import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Substitua pela URL do Cloud Run após o deploy
  static const String baseUrl = 'http://localhost:8080/api/v1';
  
  String? _authToken;

  void setToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // --- Rotas Públicas ---

  Future<Map<String, dynamic>> getEventConfig() async {
    final response = await http.get(Uri.parse('$baseUrl/event'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Falha ao carregar configurações do evento');
  }

  Future<Map<String, dynamic>> getContent() async {
    final response = await http.get(Uri.parse('$baseUrl/content'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Falha ao carregar conteúdo');
  }

  Future<List<dynamic>> getPricing() async {
    final response = await http.get(Uri.parse('$baseUrl/pricing'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Falha ao carregar lotes de preço');
  }

  // --- Rotas Privadas ---

  Future<void> updateEventConfig(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/event'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw Exception('Falha ao atualizar evento');
  }

  Future<void> updateRules(List<String> rules) async {
    final response = await http.put(
      Uri.parse('$baseUrl/content/rules'),
      headers: _headers,
      body: jsonEncode({'rules': rules}),
    );
    if (response.statusCode != 200) throw Exception('Falha ao atualizar regras');
  }

  Future<String> uploadMedia(List<int> fileBytes, String filename) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/media/upload'));
    
    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
    ));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'];
    }
    throw Exception('Falha ao fazer upload da mídia');
  }
}
