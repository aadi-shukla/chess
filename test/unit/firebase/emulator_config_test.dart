import 'package:chess/core/firebase/emulator_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emulator ports are defined', () {
    expect(EmulatorConfig.authPort, 9099);
    expect(EmulatorConfig.firestorePort, 8080);
    expect(EmulatorConfig.functionsPort, 5001);
  });

  test('emulator host resolves on test platform', () {
    final host = EmulatorConfig.host;
    expect(host, isNotEmpty);
    if (defaultTargetPlatform == TargetPlatform.android) {
      expect(host, '10.0.2.2');
    }
  });
}
