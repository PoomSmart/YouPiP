#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

// TODO: Remove when using iOS 15 SDK
@protocol AVPictureInPictureSampleBufferPlaybackDelegate <NSObject>
@end

// TODO: Remove when using iOS 15 SDK
@protocol AVPictureInPictureContentSource <NSObject>
@end

@interface AVPlayerController : UIResponder
@end

@interface AVObservationController : NSObject
- (void)startObservingNotificationForName:(NSNotificationName)name object:(id)object notificationCenter:(id)notificationCenter observationHandler:(id)observationHandler;
@end

@interface AVSampleBufferDisplayLayerPlayerController : AVPlayerController
@property(assign, nonatomic) CGSize enqueuedBufferDimensions;
@end

@interface AVSampleBufferDisplayLayer (Additions)
- (CGRect)videoRect;
- (void)postVideoRectDidChangeNotification;
@end

// TODO: Remove when using iOS 15 SDK
@interface AVPictureInPictureControllerContentSource : NSObject
@property(nonatomic, readonly) id <AVPictureInPictureContentSource> source;
@property(nonatomic, readonly) AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;
@property(assign) bool hasInitialRenderSize;
- (instancetype)initWithSampleBufferDisplayLayer:(AVSampleBufferDisplayLayer *)sampleBufferDisplayLayer playbackDelegate:(id <AVPictureInPictureSampleBufferPlaybackDelegate>)playbackDelegate;
- (instancetype)initWithPlayerLayer:(AVPlayerLayer *)playerLayer;
@end

// TODO: Remove when using iOS 15 SDK
@interface AVPictureInPictureController (Additions)
@property(nonatomic, readonly) id <AVPictureInPictureContentSource> source;
@property(nonatomic, retain) AVPictureInPictureControllerContentSource *contentSource; // retain -> strong on iOS 15
@property(nonatomic, retain) id prerollDelegate;
@property(nonatomic, readonly) AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;
@property(nonatomic, readonly) AVObservationController *observationController;
- (instancetype)initWithContentSource:(AVPictureInPictureControllerContentSource *)contentSource;
- (AVSampleBufferDisplayLayerPlayerController *)_sbdlPlayerController;
- (void)contentSourceVideoRectInWindowChanged;
- (void)sampleBufferDisplayLayerRenderSizeDidChangeToSize:(CGSize)renderSize;
- (void)sampleBufferDisplayLayerDidAppear;
- (void)_updateEnqueuedBufferDimensions;
- (void)_observePlayerLayer:(id <AVPictureInPictureContentSource>)playerLayerContentSource; // pre iOS 15.0b2
- (void)_startObservationsForContentSource:(AVPictureInPictureControllerContentSource *)controllerContentSource;
- (void)_startObservingPlayerLayerContentSource:(id <AVPictureInPictureContentSource>)playerLayerContentSource;
- (void)_startObservingSampleBufferDisplayLayerContentSource:(id <AVPictureInPictureContentSource>)contentSource;
@end