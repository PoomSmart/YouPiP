#import <AVKit/AVKit.h>
#import <version.h>

%hook AVPictureInPictureController

// %property(retain, nonatomic) AVPictureInPictureControllerContentSource *contentSource;

// %new
// - (AVPictureInPictureController *)initWithContentSource:(AVPictureInPictureControllerContentSource *)contentSource {
//     AVPictureInPictureController *r = [[AVPictureInPictureController alloc] init];
//     r.contentSource = contentSource;
//     [r _commonInitWithSource:contentSource.source];
//     if ([[r source] isKindOfClass:[AVPlayerLayer class]]) {
//         [r _observePlayerLayer:[r source]];
//     }
//     r.allowsPictureInPicturePlayback = YES;
// }

%new
- (void)invalidatePlaybackState {

}

%new
- (void)sampleBufferDisplayLayerDidDisappear {

}

%new
- (void)sampleBufferDisplayLayerDidAppear {

}

%new
- (void)sampleBufferDisplayLayerRenderSizeDidChangeToSize:(CGSize)size {

}

%end

%ctor {
    if (IS_IOS_OR_NEWER(iOS_14_0))
        return;
    %init;
}