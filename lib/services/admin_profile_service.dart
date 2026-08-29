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

    // First consult whitelists / master email so we can return quickly when
    // the current user is explicitly allowed as admin (avoids Firestore calls
    // when running offline or during dev shortcuts).
    final bool whitelistedAdmin = _isEmailWhitelisted(user.email);
    if (whitelistedAdmin) {
      final profile = AdminProfile(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        isAdmin: true,
      );
      // Try to persist the admin flag to Firestore if possible, but don't fail
      // the whole flow if Firestore is unreachable.
      try {
        final docRef = _firestore.collection('admin_profiles').doc(user.uid);
        await docRef.set(profile.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to persist whitelisted admin profile (non-fatal): $e');
      }
      try {
        await _cacheProfile(profile);
      } catch (e) {
        debugPrint('Failed to cache whitelisted admin profile: $e');
      }
      return profile;
    }

    // Not whitelisted: read from Firestore (with cache fallback on error)
    try {
      final docRef = _firestore.collection('admin_profiles').doc(user.uid);
      final doc = await docRef.get();

      final profile = !doc.exists
          ? AdminProfile(
              uid: user.uid,
              email: user.email,
              displayName: user.displayName,
              isAdmin: false,
            )
          : AdminProfile.fromMap(user.uid, doc.data());

      // If doc didn't exist but we have a non-whitelisted default profile, cache it
      if (!doc.exists) {
        try {
          await docRef.set(profile.toMap(), SetOptions(merge: true));
        } catch (_) {}
      }

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

  /// Returns true when the provided email is present in the admin whitelist.
  /// The whitelist can be provided at build/runtime via the Dart define
  /// `--dart-define=ADMIN_WHITELIST=example@domain.com,other@domain.com`.
  /// Use lowercase, comma-separated emails. This check avoids hardcoding any
  /// specific email in source control.
  bool _isEmailWhitelisted(String? email) {
    if (email == null || email.isEmpty) return false;

    // 1) Explicit master email provided at build/run time via --dart-define=MASTER_EMAIL
    const masterEmail = String.fromEnvironment('MASTER_EMAIL', defaultValue: '');
    if (masterEmail.isNotEmpty) {
      if (email.toLowerCase() == masterEmail.toLowerCase()) {
        debugPrint('AdminProfileService: matched MASTER_EMAIL dart-define for superadmin');
        return true;
      }
    }

    // 2) Compile-time / build-time whitelist via ADMIN_WHITELIST (comma-separated)
    const envList = String.fromEnvironment('ADMIN_WHITELIST', defaultValue: '');
    if (envList.isNotEmpty) {
      final entries = envList.split(',').map((e) => e.trim().toLowerCase()).toSet();
      if (entries.contains(email.toLowerCase())) {
        debugPrint('AdminProfileService: matched ADMIN_WHITELIST entry for $email');
        return true;
      }
    }

    // 3) Development-only literal superadmin shortcut
    // WARNING: This branch is only active in debug builds to avoid creating a production bypass.
    if (kDebugMode) {
      const devSuperAdmin = 'gustavodionisio15x@gmail.com';
      if (email.toLowerCase() == devSuperAdmin.toLowerCase()) {
        debugPrint('AdminProfileService: granting dev-only superadmin for $email (kDebugMode)');
        return true;
      }
    }

    // No matches found; no whitelist present
    return false;
  }

  /// Helper to grant admin using a locally-stored whitelist entry (development only).
  /// This reads a storage key 'admin_whitelist' containing comma-separated emails
  /// and returns true if the current user matches and the profile was updated.
  Future<bool> ensureAdminByLocalStorage() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final raw = await _storage.read(key: 'admin_whitelist');
      if (raw == null || raw.isEmpty) return false;
      final entries = raw.split(',').map((e) => e.trim().toLowerCase()).toSet();
      if (!entries.contains(user.email?.toLowerCase())) return false;

      final profile = AdminProfile(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        isAdmin: true,
      );
      await setAdminProfile(profile);

      // Persist a secure session flag so other services can read it quickly
      await _storage.write(key: 'admin_session_${user.uid}', value: '1');
      return true;
    } catch (e) {
      debugPrint('ensureAdminByLocalStorage error: $e');
      return false;
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
