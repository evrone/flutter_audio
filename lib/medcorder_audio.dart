import 'dart:async';

import 'package:flutter/services.dart';

class MedcorderAudio {
  static const MethodChannel _channel =
      const MethodChannel('medcorder_audio');

  static Future<String> get platformVersion =>
      _channel.invokeMethod('getPlatformVersion');
}
