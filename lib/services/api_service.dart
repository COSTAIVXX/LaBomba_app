import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiService {
  ApiService();

  String? _authToken;

  void setToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) headers['Authorization'] = 'Bearer ' + _authToken!;
    return headers;
  }

  String get _base => ApiConfig.baseUrl;

  // --- Rotas Públicas ---

  Future<Map<String, dynamic>> getEventConfig() async {
    try {
      final response = await http.get(Uri.parse(_base + '/event'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Falha ao carregar configurações do evento');
    } on SocketException catch (e) {
      throw Exception('Conexão falhou: ' + e.toString());
    }
  }

  Future<Map<String, dynamic>> getContent() async {
    try {
      final response = await http.get(Uri.parse(_base + '/content'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Falha ao carregar conteúdo');
    } on SocketException catch (e) {
      throw Exception('Conexão falhou: ' + e.toString());
    }
  }

  Future<List<dynamic>> getPricing() async {
    try {
      final response = await http.get(Uri.parse(_base + '/pricing'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Falha ao carregar lotes de preço');
    } on SocketException catch (e) {
      throw Exception('Conexão falhou: ' + e.toString());
    }
  }

  // --- Rotas PrivADAS ---

  Future<void> updateEventConfig(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse(_base + '/event'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) throw Exception('Falha ao atualizar evento');
    } on SocketException catch (e) {
      throw Exception('Conexão falhou: ' + e.toString());
    }
  }

  Future<void> updateRules(List<String> rules) async {
    try {
      final response = await http.put(
        Uri.parse(_base + '/content/rules'),
        headers: _headers,
        body: jsonEncode({'rules': rules}),
      );
      if (response.statusCode != 200) throw Exception('Falha ao atualizar regras');
    } on SocketException catch (e) {
      throw Exception('Conexão falhou: ' + e.toString());
    }
  }

  Future<String> uploadMedia(List<int> fileBytes, String filename) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_base + '/media/upload'));
      
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer ' + _authToken!;
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
    } on SocketException catch (e) {
      throw Exception('Conexão falhou: ' + e.toString());
    }
  }
}
