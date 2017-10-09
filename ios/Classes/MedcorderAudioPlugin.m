#import "MedcorderAudioPlugin.h"
#import <AVFoundation/AVFoundation.h>
#import <Flutter/Flutter.h>

@implementation MedcorderAudioPlugin

NSURL *temporaryRecFile;
AVAudioRecorder *recorder;
AVAudioPlayer *player;
NSTimer *recordTimer;
NSTimer *playTimer;
NSString *recordingFolder;
FlutterEventSink _eventSink;

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    if(playTimer != nil && [playTimer isValid]){
        [playTimer invalidate];
        playTimer = nil;
    };
    
    [self updatePlayingWithCode: @"audioPlayerDidFinishPlaying"];
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error{
    
}

/* audioRecorderDidFinishRecording:successfully: is called when a recording has been finished or stopped. This method is NOT called if the recorder is stopped due to an interruption. */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error{
    
}

- (FlutterError*)onListenWithArguments:(id)arguments
                             eventSink:(FlutterEventSink)eventSink {
    _eventSink = eventSink;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    _eventSink = nil;
    return nil;
}

- (void)sendFlutterEvent: (NSDictionary *) dict {
    if (!_eventSink) return;
    /*
     _eventSink([FlutterError errorWithCode:@"UNAVAILABLE"
     message:@"Charging status unavailable"
     details:nil]);
     */
    
    _eventSink(dict);
    
}

- (bool)setAudioSettings {
    // Prepare the audio session
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error])
    {
        NSLog(@"Error setting session category: %@", error.localizedFailureReason);
        return NO;
    }
    
    
    if (![session setActive:YES error:&error])
    {
        NSLog(@"Error activating audio session: %@", error.localizedFailureReason);
        return NO;
    }
    
    return session.inputAvailable;
    
}

- (void)checkMicrophonePermissions:(void (^)(BOOL allowed))completion {
    AVAudioSessionRecordPermission status = [[AVAudioSession sharedInstance] recordPermission];
    switch (status) {
        case AVAudioSessionRecordPermissionGranted:
            if (completion) {
                completion(YES);
            }
            break;
        case AVAudioSessionRecordPermissionDenied:
        {
            // Optionally show alert with option to go to Settings
            
            //if (completion) {
            //    completion(NO);
            //}
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                if (granted && completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(granted);
                    });
                }
            }];
        }
            break;
        case AVAudioSessionRecordPermissionUndetermined:
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                if (granted && completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(granted);
                    });
                }
            }];
            break;
    }
    
}

- (void)backAudioSettings {
    // Prepare the audio session
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error])
    {
        NSLog(@"Error setting session category: %@", error.localizedFailureReason);
        return;
    }
    
    
    if (![session setActive:NO error:&error])
    {
        NSLog(@"Error activating audio session: %@", error.localizedFailureReason);
        return;
    }
    
    return;
    
}

- (NSString *) dateString
{
    // return a formatted string for a file name
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    formatter.dateFormat = @"ddMMMYY_hhmmssa";
    return [[formatter stringFromDate:[NSDate date]] stringByAppendingString:@".caf"];
    
}

- (bool)startRecord:(NSString*) toFile {
    NSError *error;
    
    // Recording settings
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    
    [settings setValue: [NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [settings setValue: [NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
    [settings setValue: [NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    [settings setValue: [NSNumber numberWithInt:32] forKey:AVLinearPCMBitDepthKey];
    [settings setValue: [NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [settings setValue: [NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    [settings setValue:  [NSNumber numberWithInt: AVAudioQualityMax] forKey:AVEncoderAudioQualityKey];
    
    NSArray *searchPaths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath_ = [searchPaths objectAtIndex: 0];
    
    recordingFolder = documentPath_;
    
    NSString *pathToSave = [documentPath_ stringByAppendingPathComponent: [toFile stringByAppendingString:@".caf"]];
    
    // File URL
    NSURL *url = [NSURL fileURLWithPath:pathToSave];//FILEPATH];
    
    // Create recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    if (!recorder)
    {
        NSLog(@"Error establishing recorder: %@", error.localizedFailureReason);
        return NO;
    }
    
    // Initialize degate, metering, etc.
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    
    if (![recorder prepareToRecord])
    {
        NSLog(@"Error: Prepare to record failed");
        //[self say:@"Error while preparing recording"];
        return NO;
    }
    
    if (![recorder record])
    {
        NSLog(@"Error: Record failed");
        //  [self say:@"Error while attempting to record audio"];
        return NO;
    }
    
    // Set a timer to monitor levels, current time
    recordTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(selectorRecording) userInfo:nil repeats:YES];
    
    return YES;
}

- (void)updateRecordingWithCode:(NSString*) code {
    [recorder updateMeters];
    NSNumber *peakPowerForChannel = [NSNumber numberWithFloat: [recorder peakPowerForChannel:0]];
    NSNumber *currentTime = [NSNumber numberWithDouble:[recorder currentTime]];
    NSString *url = [[recorder url] absoluteString];
    [self sendFlutterEvent: @{
                              @"code" : code,
                              @"url" : url,
                              @"peakPowerForChannel" : peakPowerForChannel,
                              @"currentTime" : currentTime
                              }];
}

- (void)updatePlayingWithCode:(NSString*) code{
    NSNumber *currentTime = [[NSNumber alloc] initWithDouble: [player currentTime]];
    NSNumber *duration = [[NSNumber alloc] initWithDouble: [player duration]];
    NSString *url = [[player url] absoluteString];
    [self sendFlutterEvent:@{
                             @"code" : code,
                             @"url" : url,
                             @"currentTime" : currentTime,
                             @"duration": duration
                             }];
}

- (void)selectorPlaying{
    [self updatePlayingWithCode: @"playing"];
}

- (void)selectorRecording{
    [self updateRecordingWithCode: @"recording"];
}

- (void)stopRecord{
    if(recordTimer != nil && [recordTimer isValid]){
        [recordTimer invalidate];
        recordTimer = nil;
    };
    if ([recorder isRecording]){
        [recorder stop];
    }
    
}

- (void)startPlay:(NSString*) fromFile :(double) position {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath_ = [searchPaths objectAtIndex: 0];
    NSMutableArray *arrayListOfRecordSound;
    NSError *error;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath: recordingFolder])
    {
        
        arrayListOfRecordSound=[[NSMutableArray alloc]initWithArray:[fileManager  contentsOfDirectoryAtPath:documentPath_ error:nil]];
        
        NSLog(@"====%@",arrayListOfRecordSound);
        
    }
    
    NSString  *selectedSound =  [documentPath_ stringByAppendingPathComponent:[fromFile stringByAppendingString:@".caf"]];
    
    if([fileManager fileExistsAtPath:selectedSound]){
        NSLog(@"fileExistsAtPath");
    }
    
    NSLog(@"selectedSound=%@",selectedSound);
    
    NSURL   *url =[NSURL fileURLWithPath:selectedSound];
    
    //Start playback
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    
    if (!player)
    {
        NSLog(@"Error establishing player for %@: %@", recorder.url, error.localizedFailureReason);
        return;
    }
    
    player.delegate = self;
    
    // Change audio session for playback
    if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error])
    {
        NSLog(@"Error updating audio session: %@", error.localizedFailureReason);
        return;
    }
    
    NSLog(@"Playing recording...");
    
    [player setCurrentTime: position];
    [player prepareToPlay];
    // Set a timer to monitor levels, current time
    if(playTimer != nil){
        [playTimer invalidate];
        playTimer = nil;
    };
    playTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(selectorPlaying) userInfo:nil repeats:YES];
    [player play];
    
}

-(void) stopPlay{
    if(playTimer != nil){
        [playTimer invalidate];
        playTimer = nil;
    };
    
    if ([player isPlaying]){
        [player stop];
    }
    
    [self updatePlayingWithCode: @"audioPlayerDidFinishPlaying"];
}


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"medcorder_audio"
            binaryMessenger:[registrar messenger]];
  MedcorderAudioPlugin* instance = [[MedcorderAudioPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterEventChannel* chargingChannel = [FlutterEventChannel
                                            eventChannelWithName:@"medcorder_audio_events"
                                            binaryMessenger:[registrar messenger]];
    [chargingChannel setStreamHandler:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"setAudioSettings" isEqualToString:call.method]) {
        [self setAudioSettings];
        result(@"OK");
    } else if ([@"backAudioSettings" isEqualToString:call.method]) {
        [self backAudioSettings];
        result(@"OK");
    } else if ([@"startRecord" isEqualToString:call.method]) {
        [self startRecord: call.arguments];
        result(@"OK");
    } else if ([@"stopRecord" isEqualToString:call.method]) {
        [self stopRecord];
        result(@"OK");
    } else if ([@"startPlay" isEqualToString:call.method]) {
        NSDictionary *dict = call.arguments;
        NSString *file = [dict valueForKey:@"file"];
        NSNumber *pos = [dict valueForKey:@"position"];
        [self startPlay: file :[pos doubleValue]];
        result(@"OK");
    } else if ([@"stopPlay" isEqualToString:call.method]) {
        [self stopPlay];
        result(@"OK");
    } else if ([@"checkMicrophonePermissions" isEqualToString:call.method]) {
        [self checkMicrophonePermissions:^(BOOL allowed) {
            if (allowed) {
                result(@"OK");
            }else{
                result(@"NO");
            }
        }];
    }else {
        result(FlutterMethodNotImplemented);
    }
}

@end
