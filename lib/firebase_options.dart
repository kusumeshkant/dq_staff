// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web: shares the dqueue-716ad Firebase project. Auth and Firestore are
  // project-scoped so they work correctly. Register a dedicated dq_staff web
  // app via `flutterfire configure` when Firebase Analytics per-app tracking
  // is needed.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD9HmJU2-5PuXQ3IlOxqEJ2YB4H6D0kqvQ',
    appId: '1:17681865839:web:71f4906f9fc83989b4019a',
    messagingSenderId: '17681865839',
    projectId: 'dqueue-716ad',
    authDomain: 'dqueue-716ad.firebaseapp.com',
    databaseURL: 'https://dqueue-716ad-default-rtdb.firebaseio.com',
    storageBucket: 'dqueue-716ad.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBdAEa_YkPJ3oWpK-C2li6ftZ-SlVM_tKc',
    appId: '1:17681865839:android:c6b7011d0b711adbb4019a',
    messagingSenderId: '17681865839',
    projectId: 'dqueue-716ad',
    databaseURL: 'https://dqueue-716ad-default-rtdb.firebaseio.com',
    storageBucket: 'dqueue-716ad.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCpd0-_wzQlwuGeHSyj6iucA1zDaFahYds',
    appId: '1:17681865839:ios:b33bdd9bb0751fdbb4019a',
    messagingSenderId: '17681865839',
    projectId: 'dqueue-716ad',
    databaseURL: 'https://dqueue-716ad-default-rtdb.firebaseio.com',
    storageBucket: 'dqueue-716ad.appspot.com',
    iosBundleId: 'com.example.dqStaff',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCpd0-_wzQlwuGeHSyj6iucA1zDaFahYds',
    appId: '1:17681865839:ios:b33bdd9bb0751fdbb4019a',
    messagingSenderId: '17681865839',
    projectId: 'dqueue-716ad',
    databaseURL: 'https://dqueue-716ad-default-rtdb.firebaseio.com',
    storageBucket: 'dqueue-716ad.appspot.com',
    iosBundleId: 'com.example.dqStaff',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBnCUh272QwWdP_q-X5lYgf_XYC6yZg4EM',
    appId: '1:17681865839:web:9c0e623d507e8fbab4019a',
    messagingSenderId: '17681865839',
    projectId: 'dqueue-716ad',
    authDomain: 'dqueue-716ad.firebaseapp.com',
    databaseURL: 'https://dqueue-716ad-default-rtdb.firebaseio.com',
    storageBucket: 'dqueue-716ad.appspot.com',
  );
}
