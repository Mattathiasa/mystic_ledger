import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase configuration for Mystic Ledger.
///
/// Only web needs this: mobile builds inherit their config from the native
/// files (android/app/google-services.json / ios GoogleService-Info.plist) and
/// never touch this class.
///
/// There is no *Web* app registered in the Firebase console yet, so the web
/// values are placeholders: the app boots and renders, but sign-in stays
/// broken until they are replaced. Paste the real Web app config from Firebase
/// console → Project settings → Your apps → Web app.
class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    // TODO: replace with the real web API key and web App ID.
    apiKey:            'REPLACE_WITH_WEB_API_KEY',
    appId:             'REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: '137233966873',
    projectId:         'mystic-ledger-a1216',
    authDomain:        'mystic-ledger-a1216.firebaseapp.com',
    storageBucket:     'mystic-ledger-a1216.firebasestorage.app',
  );
}
