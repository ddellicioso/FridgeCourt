// Placeholder so the project compiles without running `flutterfire
// configure` yet. kDemoMode (see lib/demo_mode.dart) skips
// Firebase.initializeApp() entirely, so this is never actually read right
// now — it only exists to satisfy the import/type in main.dart.
//
// Once you run `flutterfire configure` for real, let it OVERWRITE this
// file — that's expected and correct, it replaces this stub with your
// real per-platform Firebase config.
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'firebase_options.dart is still the placeholder — run '
      '`flutterfire configure` to generate the real one before turning '
      'kDemoMode off.',
    );
  }
}
