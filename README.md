# medcorder_audio

## Flutter record/play audio plugin.

<a href="https://evrone.com/?utm_source=something">
  <img src="https://evrone.com/logo/evrone-sponsored-logo.png"
       alt="Sponsored by Evrone" width="231">
</a>

### Developed for [Evrone.com](https://evrone.com/)
### Funded by David Weekly [dweek.ly](http://dweek.ly/)

## Getting Started

For help getting started with Flutter, view our online
[documentation](http://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/platform-plugins/#edit-code).

With medcorder_audio plugin you can integrate record/play audio support into your flutter app for iOS or Android.

## Plugin functions
### setAudioSettings
**Future<String> setAudioSettings()**\
iOS only. open PlayAndRecord audio session\
**returns: 'OK', 'FAIL'**

### backAudioSettings
**Future<String> backAudioSettings()**\
iOS only. close PlayAndRecord audio session\
**returns: 'OK', 'FAIL'**

### startRecord
**Future<String> startRecord(String fileId)**\
start record audio file to app documents path\
**returns: 'OK', 'FAIL'**

### stopRecord
**Future<String> stopRecord()**\
stop audio recording process\
**returns: 'OK', 'FAIL'**

### checkMicrophonePermissions
**Future<String> checkMicrophonePermissions()**\
check if you have recording audio permissions\
**returns: 'OK', 'NO'**

### startPlay
**Future<String> startPlay(dynamic params) async**\
start audio playing for file with position\
**returns: 'OK', 'FAIL'**\
**params: Map<String, String>**

| Key      | Type           | Description  |
| ------------- |:-------------:| ---------:|
| file   | String        | String file Id |
| position   | double        | play start position in seconds |

### stopPlay
**Future<String> stopPlay()**\
stop audio playing\
**returns: 'OK', 'FAIL'**\

## Plugin events
for recieving plugin events you need assign callback function\
**void _onEvent(dynamic event) {...}**

### recording events
| Key      | Type           | Description  |
| ------------- |:-------------:| ---------:|
|'code'	|String	|'recording', |
|'url'	|String	|recording file url|
|'peakPowerForChannel'	|double	|peak power for channel|
|'currentTime'	|double	|recording time in seconds|

### playing events
| Key      | Type           | Description  |
| ------------- |:-------------:| ---------:|
|'code'	|String	|'playing', 'audioPlayerDidFinishPlaying' |
|'url'	|String	|playing file url|
|'currentTime'	|double	|playing time in seconds|
|'duration'	|double	|playing file duration|