import 'package:chess/main_bootstrap.dart';

/// Production flavor entry point.
///
/// Run:
/// `flutter run -t lib/main_prod.dart --dart-define-from-file=config/env/prod.json`
Future<void> main() => runChessApp();
