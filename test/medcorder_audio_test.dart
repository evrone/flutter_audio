import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medcorder_audio/medcorder_audio.dart';

void main() {
  const MethodChannel channel = MethodChannel('medcorder_audio');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  /*
  test('getPlatformVersion', () async {
    expect(await MedcorderAudio.platformVersion, '42');
  });
  */
}
