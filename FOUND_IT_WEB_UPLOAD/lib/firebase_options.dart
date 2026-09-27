import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCkPVz97ZycM4qJCRA9a6r4_96aH2OktoQ',
    appId: '1:264153815514:android:af29cd6c2c9b36718b08e3',
    messagingSenderId: '264153815514',
    projectId: 'foundit-57a95',
    storageBucket: 'foundit-57a95.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCkPVz97ZycM4qJCRA9a6r4_96aH2OktoQ',
    appId: '1:264153815514:ios:dummy-app-id-ios',
    messagingSenderId: '264153815514',
    projectId: 'foundit-57a95',
    storageBucket: 'foundit-57a95.firebasestorage.app',
    iosBundleId: 'com.company.Foundit',
  );
}
