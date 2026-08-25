import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';

class ClientProvider with ChangeNotifier {
  static const _clientsKey = 'labomba_clients';
  final List<Client> _clients = [];

  ClientProvider() {
    _loadClients();
  }

  List<Client> get clients => List.unmodifiable(_clients);

  Future<Client> registerClient({
    required String fullName,
    required DateTime birthDate,
    required String cpf,
    required String phone,
    required bool acceptedTerms,
  }) async {
    if (!acceptedTerms) {
      throw const ClientRegistrationException(
          'É obrigatório aceitar o termo de responsabilidade.');
    }

    final client = Client(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fullName: fullName.trim(),
      birthDate: birthDate,
      cpf: cpf.trim(),
      phone: phone.trim(),
      registeredAt: DateTime.now(),
      acceptedTerms: acceptedTerms,
    );

    if (client.age < 18) {
      throw const ClientRegistrationException(
        'O evento é restrito para maiores de 18 anos.',
      );
    }

    _clients.add(client);
    notifyListeners();
    await _saveClients();
    return client;
  }

  /// Update basic client information (does not change registeredAt)
  Future<void> updateClient({
    required String clientId,
    String? fullName,
    DateTime? birthDate,
    String? cpf,
    String? phone,
    bool? acceptedTerms,
  }) async {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index < 0) return;
    final existing = _clients[index];
    final updated = Client(
      id: existing.id,
      fullName: fullName?.trim() ?? existing.fullName,
      birthDate: birthDate ?? existing.birthDate,
      cpf: cpf?.trim() ?? existing.cpf,
      phone: phone?.trim() ?? existing.phone,
      registeredAt: existing.registeredAt,
      acceptedTerms: acceptedTerms ?? existing.acceptedTerms,
      purchaseHistory: existing.purchaseHistory,
    );
    _clients[index] = updated;
    notifyListeners();
    await _saveClients();
  }

  /// Delete a client from the list
  Future<void> deleteClient(String clientId) async {
    _clients.removeWhere((c) => c.id == clientId);
    notifyListeners();
    await _saveClients();
  }

  /// Update the payment status of the latest purchase for a client
  Future<void> updateLatestPaymentStatus(String clientId, String status) async {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index < 0) return;
    final client = _clients[index];
    if (client.purchaseHistory.isEmpty) return;
    final last = client.purchaseHistory.last;
    final updated = ClientPurchase(
      description: last.description,
      quantity: last.quantity,
      amount: last.amount,
      purchasedAt: last.purchasedAt,
      paymentMethod: last.paymentMethod,
      paymentStatus: status,
    );
    client.purchaseHistory[client.purchaseHistory.length - 1] = updated;
    notifyListeners();
    await _saveClients();
  }

  Future<void> _loadClients() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_clientsKey);
      if (saved == null) return;
      
      final decoded = jsonDecode(saved) as List<dynamic>;
      _clients
        ..clear()
        ..addAll(decoded.map((item) => Client.fromJson(
              Map<String, dynamic>.from(item as Map),
            )));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading clients: $e');
      // Keep an empty list when local client data is invalid or corrupt.
      _clients.clear();
      notifyListeners();
    }
  }

  Future<void> _saveClients() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _clientsKey,
        jsonEncode(_clients.map((client) => client.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving clients: $e');
    }
  }

  /// Adds a purchase record to an existing client and persists the change.
  Future<void> addPurchase(String clientId, ClientPurchase purchase) async {
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index < 0) return;
    _clients[index].purchaseHistory.add(purchase);
    notifyListeners();
    await _saveClients();
  }
}

class ClientRegistrationException implements Exception {
  const ClientRegistrationException(this.message);
  final String message;
}
