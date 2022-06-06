#import "Header.h"
#import "../PSHeader/iOSVersions.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"

%group AVKit_iOS14_2_Up

%hook AVPictureInPictureControllerContentSource

%property (assign) bool hasInitialRenderSize;

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

%property (assign) bool hasInitialRenderSize;

%new
- (instancetype)initWithSampleBufferDisplayLayer:(AVSampleBufferDisplayLayer *)sampleBufferDisplayLayer initialRenderSize:(CGSize)initialRenderSize playbackDelegate:(id <AVPictureInPictureSampleBufferPlaybackDelegate>)playbackDelegate {
    return [self initWithSampleBufferDisplayLayer:sampleBufferDisplayLayer playbackDelegate:playbackDelegate];
}

%end

%hook AVPictureInPictureController

%new
- (void)setCanStartPictureInPictureAutomaticallyFromInline:(BOOL)canStartFromInline {}

%end

%end

%ctor {
    if (!IS_IOS_OR_NEWER(iOS_14_0) || IS_IOS_OR_NEWER(iOS_15_0))
        return;
    if (IS_IOS_OR_NEWER(iOS_14_2)) {
        %init(AVKit_iOS14_2_Up);
    } else {
        %init(AVKit_preiOS14_2);
    }
}

#pragma clang diagnostic pop