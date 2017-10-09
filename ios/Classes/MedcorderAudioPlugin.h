#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>

@interface MedcorderAudioPlugin : NSObject<FlutterPlugin,AVAudioSessionDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, FlutterStreamHandler>
@end
