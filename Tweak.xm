#import "Header.h"
#import <version.h>

static void forceEnablePictureInPictureInternal(YTHotConfig *hotConfig) {
    [hotConfig mediaHotConfig].enablePictureInPicture = YES;
    [[[hotConfig hotConfigGroup] mediaHotConfig] iosMediaHotConfig].enablePictureInPicture = YES;
}

static void activatePiP(YTPlayerPIPController *controller) {
    if ([controller respondsToSelector:@selector(maybeEnablePictureInPicture)])
        [controller maybeEnablePictureInPicture];
    else if ([controller respondsToSelector:@selector(maybeInvokePictureInPicture)])
        [controller maybeInvokePictureInPicture];
    else {
        MLPIPController *pip = [controller valueForKey:@"_pipController"];
        if ([controller canEnablePictureInPicture])
            [pip activatePiPController];
    }
}

%hook YTPlayerViewController

- (id)initWithParentResponder:(id)arg1 overlayFactory:(id)arg2 {
    self = %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        YTHotConfig *hotConfig = [self valueForKey:@"_hotConfig"];
        forceEnablePictureInPictureInternal(hotConfig);
        YTLocalPlaybackController *local = [self valueForKey:@"_playbackController"];
        YTPlayerPIPController *controller = [local valueForKey:@"_playerPIPController"];
        NSLog(@"[YOUPIP] %@", [controller description] != nil ? [controller description] : @"controller == nil");
        activatePiP(controller);
    });
    return self;
}

%new
- (void)appWillResignActive:(id)arg1 {
    YTHotConfig *hotConfig = [self valueForKey:@"_hotConfig"];
    forceEnablePictureInPictureInternal(hotConfig);
    YTLocalPlaybackController *local = [self valueForKey:@"_playbackController"];
    YTPlayerPIPController *controller = [local valueForKey:@"_playerPIPController"];
    activatePiP(controller);
}

%end

MLPIPController *(*InjectMLPIPController)();
YTBackgroundabilityPolicy *(*InjectYTBackgroundabilityPolicy)();
YTPlayerViewControllerConfig *(*InjectYTPlayerViewControllerConfig)();
YTHotConfig *(*InjectYTHotConfig)();

%hook YTPlayerPIPController

- (id)initWithDelegate:(id)delegate {
    if (!IS_IOS_OR_NEWER(iOS_14_0)) {
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
    return %orig;
}

%end

%hook MLPIPController

- (void)activatePiPController {
    if (IS_IOS_OR_NEWER(iOS_14_0))
        %orig;
    else {
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
}

%end

#import <MediaRemote/MediaRemote.h>

#pragma mark - This method is the method called to stop the playback after dismissing
#pragma mark - the PiP view. We need to implement a new way to pause playback from here;
#pragma mark - MRMediaRemoteCommandStop doesn't actually do anything, and
#pragma mark - MRMediaRemoteCommandPause does pause, but breaks playback unless
#pragma mark - delayed for a little bit after PiP dismiss animation is completed.

%hook AVPictureInPictureController

- (void)pictureInPicturePlatformAdapterPrepareToStopForDismissal:(id)arg1 {
    NSLog(@"[YOUPIP] (pictureInPicturePlatformAdapterPrepareToStopForDismissal) %@", [arg1 class]);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.75 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        MRMediaRemoteSendCommand(MRMediaRemoteCommandPause, 0);
    });
}

+ (BOOL)isPictureInPictureSupported {
    return YES;
}

%end

%hook MLHAMQueuePlayer

- (id)initWithStickySettings:(id)stickySettings playerViewProvider:(id)playerViewProvider playerConfiguration:(id)playerConfiguration {
    id player = %orig;
    if (!IS_IOS_OR_NEWER(iOS_14_0) && [player valueForKey:@"_pipController"] == nil) {
        MLPIPController *pip = InjectMLPIPController();
        [player setValue:pip forKey:@"_pipController"];
    }
    return player;
}

%end

%hook MLAVPlayer

- (bool)isPictureInPictureActive {
    if (IS_IOS_OR_NEWER(iOS_14_0))
        return %orig;
    MLPIPController *pip = InjectMLPIPController();
    return [pip isPictureInPictureActive];
}

%end

%hook MLDefaultPlayerViewFactory

- (MLAVPlayerLayerView *)AVPlayerViewForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig {
    forceEnablePictureInPictureInternal([self valueForKey:@"_hotConfig"]);
    return %orig;
}

%end

%hook YTIHamplayerConfig

- (BOOL)enableBackgroundable {
    return YES;
}

%end

%hook MLPlayerPoolImpl

- (id)init {
    id r = %orig;
    if (!IS_IOS_OR_NEWER(iOS_14_0)) {
        MLPIPController *pip = InjectMLPIPController();
        [r setValue:pip forKey:@"_pipController"];
    }
    return r;
}

- (id)acquirePlayerForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings latencyLogger:(id)latencyLogger {
    if (IS_IOS_OR_NEWER(iOS_14_0))
        return %orig;
    BOOL externalPlaybackActive = [(MLPlayer *)[self valueForKey:@"_activePlayer"] externalPlaybackActive];
    MLAVPlayer *player = [(MLAVPlayer *)[[self gimme] allocOf:%c(MLAVPlayer)] initWithVideo:video playerConfig:playerConfig stickySettings:stickySettings externalPlaybackActive:externalPlaybackActive];
    if (stickySettings)
        player.rate = stickySettings.rate;
    return player;
}

%end

%hook YTIBackgroundOfflineSettingCategoryEntryRenderer

- (BOOL)isBackgroundEnabled {
    return YES;
}

%end

%hook YTBackgroundabilityPolicy

- (void)updateIsBackgroundableByUserSettings {
    %orig;
    MSHookIvar<BOOL>(self, "_backgroundableByUserSettings") = YES;
}

- (bool)isPlayableInPictureInPictureByUserSettings {
    return true;
}

%end

%hook MLModule

- (void)configureWithBinder:(GIMBindingBuilder *)binder {
    %orig;
    if (!IS_IOS_OR_NEWER(iOS_14_0))
        [binder bindType:%c(MLPIPController)];
}

%end

%group LateLateHook

%hook YTIPictureInPictureRenderer

- (BOOL)playableInPip {
    return YES;
}

%end

%end

BOOL override = NO;

%hook YTSingleVideo

- (BOOL)isLivePlayback {
    return override ? NO : %orig;
}

%end

%hook YTPlayerPIPController

- (BOOL)canInvokePictureInPicture {
    override = YES;
    BOOL orig = %orig;
    override = NO;
    return orig;
}

- (BOOL)canEnablePictureInPicture {
    override = YES;
    BOOL orig = %orig;
    override = NO;
    return orig;
}

%end

%group LateHook

%hook YTIPlayabilityStatus

- (BOOL)isPlayableInBackground {
    return YES;
}

- (BOOL)isPlayableInPictureInPicture {
    %init(LateLateHook);
    return %orig;
}

- (BOOL)hasPictureInPicture {
    return YES;
}

- (void)setHasPictureInPicture:(BOOL)arg {
    %orig(YES);
}

%end

%end

%hook YTBaseInnerTubeService

+ (void)initialize {
    %orig;
    %init(LateHook);
}

%end

%ctor {
    if (!IS_IOS_OR_NEWER(iOS_14_0)) {
        NSString *frameworkPath = [NSString stringWithFormat:@"%@/Frameworks/Module_Framework.framework/Module_Framework", NSBundle.mainBundle.bundlePath];
        MSImageRef ref = MSGetImageByName([frameworkPath UTF8String]);
        InjectMLPIPController = (MLPIPController *(*)())MSFindSymbol(ref, "_InjectMLPIPController");
        InjectYTBackgroundabilityPolicy = (YTBackgroundabilityPolicy *(*)())MSFindSymbol(ref, "_InjectYTBackgroundabilityPolicy");
        InjectYTPlayerViewControllerConfig = (YTPlayerViewControllerConfig *(*)())MSFindSymbol(ref, "_InjectYTPlayerViewControllerConfig");
        InjectYTHotConfig = (YTHotConfig *(*)())MSFindSymbol(ref, "_InjectYTHotConfig");
    }
    %init;
}
