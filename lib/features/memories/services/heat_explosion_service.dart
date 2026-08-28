import 'package:cloud_firestore/cloud_firestore.dart';

class HeatExplosionService {
  final FirebaseFirestore _firestore;

  HeatExplosionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('heat_explosions');

  Stream<QuerySnapshot<Map<String, dynamic>>> eventsStream() => _events
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots();

  Future<String> trigger({
    required String userId,
    required String displayName,
  }) async {
    final reference = await _events.add({
      'userId': userId,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }
}
