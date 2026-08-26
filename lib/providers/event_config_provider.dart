import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class EventConfigProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  String _title = 'LA BOMBA 2027 • O MAIOR CARNAVAL';
  String _date = '05 de Fevereiro de 2027';
  String _location = 'Peçanha - MG';

  bool _loading = false;

  // Optional stream to allow fine-grained subscriptions
  final StreamController<Map<String, String>> _onChange = StreamController.broadcast();

  EventConfigProvider() {
    // initial load
    fetch();
  }

  Stream<Map<String, String>> get onChange => _onChange.stream;

  String get title => _title;
  String get date => _date;
  String get location => _location;
  bool get isLoading => _loading;

  Future<void> fetch() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.getEventConfig();
      _title = data['title']?.toString() ?? _title;
      _date = data['date']?.toString() ?? _date;
      _location = data['location']?.toString() ?? _location;
      _onChange.add({'title': _title, 'date': _date, 'location': _location});
    } catch (e) {
      // ignore, keep defaults
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> update(Map<String, String> data) async {
    _loading = true;
    notifyListeners();
    try {
      await _api.updateEventConfig(data);
      // update local state immediately for reactivity
      _title = data['title'] ?? _title;
      _date = data['date'] ?? _date;
      _location = data['location'] ?? _location;
      _onChange.add({'title': _title, 'date': _date, 'location': _location});
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void disposeProvider() {
    _onChange.close();
  }
}
