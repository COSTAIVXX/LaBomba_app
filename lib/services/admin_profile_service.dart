import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_profile.dart';

class AdminProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Reads admin profile for the current user from Firestore collection 'admin_profiles'.
  /// Returns null if no user is signed in or profile not found.
  Future<AdminProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('admin_profiles').doc(user.uid).get();
      if (!doc.exists) return AdminProfile(uid: user.uid, email: user.email, displayName: user.displayName, isAdmin: false);
      return AdminProfile.fromMap(user.uid, doc.data());
    } catch (e) {
      debugPrint('AdminProfileService.getCurrentUserProfile error: $e');
      return null;
    }
  }

  /// Shortcut to check if the current user is marked as admin in Firestore
  Future<bool> isCurrentUserAdmin() async {
    final p = await getCurrentUserProfile();
    return p?.isAdmin ?? false;
  }

  /// Update or create the admin profile for the given uid
  Future<void> setAdminProfile(AdminProfile profile) async {
    try {
      await _firestore.collection('admin_profiles').doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('AdminProfileService.setAdminProfile error: $e');
      rethrow;
    }
  }

  /// Update the Firebase Auth user's displayName and mirror to Firestore admin_profiles
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.updateDisplayName(displayName);
      await user.reload();
      // update Firestore profile as well (merge)
      await _firestore.collection('admin_profiles').doc(user.uid).set({
        'displayName': displayName,
        'email': user.email,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AdminProfileService.updateDisplayName error: $e');
      rethrow;
    }
  }
}
