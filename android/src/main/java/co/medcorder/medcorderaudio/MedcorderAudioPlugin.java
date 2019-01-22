package co.medcorder.medcorderaudio;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.net.Uri;
import android.util.Log;
import android.support.v4.content.ContextCompat;

import java.io.File;
import java.util.HashMap;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * MedcorderAudioPlugin
 */
public class MedcorderAudioPlugin implements MethodCallHandler, EventChannel.StreamHandler {
  /**
   * Plugin registration.
   */
  private static final String TAG = "MEDCORDER";
  private EventChannel.EventSink eventSink;

  private Context context;
  private Timer recordTimer;
  private Timer playTimer;

  private MediaRecorder recorder;
  private String currentOutputFile;
  private boolean isRecording = false;
  private double recorderSecondsElapsed;

  private MediaPlayer player;
  private String currentPlayingFile;
  private boolean isPlaying = false;
  private double playerSecondsElapsed;

  private Activity activity;

  MedcorderAudioPlugin(Activity _activity){
    this.activity = _activity;
    this.context = this.activity.getApplicationContext();
  }

  public static void registerWith(Registrar registrar) {
    final MedcorderAudioPlugin plugin = new MedcorderAudioPlugin(registrar.activity());

    final MethodChannel methodChannel = new MethodChannel(registrar.messenger(), "medcorder_audio");
    methodChannel.setMethodCallHandler(plugin);

    final EventChannel eventChannel = new EventChannel(registrar.messenger(), "medcorder_audio_events");
    eventChannel.setStreamHandler(plugin);

  }

  @Override
  public void onListen(Object arguments, EventChannel.EventSink events) {
    eventSink = events;
  }

  @Override
  public void onCancel(Object arguments) {
    eventSink = null;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("setAudioSettings")) {
      result.success("OK");
    } else if (call.method.equals("backAudioSettings")) {
      result.success("OK");
    } else if (call.method.equals("startRecord")) {
      result.success(startRecord((String) call.arguments) ? "OK" : "FAIL");
    } else if (call.method.equals("stopRecord")) {
      result.success(stopRecord() ? "OK" : "FAIL");
    } else if (call.method.equals("startPlay")) {
      HashMap params = (HashMap) call.arguments;
      String fileName = (String) params.get("file");
      double position = (double) params.get("position");
      result.success(startPlay(fileName, position) ? "OK" : "FAIL");
    } else if (call.method.equals("stopPlay")) {
      stopPlay();
      result.success("OK");
    } else if (call.method.equals("checkMicrophonePermissions")) {
      result.success(checkMicrophonePermissions() ? "OK" : "NO");
    } else {
      result.notImplemented();
    }
  }
    
  private void sendEvent(Object o){
    if (eventSink != null){
      eventSink.success(o);
    }
  }

  private boolean checkMicrophonePermissions(){
    int permissionCheck = ContextCompat.checkSelfPermission(activity,
            Manifest.permission.RECORD_AUDIO);
    boolean permissionGranted = permissionCheck == PackageManager.PERMISSION_GRANTED;
    return permissionGranted;
  }

  private boolean startRecord(String fileName){
    Log.d(TAG, "startRecord:" + fileName);
    recorder = new MediaRecorder();
    try {
      currentOutputFile = activity.getApplicationContext().getFilesDir() + "/" + fileName + ".aac";
      recorder.setAudioSource(MediaRecorder.AudioSource.MIC);
      int outputFormat = MediaRecorder.OutputFormat.AAC_ADTS;
      recorder.setOutputFormat(outputFormat);
      int audioEncoder = MediaRecorder.AudioEncoder.AAC;
      recorder.setAudioEncoder(audioEncoder);
      recorder.setAudioSamplingRate(16000);
      recorder.setAudioChannels(2);
      recorder.setAudioEncodingBitRate(32000);
      recorder.setOutputFile(currentOutputFile);
    }
    catch(final Exception e) {
      return false;
    }

    try {
      recorder.prepare();
      recorder.start();
      isRecording = true;
      startRecordTimer();
    } catch (final Exception e) {
      return false;
    }

    return true;
  }

  public boolean stopRecord(){
    if (!isRecording){
      // sendEvent("recordingFinished");
      return true;
    }

    stopRecordTimer();
    isRecording = false;

    try {
      recorder.stop();
      recorder.release();
    }
    catch (final RuntimeException e) {
      return false;
    }
    finally {
      recorder = null;
    }

    // sendEvent("recordingFinished");
    return true;
  }

  private void startRecordTimer(){
    stopRecordTimer();
    recordTimer = new Timer();
    recordTimer.scheduleAtFixedRate(new TimerTask() {
      @Override
      public void run() {
        updateRecordingWithCode("recording");
        recorderSecondsElapsed = recorderSecondsElapsed + 0.1;
      }
    }, 0, 100);
  }

  private void stopRecordTimer(){
    recorderSecondsElapsed = 0.0;
    if (recordTimer != null) {
      recordTimer.cancel();
      recordTimer.purge();
      recordTimer = null;
    }
  }

  private void startPlayTimer(){
    stopPlayTimer();
    playTimer = new Timer();
    playTimer.scheduleAtFixedRate(new TimerTask() {
      @Override
      public void run() {
        updatePlayingWithCode("playing");
        playerSecondsElapsed = playerSecondsElapsed + 0.1;
      }
    }, 0, 100);
  }

  private void stopPlayTimer(){
    playerSecondsElapsed = 0.0;
    if (playTimer != null) {
      playTimer.cancel();
      playTimer.purge();
      playTimer = null;
    }
  }

  private boolean startPlay(String fileName, double duration){
    try{
      if (player != null && player.isPlaying()){
        player.stop();
        player.release();
      }
    }catch(Exception e){

    }finally {
      player = null;
    }

    currentPlayingFile = activity.getApplicationContext().getFilesDir() + "/" + fileName + ".aac";
    File file = new File(currentPlayingFile);
    if (file.exists()) {
      Uri uri = Uri.fromFile(file);
      player =  MediaPlayer.create(this.context, uri);
      player.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
        boolean callbackWasCalled = false;

        @Override
        public synchronized void onCompletion(MediaPlayer mp) {
          if (callbackWasCalled) return;
          callbackWasCalled = true;
          stopPlayTimer();
          updatePlayingWithCode("audioPlayerDidFinishPlaying");
        }
      });
      player.seekTo(new Double(duration).intValue() * 1000);
      player.start();
      startPlayTimer();
      isPlaying = true;
    }else{
      return false;
    }

    return true;
  }

  private boolean stopPlay(){
    try{
      if (player != null && player.isPlaying()){
        player.stop();
        stopPlayTimer();
        updatePlayingWithCode("audioPlayerDidFinishPlaying");
        player.release();
      }
    }catch(Exception e){
      Log.i("MEDCORDER_AUDIO", "Exception:" + e.getMessage());
    }
    finally {
      player = null;
    }

    isPlaying = false;
    return true;
  }

  private void updateRecordingWithCode(String code){
    HashMap<String, Object> body = new HashMap<String, Object>();
    body.put("code", code);
    body.put("url", currentOutputFile);
    body.put("peakPowerForChannel", (double) recorder.getMaxAmplitude());
    body.put("currentTime", recorderSecondsElapsed);
    sendEvent(body);
  }

  private void updatePlayingWithCode(String code){
    HashMap<String, Object> body = new HashMap<String, Object>();
    body.put("code", code);
    if (player.isPlaying()) {
      body.put("url", currentPlayingFile);
      body.put("currentTime", (double) new Double(player.getCurrentPosition()) / 1000.0);
      body.put("duration", (double) new Double(player.getDuration()) / 1000.0);
    }
    sendEvent(body);
  }

}
