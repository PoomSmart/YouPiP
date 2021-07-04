#if !SIDELOADED
#define tweakIdentifier @"com.ps.youpip"
#import "../PSPrefs/PSPrefs.x"
#endif

#import "Header.h"
#import "../PSHeader/iOSVersions.h"

BOOL SampleBufferWork = YES;

static NSNotificationName AVSampleBufferDisplayLayerVideoRectDidChangeNotification = @"AVSampleBufferDisplayLayerVideoRectDidChangeNotification";

int AVObservationController_stopAllObservation_override = 0;

%group AVKit_iOS14_2_Up

%hook AVPictureInPictureControllerContentSource

%property(assign) bool hasInitialRenderSize;

- (id)initWithSampleBufferDisplayLayer:(AVSampleBufferDisplayLayer *)sampleBufferDisplayLayer initialRenderSize:(CGSize)initialRenderSize playbackDelegate:(id)playbackDelegate {
    self = %orig;
    if (self)
        self.hasInitialRenderSize = true;
    return self;
}

%end

%end

%group AVKit_preiOS14_2

%hook AVPictureInPictureControllerContentSource

%property(assign) bool hasInitialRenderSize;

%new
- (instancetype)initWithSampleBufferDisplayLayer:(AVSampleBufferDisplayLayer *)sampleBufferDisplayLayer initialRenderSize:(CGSize)initialRenderSize playbackDelegate:(id <AVPictureInPictureSampleBufferPlaybackDelegate>)playbackDelegate {
    return [self initWithSampleBufferDisplayLayer:sampleBufferDisplayLayer playbackDelegate:playbackDelegate];
}

%end

%hook AVPictureInPictureController

%new
- (void)setCanStartPictureInPictureAutomaticallyFromInline:(BOOL)canStartFromInline {

}

%end

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
        CGRect videoRect = [displayLayer respondsToSelector:@selector(videoRect)] ? [displayLayer videoRect] : displayLayer.bounds;
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
    [observationController startObservingNotificationForName:AVSampleBufferDisplayLayerVideoRectDidChangeNotification object:contentSource notificationCenter:nil observationHandler:^(void) {
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
    [[NSNotificationCenter defaultCenter] postNotificationName:AVSampleBufferDisplayLayerVideoRectDidChangeNotification object:self];
}

%end

%ctor {
    if (!IS_IOS_OR_NEWER(iOS_14_0) || IS_IOS_OR_NEWER(iOS_15_0))
        return;
#if !SIDELOADED
        GetPrefs();
        GetBool2(SampleBufferWork, YES);
#endif
    if (IS_IOS_OR_NEWER(iOS_14_2)) {
        %init(AVKit_iOS14_2_Up);
    } else {
        %init(AVKit_preiOS14_2);
    }
    if (SampleBufferWork) {
        %init;
    }
}