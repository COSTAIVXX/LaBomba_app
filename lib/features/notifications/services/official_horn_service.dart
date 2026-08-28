import 'package:cloud_firestore/cloud_firestore.dart';

class OfficialAnnouncement {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;

  const OfficialAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory OfficialAnnouncement.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];
    return OfficialAnnouncement(
      id: document.id,
      title: data['title'] as String? ?? 'Buzina oficial',
      message: data['message'] as String? ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }
}

class OfficialHornService {
  final FirebaseFirestore _firestore;

  OfficialHornService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('official_announcements');

  Stream<QuerySnapshot<Map<String, dynamic>>> announcementsStream() =>
      _announcements
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots();

  Future<void> publish({
    required String title,
    required String message,
  }) {
    return _announcements.add({
      'title': title.trim(),
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
