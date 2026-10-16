// File: lib/firebase_options.dart
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
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been supported for this platform.',
        );
    }
  }

  // Cấu hình đồng bộ từ thông tin Firebase của bạn
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBYPjL5OrGT8OTvjK2HnP1EgAyI7GoOrHM',
    appId: '1:219095426302:web:40347dfbf1fc0e042331af',
    messagingSenderId: '219095426302',
    projectId: 'fir-pos-8ff24',
    databaseURL: 'https://fir-pos-8ff24-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBYPjL5OrGT8OTvjK2HnP1EgAyI7GoOrHM',
    appId: '1:219095426302:web:40347dfbf1fc0e042331af',
    messagingSenderId: '219095426302',
    projectId: 'fir-pos-8ff24',
    databaseURL: 'https://fir-pos-8ff24-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYPjL5OrGT8OTvjK2HnP1EgAyI7GoOrHM',
    appId: '1:219095426302:web:40347dfbf1fc0e042331af',
    messagingSenderId: '219095426302',
    projectId: 'fir-pos-8ff24',
    databaseURL: 'https://fir-pos-8ff24-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}