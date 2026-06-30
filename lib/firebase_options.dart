import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured yet.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB5tB2NcyA63QvFWxfSBtiuYsI7vRUhpJg',
    appId: '1:56946479785:android:aa2fc42450bdd45ab64fb8',
    messagingSenderId: '56946479785',
    projectId: 'bizsplit-818a0',
    storageBucket: 'bizsplit-818a0.firebasestorage.app',
  );
}