class AdminProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAdmin;

  const AdminProfile({
    required this.uid,
    this.email,
    this.displayName,
    required this.isAdmin,
  });

  factory AdminProfile.fromMap(String uid, Map<String, dynamic>? map) {
    if (map == null) return AdminProfile(uid: uid, email: null, displayName: null, isAdmin: false);
    return AdminProfile(
      uid: uid,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      isAdmin: (map['isAdmin'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'isAdmin': isAdmin,
      };
}
