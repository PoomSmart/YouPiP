#if !SIDELOADED
#define tweakIdentifier @"com.ps.youpip"
#import "../PSPrefs/PSPrefs.x"
#endif

#import "Header.h"
#import "../PSHeader/iOSVersions.h"

BOOL CompatibilityMode = YES;

MLPIPController *(*InjectMLPIPController)();
YTBackgroundabilityPolicy *(*InjectYTBackgroundabilityPolicy)();
YTPlayerViewControllerConfig *(*InjectYTPlayerViewControllerConfig)();
YTHotConfig *(*InjectYTHotConfig)();

%group WithInjection

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

%hook MLHAMQueuePlayer

- (instancetype)initWithStickySettings:(MLPlayerStickySettings *)stickySettings playerViewProvider:(MLPlayerPoolImpl *)playerViewProvider playerConfiguration:(void *)playerConfiguration {
    self = %orig;
    if ([self valueForKey:@"_pipController"] == nil) {
        MLPIPController *pip = InjectMLPIPController();
        [self setValue:pip forKey:@"_pipController"];
    }
    return self;
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

%end

%end

%group Legacy

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
    }
}

- (void)deactivatePiPController {
    AVPictureInPictureController *pip = [self valueForKey:@"_pictureInPictureController"];
    [pip stopPictureInPicture];
}

%end

%hook MLPlayerPoolImpl

- (id)acquirePlayerForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings {
    BOOL externalPlaybackActive = [(MLPlayer *)[self valueForKey:@"_activePlayer"] externalPlaybackActive];
    MLAVPlayer *player = [[%c(MLAVPlayer) alloc] initWithVideo:video playerConfig:playerConfig stickySettings:stickySettings externalPlaybackActive:externalPlaybackActive];
    if (stickySettings)
        player.rate = stickySettings.rate;
    return player;
}

- (id)acquirePlayerForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings latencyLogger:(id)latencyLogger {
    BOOL externalPlaybackActive = [(MLPlayer *)[self valueForKey:@"_activePlayer"] externalPlaybackActive];
    MLAVPlayer *player = [[%c(MLAVPlayer) alloc] initWithVideo:video playerConfig:playerConfig stickySettings:stickySettings externalPlaybackActive:externalPlaybackActive];
    if (stickySettings)
        player.rate = stickySettings.rate;
    return player;
}

- (MLAVPlayerLayerView *)playerViewForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig {
    MLDefaultPlayerViewFactory *factory = [self valueForKey:@"_playerViewFactory"];
    return [factory AVPlayerViewForVideo:video playerConfig:playerConfig];
}

- (bool)canQueuePlayerPlayVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig {
    return false;
}

%end

%end

%group Compat

%hook AVPictureInPictureController

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

%end

%ctor {
    if (IS_IOS_OR_NEWER(iOS_14_0)) {
#if !SIDELOADED
        GetPrefs();
        GetBool2(CompatibilityMode, NO);
#endif
    } else {
        NSString *frameworkPath = [NSString stringWithFormat:@"%@/Frameworks/Module_Framework.framework/Module_Framework", NSBundle.mainBundle.bundlePath];
        MSImageRef ref = MSGetImageByName([frameworkPath UTF8String]);
        InjectMLPIPController = (MLPIPController *(*)())MSFindSymbol(ref, "_InjectMLPIPController");
        InjectYTBackgroundabilityPolicy = (YTBackgroundabilityPolicy *(*)())MSFindSymbol(ref, "_InjectYTBackgroundabilityPolicy");
        InjectYTPlayerViewControllerConfig = (YTPlayerViewControllerConfig *(*)())MSFindSymbol(ref, "_InjectYTPlayerViewControllerConfig");
        InjectYTHotConfig = (YTHotConfig *(*)())MSFindSymbol(ref, "_InjectYTHotConfig");
        if (InjectMLPIPController != NULL) {
            %init(WithInjection);
        }
        %init(Compat);
    }
    if (CompatibilityMode) {
        %init(Legacy);
    }
}