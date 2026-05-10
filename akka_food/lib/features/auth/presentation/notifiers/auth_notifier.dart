import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';

/// Holds the currently authenticated [AppUser].
///
/// `null` means the user is not signed in (or the session has not yet loaded).
/// Update this provider after a successful sign-in / sign-out.
final currentUserProvider = StateProvider<AppUser?>((ref) => null);
