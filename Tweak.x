#if !SIDELOADED
#define tweakIdentifier @"com.ps.youpip"
#import "../PSPrefs/PSPrefs.x"
#endif

#import "Header.h"
#import <UIKit/UIImage+Private.h>
#import <version.h>

BOOL FromUser = NO;
int PiPActivationMethod = 0;

static NSString *PiPIconPath;
static NSBundle *resourcesBundle;
static NSString *PiPVideoPath;

@interface YTMainAppControlsOverlayView (YP)
@property(retain, nonatomic) YTQTMButton *pipButton;
- (void)didPressPiP:(id)arg;
- (UIImage *)pipImage;
@end

static void forceEnablePictureInPictureInternal(YTHotConfig *hotConfig) {
    [hotConfig mediaHotConfig].enablePictureInPicture = YES;
    YTIIosMediaHotConfig *iosMediaHotConfig = [[[hotConfig hotConfigGroup] mediaHotConfig] iosMediaHotConfig];
    iosMediaHotConfig.enablePictureInPicture = YES;
    if ([iosMediaHotConfig respondsToSelector:@selector(setEnablePipForNonBackgroundableContent:)])
        iosMediaHotConfig.enablePipForNonBackgroundableContent = YES;
}

static void activatePiP(YTLocalPlaybackController *local, BOOL playPiP, BOOL killPiP) {
    if (![local isKindOfClass:%c(YTLocalPlaybackController)])
        return;
    YTPlayerPIPController *controller = [local valueForKey:@"_playerPIPController"];
    MLPIPController *pip = [controller valueForKey:@"_pipController"];
#if !SIDELOADED
    if (killPiP && !FromUser) {
        if ([pip respondsToSelector:@selector(deactivatePiPController)])
            [pip deactivatePiPController];
        else
            [pip stopPictureInPicture];
        return;
    }
#endif
    if ([controller respondsToSelector:@selector(maybeEnablePictureInPicture)])
        [controller maybeEnablePictureInPicture];
    else if ([controller respondsToSelector:@selector(maybeInvokePictureInPicture)])
        [controller maybeInvokePictureInPicture];
    else {
        BOOL canPiP = [controller respondsToSelector:@selector(canEnablePictureInPicture)] && [controller canEnablePictureInPicture];
        if (!canPiP)
            canPiP = [controller respondsToSelector:@selector(canInvokePictureInPicture)] && [controller canInvokePictureInPicture];
        if (canPiP) {
            if ([pip respondsToSelector:@selector(activatePiPController)])
                [pip activatePiPController];
            else
                [pip startPictureInPicture];
        }
    }
    if (playPiP) {
        AVPictureInPictureController *avpip = [pip valueForKey:@"_pictureInPictureController"];
        if ([avpip isPictureInPicturePossible])
            [avpip startPictureInPicture];
    }
}

static void bootstrapPiP(YTPlayerViewController *self, BOOL playPiP, BOOL killPiP) {
    YTHotConfig *hotConfig;
    @try {
        hotConfig = [self valueForKey:@"_hotConfig"];
    } @catch (id ex) {
        hotConfig = [[self gimme] instanceForType:%c(YTHotConfig)];
    }
    forceEnablePictureInPictureInternal(hotConfig);
    YTLocalPlaybackController *local = [self valueForKey:@"_playbackController"];
    activatePiP(local, playPiP, killPiP);
}

#pragma mark - PiP Button

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
        @try {
            [[self valueForKey:@"_topControlsAccessibilityContainerView"] addSubview:self.pipButton];
        } @catch (id ex) {
            [self addSubview:self.pipButton];
        }
    }
    return self;
}

- (NSMutableArray *)topControls {
    NSMutableArray *controls = %orig;
    if (PiPActivationMethod) {
        if ([controls respondsToSelector:@selector(insertObject:atIndex:)])
            [controls insertObject:self.pipButton atIndex:0];
        else {
            NSMutableArray *mutableControls = [NSMutableArray arrayWithArray:controls];
            [mutableControls insertObject:self.pipButton atIndex:0];
            return mutableControls;
        }
    }
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
        image = [UIImage imageWithContentsOfFile:PiPIconPath];
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
    FromUser = YES;
    bootstrapPiP(p, YES, NO);
}

%end

#pragma mark - PiP Bootstrapping

%hook YTPlayerViewController

%new
- (void)appWillResignActive:(id)arg1 {
    bootstrapPiP(self, !IS_IOS_OR_NEWER(iOS_14_0), PiPActivationMethod != 0);
    FromUser = NO;
}

%end

#pragma mark - PiP Support

%hook AVPictureInPictureController

+ (BOOL)isPictureInPictureSupported {
    return YES;
}

%end

%hook MLPIPController

- (BOOL)isPictureInPictureSupported {
    return YES;
}

%end

%hook MLDefaultPlayerViewFactory

- (MLAVPlayerLayerView *)AVPlayerViewForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig {
    forceEnablePictureInPictureInternal([self valueForKey:@"_hotConfig"]);
    return %orig;
}

%end

// %hook YTHotConfig

// - (bool)iosReleasePipControllerOnMain {
//     return true;
// }

// - (bool)iosDontReleasePipController {
//     return false;
// }

// %end

#pragma mark - PiP Support, Backgroundable

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
    [self setValue:@(YES) forKey:@"_backgroundableByUserSettings"];
}

%end

%hook YTSettingsSectionItemManager

- (id)pictureInPictureSectionItem {
    forceEnablePictureInPictureInternal([self valueForKey:@"_hotConfig"]);
    return %orig;
}

%end

#pragma mark - Hacks

BOOL YTSingleVideo_isLivePlayback_override = NO;

%hook YTSingleVideo

- (BOOL)isLivePlayback {
    return YTSingleVideo_isLivePlayback_override ? NO : %orig;
}

%end

static YTHotConfig *getHotConfig(YTPlayerPIPController *self) {
    @try {
        return [self valueForKey:@"_hotConfig"];
    } @catch (id ex) {
        return [[self valueForKey:@"_config"] valueForKey:@"_hotConfig"];
    }
}

%hook YTPlayerPIPController

- (BOOL)canInvokePictureInPicture {
    forceEnablePictureInPictureInternal(getHotConfig(self));
    YTSingleVideo_isLivePlayback_override = YES;
    BOOL value = %orig;
    YTSingleVideo_isLivePlayback_override = NO;
    return value;
}

- (BOOL)canEnablePictureInPicture {
    forceEnablePictureInPictureInternal(getHotConfig(self));
    YTSingleVideo_isLivePlayback_override = YES;
    BOOL value = %orig;
    YTSingleVideo_isLivePlayback_override = NO;
    return value;
}

%end

#pragma mark - PiP Support, Late Hooks

%group LateLateHook

%hook YTIPictureInPictureRenderer

- (BOOL)playableInPip {
    return YES;
}

%end

%hook YTIPictureInPictureSupportedRenderers

- (BOOL)hasPictureInPictureRenderer {
    return YES;
}

%end

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

#pragma mark - PiP Support, Binding

%hook YTAppModule

- (void)configureWithBinder:(GIMBindingBuilder *)binder {
    %orig;
    [[binder bindType:%c(MLPIPController)] initializedWith:^(id a) {
        MLPIPController *pip = [%c(MLPIPController) alloc];
        if ([pip respondsToSelector:@selector(initWithPlaceholderPlayerItemResourcePath:)])
            pip = [pip initWithPlaceholderPlayerItemResourcePath:PiPVideoPath];
        else if ([pip respondsToSelector:@selector(initWithPlaceholderPlayerItem:)])
            pip = [pip initWithPlaceholderPlayerItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:PiPVideoPath]]];
        if ([pip respondsToSelector:@selector(initializePictureInPicture)])
            [pip initializePictureInPicture];
        return pip;
    }];
}

%end

%hook YTIInnertubeResourcesIosRoot

- (GPBExtensionRegistry *)extensionRegistry {
    GPBExtensionRegistry *registry = %orig;
    [registry addExtension:[%c(YTIPictureInPictureRendererRoot) pictureInPictureRenderer]];
    return registry;
}

%end

%hook GoogleGlobalExtensionRegistry

- (GPBExtensionRegistry *)extensionRegistry {
    GPBExtensionRegistry *registry = %orig;
    [registry addExtension:[%c(YTIPictureInPictureRendererRoot) pictureInPictureRenderer]];
    return registry;
}

%end

%ctor {
#if !SIDELOADED
    GetPrefs();
    GetInt2(PiPActivationMethod, 0);
    PiPVideoPath = @"/Library/Application Support/YouPiP/PiPPlaceholderAsset.mp4";
    PiPIconPath = @"/Library/Application Support/YouPiP/yt-pip-overlay.png";
#else
    resourcesBundle = [NSBundle bundleForClass:%c(MLDefaultPlayerViewFactory)];
    PiPVideoPath = [resourcesBundle pathForResource:@"PiPPlaceholderAsset" ofType:@"mp4"];
#endif
    %init;
}
