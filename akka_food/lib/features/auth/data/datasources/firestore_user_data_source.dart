import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';

/// Handles all Firestore read/write operations for the `/users/{uid}` document.
class FirestoreUserDataSource {
  FirestoreUserDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Fetches the user document for [uid] from Firestore.
  ///
  /// Returns null if the document does not exist.
  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap({'uid': uid, ...doc.data()!});
  }

  /// Creates or overwrites the `/users/{uid}` document.
  ///
  /// Used during registration to persist the initial user record.
  /// The [role] field is always included; new users receive 'user' by default.
  Future<void> createUser(AppUser user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  /// Updates specific fields on the `/users/{uid}` document.
  ///
  /// Only the provided fields are written; other fields are left unchanged.
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _usersCollection.doc(uid).update(fields);
  }

  /// Returns a real-time stream of the `/users/{uid}` document.
  Stream<AppUser?> watchUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return AppUser.fromMap({'uid': uid, ...snapshot.data()!});
    });
  }

  /// Builds the initial Firestore document map for a newly registered user.
  ///
  /// The [role] is always set to 'user' for new registrations.
  static Map<String, dynamic> buildNewUserDocument({
    required String uid,
    required String displayName,
    String? email,
    String? phoneNumber,
    required List<String> linkedProviders,
  }) {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'isVerified': false,
      'isDeactivated': false,
      'createdAt': FieldValue.serverTimestamp(),
      'linkedProviders': linkedProviders,
      'coinBalance': 0,
      'failedLoginAttempts': 0,
      'lockedUntil': null,
      // New users always start with the 'user' role.
      // Role can only be elevated to 'admin' via the Firebase Console
      // or a dedicated admin provisioning script.
      'role': 'user',
    };
  }
}
