import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  // Firebase project configuration for this app.
  //
  // Replace the placeholder values below with your own Firebase project config
  // (from Firebase Console > Project settings > General > Your apps) before
  // running the app locally. Until then the app initializes against these
  // placeholders so it compiles, tests, and boots without a real project.
  static const firebaseConfig = FirebaseOptions(
    apiKey: 'AIzaSyBxPlaceholderApiKey1234567890',
    authDomain: 'placeholder-project.firebaseapp.com',
    databaseURL: 'https://placeholder-project-default-rtdb.firebaseio.com',
    projectId: 'placeholder-project',
    storageBucket: 'placeholder-project.appspot.com',
    messagingSenderId: '000000000000',
    appId: '1:000000000000:web:0000000000000000000000',
  );

  static Future<FirebaseApp> initializeFirebase() async {
    return await Firebase.initializeApp(options: firebaseConfig);
  }
}
