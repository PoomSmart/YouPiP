#define LEGACY
#import <version.h>
#import "Header.h"
#import "../YouTubeHeader/GIMBindingBuilder.h"
#import "../YouTubeHeader/GPBExtensionRegistry.h"
#import "../YouTubeHeader/MLPIPController.h"
#import "../YouTubeHeader/MLDefaultPlayerViewFactory.h"
#import "../YouTubeHeader/YTBackgroundabilityPolicy.h"
#import "../YouTubeHeader/YTMainAppControlsOverlayView.h"
#import "../YouTubeHeader/YTMainAppVideoPlayerOverlayViewController.h"
#import "../YouTubeHeader/YTHotConfig.h"
#import "../YouTubeHeader/YTLocalPlaybackController.h"
#import "../YouTubeHeader/YTPlayerPIPController.h"
#import "../YouTubeHeader/YTSettingsSectionItem.h"
#import "../YouTubeHeader/YTSettingsSectionItemManager.h"
#import "../YouTubeHeader/YTIPictureInPictureRendererRoot.h"
#import "../YouTubeHeader/YTColor.h"
#import "../YouTubeHeader/QTMIcon.h"

BOOL FromUser = NO;
BOOL ForceDisablePiP = NO;

BOOL PiPActivationMethod() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:PiPActivationMethodKey];
}

static NSString *PiPIconPath;
static NSString *PiPVideoPath;

@interface YTMainAppControlsOverlayView (YP)
@property(retain, nonatomic) YTQTMButton *pipButton;
- (void)didPressPiP:(id)arg;
- (UIImage *)pipImage;
@end

static YTHotConfig *getHotConfig(id object) {
    return [[object valueForKey:@"_config"] valueForKey:@"_hotConfig"];
}

static void forcePictureInPictureInternal(YTHotConfig *hotConfig, BOOL value) {
    [hotConfig mediaHotConfig].enablePictureInPicture = value;
    YTIIosMediaHotConfig *iosMediaHotConfig = [[[hotConfig hotConfigGroup] mediaHotConfig] iosMediaHotConfig];
    iosMediaHotConfig.enablePictureInPicture = value;
}

static void forceEnablePictureInPictureInternal(YTHotConfig *hotConfig) {
    if (ForceDisablePiP && !FromUser)
        return;
    forcePictureInPictureInternal(hotConfig, YES);
}

static void activatePiPBase(YTPlayerPIPController *controller, BOOL playPiP) {
    MLPIPController *pip = [controller valueForKey:@"_pipController"];
    BOOL canPiP = [controller canInvokePictureInPicture];
    if (canPiP)
        [pip startPictureInPicture];
    AVPictureInPictureController *avpip = [pip valueForKey:@"_pictureInPictureController"];
    if (playPiP) {
        if ([avpip isPictureInPicturePossible])
            [avpip startPictureInPicture];
    } else if (![pip isPictureInPictureActive])
        [avpip stopPictureInPicture];
}

static void activatePiP(YTLocalPlaybackController *local, BOOL playPiP) {
    if (![local isKindOfClass:%c(YTLocalPlaybackController)])
        return;
    YTPlayerPIPController *controller = [local valueForKey:@"_playerPIPController"];
    activatePiPBase(controller, playPiP);
}

static void bootstrapPiP(YTPlayerViewController *self, BOOL playPiP) {
    YTHotConfig *hotConfig = [[self gimme] instanceForType:%c(YTHotConfig)];
    forceEnablePictureInPictureInternal(hotConfig);
    YTLocalPlaybackController *local = [self valueForKey:@"_playbackController"];
    activatePiP(local, playPiP);
}

#pragma mark - PiP Button

%hook YTMainAppVideoPlayerOverlayViewController

- (void)updateTopRightButtonAvailability {
    %orig;
    YTMainAppVideoPlayerOverlayView *v = [self videoPlayerOverlayView];
    YTMainAppControlsOverlayView *c = [v valueForKey:@"_controlsOverlayView"];
    c.pipButton.hidden = !PiPActivationMethod();
    [c setNeedsLayout];
}

%end

static void createPiPButton(YTMainAppControlsOverlayView *self) {
    if (self) {
        CGFloat padding = [[self class] topButtonAdditionalPadding];
        UIImage *image = [self pipImage];
        self.pipButton = [self buttonWithImage:image accessibilityLabel:@"pip" verticalContentPadding:padding];
        self.pipButton.hidden = YES;
        self.pipButton.alpha = 0;
        [self.pipButton addTarget:self action:@selector(didPressPiP:) forControlEvents:64];
        [self addSubview:self.pipButton];
    }
}

static NSMutableArray *topControls(YTMainAppControlsOverlayView *self, NSMutableArray *controls) {
    if (PiPActivationMethod())
        [controls insertObject:self.pipButton atIndex:0];
    return controls;
}

%hook YTMainAppPlayerOverlayView

%property(retain, nonatomic) YTQTMButton *pipButton;

- (id)initWithDelegate:(id)delegate {
    self = %orig;
    createPiPButton(self);
    return self;
}

- (id)initWithDelegate:(id)delegate autoplaySwitchEnabled:(BOOL)autoplaySwitchEnabled {
    self = %orig;
    createPiPButton(self);
    return self;
}

- (NSMutableArray *)topButtonControls {
    return topControls(self, %orig);
}

- (NSMutableArray *)topControls {
    return topControls(self, %orig);
}

- (void)setTopOverlayVisible:(BOOL)visible isAutonavCanceledState:(BOOL)canceledState {
    if (PiPActivationMethod()) {
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
        image = [%c(QTMIcon) tintImage:[UIImage imageWithContentsOfFile:PiPIconPath] color:color];
        if ([image respondsToSelector:@selector(imageFlippedForRightToLeftLayoutDirection)])
            image = [image imageFlippedForRightToLeftLayoutDirection];
    });
    return image;
}

%new
- (void)didPressPiP:(id)arg {
    YTMainAppVideoPlayerOverlayViewController *c = [self valueForKey:@"_eventsDelegate"];
    FromUser = YES;
    bootstrapPiP([c delegate], YES);
}

%end

#pragma mark - PiP Bootstrapping

%hook YTPlayerViewController

%new
- (void)appWillResignActive:(id)arg1 {
    if (!PiPActivationMethod())
        bootstrapPiP(self, YES);
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
    forceEnablePictureInPictureInternal(getHotConfig(self));
    return %orig;
}

%end

#pragma mark - PiP Support, Backgroundable

%hook YTBackgroundabilityPolicy

- (void)updateIsBackgroundableByUserSettings {
    %orig;
    [self setValue:@(YES) forKey:@"_backgroundableByUserSettings"];
}

%end

#pragma mark - Hacks

BOOL YTSingleVideo_isLivePlayback_override = NO;

%hook YTSingleVideo

- (BOOL)isLivePlayback {
    return YTSingleVideo_isLivePlayback_override ? NO : %orig;
}

%end

%hook YTPlayerPIPController

- (BOOL)canInvokePictureInPicture {
    forceEnablePictureInPictureInternal(getHotConfig(self));
    YTSingleVideo_isLivePlayback_override = YES;
    BOOL value = %orig;
    YTSingleVideo_isLivePlayback_override = NO;
    return value;
}

- (void)appWillResignActive:(id)arg1 {
    forcePictureInPictureInternal(getHotConfig(self), !PiPActivationMethod());
    ForceDisablePiP = YES;
    if (PiPActivationMethod())
        activatePiPBase(self, NO);
    %orig;
    ForceDisablePiP = FromUser = NO;
}

%end

%hook YTIPlayabilityStatus

- (BOOL)isPlayableInBackground {
    return YES;
}

- (BOOL)isPlayableInPictureInPicture {
    return YES;
}

- (BOOL)hasPictureInPicture {
    return YES;
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

%ctor {
    PiPVideoPath = @"/Library/Application Support/YouPiP.bundle/PiPPlaceholderAsset.mp4";
    PiPIconPath = @"/Library/Application Support/YouPiP.bundle/yt-pip-overlay.png";
    %init;
}
