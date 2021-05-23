#import "Header.h"
#import <version.h>

MLPIPController *(*InjectMLPIPController)();
YTBackgroundabilityPolicy *(*InjectYTBackgroundabilityPolicy)();
YTPlayerViewControllerConfig *(*InjectYTPlayerViewControllerConfig)();
YTHotConfig *(*InjectYTHotConfig)();

%hook YTPlayerPIPController

- (id)initWithDelegate:(id)delegate {
    id pipcont = [[%c(YTPlayerPIPController) alloc] init];
    MLPIPController *pip = InjectMLPIPController();
    YTBackgroundabilityPolicy *bgPolicy = InjectYTBackgroundabilityPolicy();
    YTPlayerViewControllerConfig *playerConfig = InjectYTPlayerViewControllerConfig();
    YTHotConfig *config = InjectYTHotConfig();
    [pipcont setValue:pip forKey:@"_pipController"];
    [pipcont setValue:bgPolicy forKey:@"_backgroundabilityPolicy"];
    [pipcont setValue:playerConfig forKey:@"_config"];
    [pipcont setValue:config forKey:@"_hotConfig"];
    [pipcont setValue:delegate forKey:@"_delegate"];
    [bgPolicy addBackgroundabilityPolicyObserver:pipcont];
    [pip addPIPControllerObserver:pipcont];
    return pipcont;
}

%end

%hook MLPIPController

- (void)activatePiPController {
    if (![self isPictureInPictureActive]) {
        AVPictureInPictureController *pip = [self valueForKey:@"_pictureInPictureController"];
        if (!pip) {
            MLAVPIPPlayerLayerView *avpip = [self valueForKey:@"_AVPlayerView"];
            if (avpip) {
                AVPlayerLayer *playerLayer = [avpip playerLayer];
                pip = [[AVPictureInPictureController alloc] initWithPlayerLayer:playerLayer];
                [self setValue:pip forKey:@"_pictureInPictureController"];
                pip.delegate = self;
            }
        }
        [pip startPictureInPicture];
    }
}

%end

%hook MLHAMQueuePlayer

- (id)initWithStickySettings:(id)stickySettings playerViewProvider:(id)playerViewProvider playerConfiguration:(id)playerConfiguration {
    id player = %orig;
    if ([player valueForKey:@"_pipController"] == nil) {
        MLPIPController *pip = InjectMLPIPController();
        [player setValue:pip forKey:@"_pipController"];
    }
    return player;
}

%end

%hook MLAVPlayer

- (bool)isPictureInPictureActive {
    MLPIPController *pip = InjectMLPIPController();
    return [pip isPictureInPictureActive];
}

%end

%hook MLPlayerPoolImpl

- (id)init {
    self = %orig;
    MLPIPController *pip = InjectMLPIPController();
    [self setValue:pip forKey:@"_pipController"];
    return self;
}

- (id)acquirePlayerForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings latencyLogger:(id)latencyLogger {
    BOOL externalPlaybackActive = [(MLPlayer *)[self valueForKey:@"_activePlayer"] externalPlaybackActive];
    MLAVPlayer *player = [(MLAVPlayer *)[[self gimme] allocOf:%c(MLAVPlayer)] initWithVideo:video playerConfig:playerConfig stickySettings:stickySettings externalPlaybackActive:externalPlaybackActive];
    if (stickySettings)
        player.rate = stickySettings.rate;
    return player;
}

%end

%hook MLModule

- (void)configureWithBinder:(GIMBindingBuilder *)binder {
    %orig;
    [binder bindType:%c(MLPIPController)];
}

%end

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
    NSString *frameworkPath = [NSString stringWithFormat:@"%@/Frameworks/Module_Framework.framework/Module_Framework", NSBundle.mainBundle.bundlePath];
    MSImageRef ref = MSGetImageByName([frameworkPath UTF8String]);
    InjectMLPIPController = (MLPIPController *(*)())MSFindSymbol(ref, "_InjectMLPIPController");
    InjectYTBackgroundabilityPolicy = (YTBackgroundabilityPolicy *(*)())MSFindSymbol(ref, "_InjectYTBackgroundabilityPolicy");
    InjectYTPlayerViewControllerConfig = (YTPlayerViewControllerConfig *(*)())MSFindSymbol(ref, "_InjectYTPlayerViewControllerConfig");
    InjectYTHotConfig = (YTHotConfig *(*)())MSFindSymbol(ref, "_InjectYTHotConfig");
    %init;
}