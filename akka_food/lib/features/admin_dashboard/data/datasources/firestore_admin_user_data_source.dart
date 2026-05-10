import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/admin_order_view.dart';
import '../../domain/entities/admin_user_view.dart';

/// Handles Firestore read operations for the `/users` collection
/// in the context of the admin dashboard.
class FirestoreAdminUserDataSource {
  FirestoreAdminUserDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  /// Returns a real-time stream of all users ordered by displayName.
  Stream<List<AdminUserView>> watchAllUsers() {
    return _usersCollection
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Fetches a single user document by [uid].
  Future<AdminUserView?> getUserById(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return _fromMap(doc.id, doc.data()!);
  }

  /// Fetches the 20 most recent orders for the user identified by [uid].
  Future<List<AdminOrderView>> getOrdersByUserId(String uid) async {
    final snapshot = await _ordersCollection
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    return snapshot.docs
        .map((doc) => AdminOrderView.fromMap(doc.id, doc.data()))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Mapping helpers (Firestore → domain entity)
  // ---------------------------------------------------------------------------

  static AdminUserView _fromMap(String uid, Map<String, dynamic> map) {
    return AdminUserView(
      uid: uid,
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String?,
      createdAt: map['createdAt'] != null
          ? _parseDateTime(map['createdAt'])
          : DateTime.now(),
      orderCount: (map['orderCount'] as num?)?.toInt() ?? 0,
      coinBalance: (map['coinBalance'] as num?)?.toInt() ?? 0,
      isDeactivated: map['isDeactivated'] as bool? ?? false,
      role: map['role'] as String? ?? 'user',
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return DateTime.now();
  }
}
