#if !SIDELOADED
#define tweakIdentifier @"com.ps.youpip"
#import "../PSPrefs/PSPrefs.x"
#endif

#import "Header.h"
#import "../PSHeader/iOSVersions.h"

BOOL CompatibilityMode = YES;
static NSString *YouPiPWarnVersionKey = @"YouPiPWarnVersionKey";

MLPIPController *(*InjectMLPIPController)();
YTSystemNotifications *(*InjectYTSystemNotifications)();
YTBackgroundabilityPolicy *(*InjectYTBackgroundabilityPolicy)();
YTPlayerViewControllerConfig *(*InjectYTPlayerViewControllerConfig)();
YTHotConfig *(*InjectYTHotConfig)();

%group WithInjection

%hook YTPlayerPIPController

- (instancetype)initWithDelegate:(id)delegate {
    id controller = %orig;
    if (controller == nil) {
        controller = [[%c(YTPlayerPIPController) alloc] init];
        MLPIPController *pip = InjectMLPIPController();
        YTSystemNotifications *systemNotifications = InjectYTSystemNotifications();
        YTBackgroundabilityPolicy *bgPolicy = InjectYTBackgroundabilityPolicy();
        YTPlayerViewControllerConfig *playerConfig = InjectYTPlayerViewControllerConfig();
        YTHotConfig *config = InjectYTHotConfig();
        [controller setValue:pip forKey:@"_pipController"];
        [controller setValue:bgPolicy forKey:@"_backgroundabilityPolicy"];
        [controller setValue:playerConfig forKey:@"_config"];
        [controller setValue:config forKey:@"_hotConfig"];
        [controller setValue:delegate forKey:@"_delegate"];
        [bgPolicy addBackgroundabilityPolicyObserver:controller];
        [pip addPIPControllerObserver:controller];
        [systemNotifications addSystemNotificationsObserver:controller];
    }
    return controller;
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

- (instancetype)init {
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
    NSBundle *bundle = [NSBundle mainBundle];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:YouPiPWarnVersionKey]) {
        NSString *currentVersion = [bundle infoDictionary][(__bridge NSString *)kCFBundleVersionKey];
        if ([currentVersion compare:@(OS_STRINGIFY(MIN_YOUTUBE_VERSION)) options:NSNumericSearch] != NSOrderedAscending) {
            UIAlertController *warning = [UIAlertController alertControllerWithTitle:@"YouPiP" message:[NSString stringWithFormat:@"YouTube version %@ is not tested and may not be supported by YouPiP, please upgrade YouTube to at least version %s", currentVersion, OS_STRINGIFY(MIN_YOUTUBE_VERSION)] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [warning addAction:action];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:warning animated:YES completion:nil];
            [defaults setBool:YES forKey:YouPiPWarnVersionKey];
        }
    }
    NSString *frameworkPath = [NSString stringWithFormat:@"%@/Frameworks/Module_Framework.framework/Module_Framework", bundle.bundlePath];
    MSImageRef ref = MSGetImageByName([frameworkPath UTF8String]);
    InjectMLPIPController = (MLPIPController *(*)())MSFindSymbol(ref, "_InjectMLPIPController");
    if (InjectMLPIPController != NULL) {
        InjectYTSystemNotifications = (YTSystemNotifications *(*)())MSFindSymbol(ref, "_InjectYTSystemNotifications");
        InjectYTBackgroundabilityPolicy = (YTBackgroundabilityPolicy *(*)())MSFindSymbol(ref, "_InjectYTBackgroundabilityPolicy");
        InjectYTPlayerViewControllerConfig = (YTPlayerViewControllerConfig *(*)())MSFindSymbol(ref, "_InjectYTPlayerViewControllerConfig");
        InjectYTHotConfig = (YTHotConfig *(*)())MSFindSymbol(ref, "_InjectYTHotConfig");
        %init(WithInjection);
    }
    if (IS_IOS_OR_NEWER(iOS_14_0)) {
#if !SIDELOADED
        GetPrefs();
        GetBool2(CompatibilityMode, NO);
#endif
    } else  {
        %init(Compat);
    }
    if (CompatibilityMode) {
        %init(Legacy);
    }
}