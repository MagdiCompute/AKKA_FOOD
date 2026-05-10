/// A read-only view of a user as seen by the admin dashboard.
///
/// Firestore collection: `/users/{uid}`
/// Satisfies Requirements 6.1 and 6.4.
///
/// This is a pure Dart class with zero Flutter/Firebase imports.
class AdminUserView {
  const AdminUserView({
    required this.uid,
    required this.displayName,
    this.email,
    required this.createdAt,
    required this.orderCount,
    required this.coinBalance,
    required this.isDeactivated,
    required this.role,
  });

  final String uid;
  final String displayName;
  final String? email;
  final DateTime createdAt;

  /// Total number of orders placed by this user.
  final int orderCount;

  /// Current loyalty coin balance.
  final int coinBalance;

  /// Whether the account is currently deactivated.
  final bool isDeactivated;

  /// Role: 'user' | 'admin'
  final String role;

  AdminUserView copyWith({
    String? uid,
    String? displayName,
    String? email,
    DateTime? createdAt,
    int? orderCount,
    int? coinBalance,
    bool? isDeactivated,
    String? role,
  }) {
    return AdminUserView(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      orderCount: orderCount ?? this.orderCount,
      coinBalance: coinBalance ?? this.coinBalance,
      isDeactivated: isDeactivated ?? this.isDeactivated,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUserView &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          isDeactivated == other.isDeactivated;

  @override
  int get hashCode => uid.hashCode ^ isDeactivated.hashCode;

  @override
  String toString() =>
      'AdminUserView(uid: $uid, displayName: $displayName, '
      'isDeactivated: $isDeactivated)';
}
