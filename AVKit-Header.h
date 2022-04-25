#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

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

@interface AVSampleBufferDisplayLayer (Private)
- (CGRect)videoRect;
- (void)postVideoRectDidChangeNotification;
@end

@interface AVPictureInPictureControllerContentSource (Private)
@property(nonatomic, readonly) id <AVPictureInPictureContentSource> source;
@property(assign) bool hasInitialRenderSize;
@end

@interface AVPictureInPictureController (Private)
@property(nonatomic, readonly) id <AVPictureInPictureContentSource> source;
@property(nonatomic, retain) AVPictureInPictureControllerContentSource *contentSource API_AVAILABLE(ios(15.0)); // retain -> strong on iOS 15
@property(nonatomic, retain) id prerollDelegate;
@property(nonatomic, readonly) AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;
@property(nonatomic, readonly) AVObservationController *observationController;
- (instancetype)initWithContentSource:(AVPictureInPictureControllerContentSource *)contentSource API_AVAILABLE(ios(15.0));
- (AVSampleBufferDisplayLayerPlayerController *)_sbdlPlayerController;
- (void)contentSourceVideoRectInWindowChanged;
- (void)sampleBufferDisplayLayerRenderSizeDidChangeToSize:(CGSize)renderSize;
- (void)sampleBufferDisplayLayerDidAppear;
- (void)sampleBufferDisplayLayerDidDisappear;
- (void)_updateEnqueuedBufferDimensions;
- (void)_observePlayerLayer:(id <AVPictureInPictureContentSource>)playerLayerContentSource; // pre iOS 15.0b2
- (void)_startObservationsForContentSource:(AVPictureInPictureControllerContentSource *)controllerContentSource API_AVAILABLE(ios(15.0));
- (void)_startObservingPlayerLayerContentSource:(id <AVPictureInPictureContentSource>)playerLayerContentSource;
- (void)_startObservingSampleBufferDisplayLayerContentSource:(id <AVPictureInPictureContentSource>)contentSource;
@end