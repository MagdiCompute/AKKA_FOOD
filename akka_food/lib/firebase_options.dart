import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the current platform.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB63_cUGvrW7uN_96mNTae7VPX9YxUfEW8',
    appId: '1:497736524789:web:c6c16f2d7ebe0517ad76bc',
    messagingSenderId: '497736524789',
    projectId: 'akka-food',
    authDomain: 'akka-food.firebaseapp.com',
    storageBucket: 'akka-food.firebasestorage.app',
    measurementId: 'G-SE9Y1Q9V20',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDM3j3MDD6Gjsgd9ZAs8t3B2v9-d7po3mg',
    appId: '1:497736524789:android:2aa3b4af63b3ffe4ad76bc',
    messagingSenderId: '497736524789',
    projectId: 'akka-food',
    storageBucket: 'akka-food.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDM3j3MDD6Gjsgd9ZAs8t3B2v9-d7po3mg',
    appId: '1:497736524789:ios:placeholder',
    messagingSenderId: '497736524789',
    projectId: 'akka-food',
    storageBucket: 'akka-food.firebasestorage.app',
    iosBundleId: 'com.akkafood.akkaFood',
  );
}
