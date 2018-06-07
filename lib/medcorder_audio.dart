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

  void setCallBack(dynamic _callback) {
    callback = _callback;
  }

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

  void _onEvent(dynamic event) {
    callback(event);
  }

  void _onError(dynamic error) {
    print('CHannel Error');
  }
}
