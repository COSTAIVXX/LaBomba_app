import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_profile.dart';
import 'storage_platform.dart';
import 'storage_service.dart';

class AdminProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StorageService _storage;

  AdminProfileService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StorageService? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? PlatformStorageService();

  String _cacheKey(String uid) => 'admin_profile_cache_$uid';

  Future<void> _cacheProfile(AdminProfile profile) async {
    await _storage.write(
      key: _cacheKey(profile.uid),
      value: jsonEncode(profile.toMap()),
    );
  }

  Future<AdminProfile?> _readCachedProfile(String uid) async {
    final value = await _storage.read(key: _cacheKey(uid));
    if (value == null || value.isEmpty) return null;
    return AdminProfile.fromMap(
      uid,
      Map<String, dynamic>.from(jsonDecode(value) as Map),
    );
  }

  /// Reads admin profile for the current user from Firestore collection 'admin_profiles'.
  /// Returns null if no user is signed in or profile not found.
  Future<AdminProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('admin_profiles').doc(user.uid).get();
      final profile = !doc.exists
          ? AdminProfile(
              uid: user.uid,
              email: user.email,
              displayName: user.displayName,
              isAdmin: false,
            )
          : AdminProfile.fromMap(user.uid, doc.data());
      await _cacheProfile(profile);
      return profile;
    } catch (e) {
      debugPrint('AdminProfileService.getCurrentUserProfile error: $e');
      try {
        return await _readCachedProfile(user.uid);
      } catch (cacheError) {
        debugPrint('AdminProfileService cache read error: $cacheError');
        return null;
      }
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
      await _cacheProfile(profile);
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
      final cached = await _readCachedProfile(user.uid);
      await _cacheProfile(AdminProfile(
        uid: user.uid,
        email: user.email,
        displayName: displayName,
        isAdmin: cached?.isAdmin ?? false,
      ));
    } catch (e) {
      debugPrint('AdminProfileService.updateDisplayName error: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String displayName,
    required String bio,
    required Map<String, String> socialLinks,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(displayName);
    await user.reload();
    final cached = await _readCachedProfile(user.uid);
    final profile = AdminProfile(
      uid: user.uid,
      email: user.email,
      displayName: displayName,
      bio: bio,
      socialLinks: socialLinks,
      isAdmin: cached?.isAdmin ?? false,
    );
    await _firestore.collection('admin_profiles').doc(user.uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
    await _cacheProfile(profile);
  }
}
