#import <AVKit/AVKit.h>
#import <Foundation/Foundation.h>
#import "../PSHeader/iOSVersions.h"

@protocol AVPictureInPictureContentSource <NSObject>
@end

@protocol AVPictureInPictureSampleBufferPlaybackDelegate <NSObject>
@end

@interface AVPlayerController : UIResponder
@end

@interface AVObservationController : NSObject
- (void)startObservingNotificationForName:(NSString *)name object:(id)object notificationCenter:(id)notificationCenter observationHandler:(id)observationHandler;
@end

@interface AVSampleBufferDisplayLayerPlayerController : AVPlayerController
@property(assign, nonatomic) CGSize enqueuedBufferDimensions;
@end

@interface AVPictureInPictureControllerContentSource : NSObject
@property(nonatomic, readonly) id <AVPictureInPictureContentSource> source;
@property(nonatomic, readonly) AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;
@property(assign) bool hasInitialRenderSize;
@end

@interface AVSampleBufferDisplayLayer (Additions)
- (CGRect)videoRect;
- (void)postVideoRectDidChangeNotification;
@end

@interface AVPictureInPictureController (Additions)
@property(nonatomic, readonly) id <AVPictureInPictureContentSource> source;
@property(nonatomic, nullable, readonly) AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;
@property(nonatomic, retain, nullable) AVPictureInPictureControllerContentSource *contentSource; // retain -> strong on iOS 15
@property(nonatomic, readonly) AVObservationController *observationController;
- (AVSampleBufferDisplayLayerPlayerController *)_sbdlPlayerController;
- (void)contentSourceVideoRectInWindowChanged;
- (void)_updateEnqueuedBufferDimensions;
- (void)_observePlayerLayer:(id <AVPictureInPictureContentSource>)playerLayerContentSource; // pre iOS 15.0b2
- (void)_startObservationsForContentSource:(AVPictureInPictureControllerContentSource *)controllerContentSource;
- (void)_startObservingPlayerLayerContentSource:(id <AVPictureInPictureContentSource>)playerLayerContentSource;
- (void)_startObservingSampleBufferDisplayLayerContentSource:(id <AVPictureInPictureContentSource>)contentSource;
@end

int AVObservationController_stopAllObservation_override = 0;

%hook AVPictureInPictureControllerContentSource

%property(assign) bool hasInitialRenderSize;

- (id)initWithSampleBufferDisplayLayer:(AVSampleBufferDisplayLayer *)sampleBufferDisplayLayer initialRenderSize:(CGSize)initialRenderSize playbackDelegate:(id)playbackDelegate {
    self = %orig;
    if (self)
        self.hasInitialRenderSize = true;
    return self;
}

%end

%hook AVPictureInPictureController

- (id)initWithContentSource:(AVPictureInPictureControllerContentSource *)controllerContentSource {
    self = %orig;
    if (self) {
        id source = controllerContentSource.source;
        if ([source isKindOfClass:[AVSampleBufferDisplayLayer class]])
            [self _startObservationsForContentSource:controllerContentSource];
    }
    return self;
}

- (void)setContentSource:(AVPictureInPictureControllerContentSource *)controllerContentSource {
    AVObservationController_stopAllObservation_override = 2;
    %orig;
    AVObservationController_stopAllObservation_override = 0;
    id <AVPictureInPictureContentSource> contentSource = self.source;
    if ([contentSource isKindOfClass:[AVSampleBufferDisplayLayer class]])
        [self _startObservationsForContentSource:controllerContentSource];
}

%new
- (void)_updateEnqueuedBufferDimensions {
    AVPictureInPictureControllerContentSource *controllerContentSource = self.contentSource;
    AVSampleBufferDisplayLayer *displayLayer = controllerContentSource.sampleBufferDisplayLayer;
    if (displayLayer) {
        CGRect videoRect = [displayLayer videoRect];
        AVSampleBufferDisplayLayerPlayerController *sbdlPlayerController = [self _sbdlPlayerController];
        sbdlPlayerController.enqueuedBufferDimensions = videoRect.size;
        [self contentSourceVideoRectInWindowChanged];
    }
}

%new
- (void)_startObservingPlayerLayerContentSource:(id <AVPictureInPictureContentSource>)contentSource {
    [self _observePlayerLayer:contentSource];
}

%new
- (void)_startObservationsForContentSource:(AVPictureInPictureControllerContentSource *)controllerContentSource {
    id source = controllerContentSource.source;
    if ([source isKindOfClass:[AVPlayerLayer class]])
        [self _startObservingPlayerLayerContentSource:source];
    else if ([source isKindOfClass:[AVSampleBufferDisplayLayer class]] && ![controllerContentSource hasInitialRenderSize])
        [self _startObservingSampleBufferDisplayLayerContentSource:source];
}

%new
- (void)_startObservingSampleBufferDisplayLayerContentSource:(id <AVPictureInPictureContentSource>)contentSource {
    AVObservationController *observationController = self.observationController;
    [observationController startObservingNotificationForName:@"AVSampleBufferDisplayLayerVideoRectDidChangeNotification" object:contentSource notificationCenter:nil observationHandler:^(void) {
        [self _updateEnqueuedBufferDimensions];
    }];
    [self _updateEnqueuedBufferDimensions];
}

%end

%hook AVObservationController

- (void)stopAllObservation {
    if (--AVObservationController_stopAllObservation_override == 1) return;
    %orig;
}

%end

%hook AVSampleBufferDisplayLayer

- (void)setBounds:(CGRect)bounds {
    %orig;
    [self postVideoRectDidChangeNotification];
}

- (void)_updateLayerTreeGeometryWithVideoGravity:(id)videoGravity bounds:(CGRect)bounds presentationSize:(CGSize)presentationSize {
    %orig;
    [self postVideoRectDidChangeNotification];
}

%new
- (void)postVideoRectDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AVSampleBufferDisplayLayerVideoRectDidChangeNotification" object:self];
}

%end

%ctor {
    if (!IS_IOS_OR_NEWER(iOS_14_0) || IS_IOS_OR_NEWER(iOS_15_0))
        return;
    %init;
}