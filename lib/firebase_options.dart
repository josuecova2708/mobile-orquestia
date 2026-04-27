// IMPORTANTE: Este archivo debe ser generado con:
//   flutterfire configure --project=orquestia
//
// Pasos:
//   1. dart pub global activate flutterfire_cli
//   2. flutterfire configure --project=orquestia
//   3. Reemplaza este archivo con el generado.
//
// Por ahora es un placeholder que NO contiene valores reales.
// La app compilará pero las push notifications no funcionarán hasta completar el paso anterior.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  // TODO: Reemplazar con valores reales de Firebase Console → Configuración del proyecto
  // Project: orquestia
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDcSZVQWJHhg9L74N-CxD2pNDHr5EcK1U',
    appId: '1:139914767846:android:ee5aa2637e6eb6ca607a27',
    messagingSenderId: '139914767846',
    projectId: 'project-f11e5e0e-e3c4-4083-bb6',
    storageBucket: 'project-f11e5e0e-e3c4-4083-bb6.firebasestorage.app',
  );
}
