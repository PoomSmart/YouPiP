#import "Header.h"

static void forceEnablePictureInPictureInternal(YTHotConfig *hotConfig) {
    [hotConfig mediaHotConfig].enablePictureInPicture = YES;
    [[[hotConfig hotConfigGroup] mediaHotConfig] iosMediaHotConfig].enablePictureInPicture = YES;
}

static void activatePiP(YTLocalPlaybackController *local) {
    if (![local isKindOfClass:%c(YTLocalPlaybackController)])
        return;
    YTPlayerPIPController *controller = [local valueForKey:@"_playerPIPController"];
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
        activatePiP(local);
    });
    return self;
}

%new
- (void)appWillResignActive:(id)arg1 {
    YTHotConfig *hotConfig = [self valueForKey:@"_hotConfig"];
    forceEnablePictureInPictureInternal(hotConfig);
    YTLocalPlaybackController *local = [self valueForKey:@"_playbackController"];
    activatePiP(local);
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.75 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        MRMediaRemoteSendCommand(MRMediaRemoteCommandPause, 0);
    });
}

+ (BOOL)isPictureInPictureSupported {
    return YES;
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
    %init;
}
