#define tweakIdentifier @"com.ps.youpip"
#import "Header.h"
#import "../PSPrefs/PSPrefs.x"
#import <UIKit/UIImage+Private.h>
#import <version.h>

int PiPActivationMethod;

@interface YTMainAppControlsOverlayView (YP)
@property(retain, nonatomic) YTQTMButton *pipButton;
- (void)didPressPiP:(id)arg;
- (UIImage *)pipImage;
@end

static void forceEnablePictureInPictureInternal(YTHotConfig *hotConfig) {
    [hotConfig mediaHotConfig].enablePictureInPicture = YES;
    [[[hotConfig hotConfigGroup] mediaHotConfig] iosMediaHotConfig].enablePictureInPicture = YES;
}

static void activatePiP(YTLocalPlaybackController *local, BOOL playPiP) {
    if (![local isKindOfClass:%c(YTLocalPlaybackController)])
        return;
    YTPlayerPIPController *controller = [local valueForKey:@"_playerPIPController"];
    MLPIPController *pip = [controller valueForKey:@"_pipController"];
    if ([controller respondsToSelector:@selector(maybeEnablePictureInPicture)])
        [controller maybeEnablePictureInPicture];
    else if ([controller respondsToSelector:@selector(maybeInvokePictureInPicture)])
        [controller maybeInvokePictureInPicture];
    else if ([controller canEnablePictureInPicture])
        [pip activatePiPController];
    if (playPiP) {
        AVPictureInPictureController *avpip = [pip valueForKey:@"_pictureInPictureController"];
        if ([avpip isPictureInPicturePossible]) {
            [avpip startPictureInPicture];
            if (PiPActivationMethod) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [UIApplication.sharedApplication performSelector:@selector(suspend)];
                });
            } else
                [UIApplication.sharedApplication performSelector:@selector(suspend)];
        }
    }
}

static void bootstrapPiP(YTPlayerViewController *self, BOOL playPiP) {
    YTHotConfig *hotConfig = [self valueForKey:@"_hotConfig"];
    forceEnablePictureInPictureInternal(hotConfig);
    YTLocalPlaybackController *local = [self valueForKey:@"_playbackController"];
    activatePiP(local, playPiP);
}

%hook YTMainAppVideoPlayerOverlayViewController

- (void)updateTopRightButtonAvailability {
    %orig;
    if (PiPActivationMethod) {
        YTMainAppVideoPlayerOverlayView *v = [self videoPlayerOverlayView];
        YTMainAppControlsOverlayView *c = [v valueForKey:@"_controlsOverlayView"];
        c.pipButton.hidden = NO;
        [c setNeedsLayout];
    }
}

%end

%hook YTMainAppControlsOverlayView

%property(retain, nonatomic) YTQTMButton *pipButton;

- (id)initWithDelegate:(id)delegate {
    self = %orig;
    if (self && PiPActivationMethod) {
        CGFloat padding = [[self class] topButtonAdditionalPadding];
        UIImage *image = [self pipImage];
        self.pipButton = [self buttonWithImage:image accessibilityLabel:@"pip" verticalContentPadding:padding];
        self.pipButton.hidden = YES;
        self.pipButton.alpha = 0;
        [self.pipButton addTarget:self action:@selector(didPressPiP:) forControlEvents:64];
        [[self valueForKey:@"_topControlsAccessibilityContainerView"] addSubview:self.pipButton];
    }
    return self;
}

- (NSMutableArray *)topControls {
    NSMutableArray *controls = %orig;
    if (PiPActivationMethod)
        [controls insertObject:self.pipButton atIndex:0];
    return controls;
}

- (void)setTopOverlayVisible:(BOOL)visible isAutonavCanceledState:(BOOL)canceledState {
    if (PiPActivationMethod) {
        if (canceledState) {
            if (!self.pipButton.hidden)
                self.pipButton.alpha = 0.0;
        } else {
            if (!self.pipButton.hidden)
                self.pipButton.alpha = visible ? 1.0 : 0.0;
        }
    }
    %orig;
}

%new
- (UIImage *)pipImage {
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIColor *color = [%c(YTColor) white1];
        image = [UIImage imageWithContentsOfFile:@"/Library/Application Support/YouPiP/yt-pip-overlay.png"];
        if ([%c(QTMIcon) respondsToSelector:@selector(tintImage:color:)])
            image = [%c(QTMIcon) tintImage:image color:color];
        else
            image = [image _flatImageWithColor:color];
        if ([image respondsToSelector:@selector(imageFlippedForRightToLeftLayoutDirection)])
            image = [image imageFlippedForRightToLeftLayoutDirection];
    });
    return image;
}

%new
- (void)didPressPiP:(id)arg {
    YTMainAppVideoPlayerOverlayViewController *c = [self valueForKey:@"_eventsDelegate"];
    YTPlayerViewController *p = [c delegate];
    bootstrapPiP(p, YES);
}

%end

%hook YTPlayerViewController

- (id)initWithParentResponder:(id)parentResponder overlayFactory:(id)overlayFactory {
    self = %orig;
    if (PiPActivationMethod == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            bootstrapPiP(self, NO);
        });
    }
    return self;
}

- (id)initWithServiceRegistryScope:(id)registryScope parentResponder:(id)parentResponder overlayFactory:(id)overlayFactory {
    self = %orig;
    if (PiPActivationMethod == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            bootstrapPiP(self, NO);
        });
    }
    return self;
}

%new
- (void)appWillResignActive:(id)arg1 {
    if (PiPActivationMethod)
        return;
    bootstrapPiP(self, !IS_IOS_OR_NEWER(iOS_14_0));
}

%end

%group MediaRemote

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

%end

%end

%hook AVPictureInPictureController

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
    GetPrefs();
    GetInt2(PiPActivationMethod, 0);
    %init;
    if (IS_IOS_OR_NEWER(iOS_13_0)) {
        %init(MediaRemote);
    }
}
