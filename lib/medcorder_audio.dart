import 'dart:async';
import 'package:flutter/services.dart';

class MedcorderAudio {
  static const MethodChannel platform = const MethodChannel('medcorder_audio');

  static const EventChannel eventChannel =
      const EventChannel('medcorder_audio_events');

  dynamic callback;

  MedcorderAudio() {
    eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  /// Callback function
  ///
  /// ```dart
  ///    void Function(dynamic event)
  /// ```
  ///
  /// Event has [code] field for get event code
  ///
  /// ## Available events:
  /// ### recording events
  /// | Key      | Type           | Description  |
  /// | ------------- |:-------------:| ---------:|
  /// |'code'	|String	|'recording', |
  /// |'url'	|String	|recording file url|
  /// |'peakPowerForChannel'	|double	|peak power for channel|
  /// |'currentTime'	|double	|recording time in seconds|
  ///
  /// ### playing events
  /// | Key      | Type           | Description  |
  /// | ------------- |:-------------:| ---------:|
  /// |'code'	|String	|'playing', 'audioPlayerDidFinishPlaying' |
  /// |'url'	|String	|playing file url|
  /// |'currentTime'	|double	|playing time in seconds|
  /// |'duration'	|double	|playing file duration|
  void setCallBack(dynamic _callback) {
    callback = _callback;
  }

  /// iOS only. open PlayAndRecord audio session
  Future<String> setAudioSettings() async {
    try {
      final String result = await platform.invokeMethod('setAudioSettings');
      print('setAudioSettings: ' + result);
      return result;
    } catch (e) {
      print('setAudioSettings: fail');
      return 'fail';
    }
  }

  /// iOS only. close PlayAndRecord audio session
  Future<String> backAudioSettings() async {
    try {
      final String result = await platform.invokeMethod('backAudioSettings');
      print('backAudioSettings: ' + result);
      return result;
    } catch (e) {
      print('backAudioSettings: fail');
      return 'fail';
    }
  }

  /// Start record audio file to app documents path
  Future<String> startRecord(String file) async {
    try {
      final String result = await platform.invokeMethod('startRecord', file);
      print('startRecord: ' + result);
      return result;
    } catch (e) {
      print('startRecord: fail');
      return 'fail';
    }
  }

  /// Stop audio recording process
  Future<String> stopRecord() async {
    try {
      final String result = await platform.invokeMethod('stopRecord');
      print('stopRecord: ' + result);
      return result;
    } catch (e) {
      print('stopRecord: fail');
      return 'fail';
    }
  }

  /// Check if you have recording audio permissions
  Future<String> checkMicrophonePermissions() async {
    try {
      final String result =
          await platform.invokeMethod('checkMicrophonePermissions');
      print('stopPlay: ' + result);
      return result;
    } catch (e) {
      print('stopPlay: fail');
      return 'fail';
    }
  }

  /// Start audio playing for file with position
  Future<String> startPlay(dynamic params) async {
    try {
      final String result = await platform.invokeMethod('startPlay', params);
      print('startPlay: ' + result);
      return result;
    } catch (e) {
      print('startPlay: fail');
      return 'fail';
    }
  }

  /// Stop audio playing
  Future<String> stopPlay() async {
    try {
      final String result = await platform.invokeMethod('stopPlay');
      print('stopPlay: ' + result);
      return result;
    } catch (e) {
      print('stopPlay: fail');
      return 'fail';
    }
  }

  /// For receiving plugin events you need assign callback function
  void _onEvent(dynamic event) {
    callback(event);
  }

  void _onError(dynamic error) {
    print('CHannel Error');
  }
}
