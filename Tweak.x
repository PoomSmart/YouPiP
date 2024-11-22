#import <version.h>
#import <rootless.h>
#import "Header.h"
#import <YouTubeHeader/ASCollectionView.h>
#import <YouTubeHeader/ELMCellNode.h>
#import <YouTubeHeader/ELMContainerNode.h>
#import <YouTubeHeader/MLDefaultPlayerViewFactory.h>
#import <YouTubeHeader/MLPIPController.h>
#import <YouTubeHeader/QTMIcon.h>
#import <YouTubeHeader/YTBackgroundabilityPolicy.h>
#import <YouTubeHeader/YTColor.h>
#import <YouTubeHeader/YTColorPalette.h>
#import <YouTubeHeader/YTCommonColorPalette.h>
#import <YouTubeHeader/YTISlimMetadataButtonSupportedRenderers.h>
#import <YouTubeHeader/YTLocalPlaybackController.h>
#import <YouTubeHeader/YTMainAppControlsOverlayView.h>
#import <YouTubeHeader/YTMainAppVideoPlayerOverlayViewController.h>
#import <YouTubeHeader/YTPageStyleController.h>
#import <YouTubeHeader/YTPlaybackStrippedWatchController.h>
#import <YouTubeHeader/YTPlayerPIPController.h>
#import <YouTubeHeader/YTPlayerStatus.h>
#import <YouTubeHeader/YTSettingsSectionItem.h>
#import <YouTubeHeader/YTSettingsSectionItemManager.h>
#import <YouTubeHeader/YTSlimVideoDetailsActionView.h>
#import <YouTubeHeader/YTSlimVideoScrollableActionBarCellController.h>
#import <YouTubeHeader/YTSlimVideoScrollableDetailsActionsView.h>
#import <YouTubeHeader/YTTouchFeedbackController.h>
#import <YouTubeHeader/YTWatchViewController.h>

#define PiPButtonType 801

@interface YTMainAppControlsOverlayView (YP)
@property (retain, nonatomic) YTQTMButton *pipButton;
- (void)didPressPiP:(id)arg;
- (UIImage *)pipImage;
@end

@interface ASCollectionView (YP)
@property (retain, nonatomic) UIButton *pipButton;
@property (retain, nonatomic) YTTouchFeedbackController *pipTouchController;
- (void)didPressPiP:(UIButton *)button event:(UIEvent *)event;
@end

BOOL FromUser = NO;
BOOL PiPDisabled = NO;

extern BOOL LegacyPiP();

BOOL TweakEnabled() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:EnabledKey];
}

BOOL UsePiPButton() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:PiPActivationMethodKey];
}

BOOL NoMiniPlayerPiP() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:NoMiniPlayerPiPKey];
}

BOOL UseTabBarPiPButton() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:PiPActivationMethod2Key];
}

BOOL NonBackgroundable() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:NonBackgroundableKey];
}

BOOL isPictureInPictureActive(MLPIPController *pip) {
    return [pip respondsToSelector:@selector(pictureInPictureActive)] ? [pip pictureInPictureActive] : [pip isPictureInPictureActive];
}

static NSString *PiPIconPath;
static NSString *TabBarPiPIconPath;

static void activatePiPBase(YTPlayerPIPController *controller, BOOL playPiP) {
    MLPIPController *pip = [controller valueForKey:@"_pipController"];
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
    AVPictureInPictureController *avpip = [pip valueForKey:@"_pictureInPictureController"];
    if (playPiP) {
        if ([avpip isPictureInPicturePossible])
            [avpip startPictureInPicture];
    } else {
        if ([pip respondsToSelector:@selector(deactivatePiPController)])
            [pip deactivatePiPController];
        else
            [avpip stopPictureInPicture];
    }
}

static void activatePiP(YTLocalPlaybackController *local, BOOL playPiP) {
    if (![local isKindOfClass:%c(YTLocalPlaybackController)])
        return;
    YTPlayerPIPController *controller = [local valueForKey:@"_playerPIPController"];
    activatePiPBase(controller, playPiP);
}

static void bootstrapPiP(YTPlayerViewController *self, BOOL playPiP) {
    YTLocalPlaybackController *local = [self valueForKey:@"_playbackController"];
    activatePiP(local, playPiP);
}

#pragma mark - Video tab bar PiP Button (16.46.5 and below + offline mode)

static YTISlimMetadataButtonSupportedRenderers *makeUnderOldPlayerButton(NSString *title, int iconType, NSString *browseId) {
    YTISlimMetadataButtonSupportedRenderers *supportedRenderer = [[%c(YTISlimMetadataButtonSupportedRenderers) alloc] init];
    YTISlimMetadataButtonRenderer *metadataButtonRenderer = [[%c(YTISlimMetadataButtonRenderer) alloc] init];
    YTIButtonSupportedRenderers *buttonSupportedRenderer = [[%c(YTIButtonSupportedRenderers) alloc] init];
    YTIBrowseEndpoint *endPoint = [[%c(YTIBrowseEndpoint) alloc] init];
    YTICommand *command = [[%c(YTICommand) alloc] init];
    YTIButtonRenderer *button = [[%c(YTIButtonRenderer) alloc] init];
    YTIIcon *icon = [[%c(YTIIcon) alloc] init];
    endPoint.browseId = browseId;
    command.browseEndpoint = endPoint;
    icon.iconType = iconType;
    button.style = 8; // Opacity style
    button.tooltip = title;
    button.size = 1; // Default size
    button.isDisabled = NO;
    button.text = [%c(YTIFormattedString) formattedStringWithString:title];
    button.icon = icon;
    button.navigationEndpoint = command;
    buttonSupportedRenderer.buttonRenderer = button;
    metadataButtonRenderer.button = buttonSupportedRenderer;
    supportedRenderer.slimMetadataButtonRenderer = metadataButtonRenderer;
    return supportedRenderer;
}

%hook YTIIcon

- (UIImage *)iconImageWithColor:(UIColor *)color {
    if (self.iconType == PiPButtonType) {
        UIImage *image = [%c(QTMIcon) tintImage:[UIImage imageWithContentsOfFile:TabBarPiPIconPath] color:[[%c(YTPageStyleController) currentColorPalette] textPrimary]];
        if ([image respondsToSelector:@selector(imageFlippedForRightToLeftLayoutDirection)])
            image = [image imageFlippedForRightToLeftLayoutDirection];
        return image;
    }
    return %orig;
}
%end

%hook YTSlimVideoScrollableDetailsActionsView

- (void)createActionViewsFromSupportedRenderers:(NSMutableArray *)renderers { // for old YouTube version
    if (UseTabBarPiPButton()) {
        YTISlimMetadataButtonSupportedRenderers *PiPButton = makeUnderOldPlayerButton(@"PiP", PiPButtonType, @"YouPiP.pip.command");
        if (![renderers containsObject:PiPButton])
            [renderers addObject:PiPButton];
    }
    %orig;
}

- (void)createActionViewsFromSupportedRenderers:(NSMutableArray *)renderers withElementsContextBlock:(id)arg2 {
    if (UseTabBarPiPButton()) {
        YTISlimMetadataButtonSupportedRenderers *PiPButton = makeUnderOldPlayerButton(@"PiP", PiPButtonType, @"YouPiP.pip.command");
        if (![renderers containsObject:PiPButton])
            [renderers addObject:PiPButton];
    }
    %orig;
}

%end

%hook YTSlimVideoDetailsActionView

- (void)didTapButton:(id)arg1 {
    if ([self.label.attributedText.string isEqualToString:@"PiP"]) {
        YTSlimVideoScrollableActionBarCellController *_delegate = self.delegate;
        YTPlayerViewController *playerViewController = nil;
        @try {
            id provider = [_delegate valueForKey:@"_metadataPanelStateProvider"];
            if ([provider isKindOfClass:%c(YTWatchController)] || [provider isKindOfClass:%c(YTPlaybackStrippedWatchController)]) {
                @try {
                    YTWatchViewController *watchViewController = [provider valueForKey:@"_watchViewController"];
                    playerViewController = [watchViewController valueForKey:@"_playerViewController"];
                } @catch (id ex) {
                    playerViewController = [provider valueForKey:@"_playerViewController"];
                }
            }
        } @catch (id ex) { // for old YouTube version
            if ([[_delegate valueForKey:@"_ngwMetadataPanelStateProvider"] isKindOfClass:%c(YTNGWatchController)]) {
                id provider = [_delegate valueForKey:@"_ngwMetadataPanelStateProvider"];
                playerViewController = [provider valueForKey:@"_playerViewController"];
            }
        }
        if (playerViewController && [playerViewController isKindOfClass:%c(YTPlayerViewController)]) {
            FromUser = YES;
            bootstrapPiP(playerViewController, YES);
        }
        return;
    }
    %orig;
}

%end

#pragma mark - Video tab bar PiP Button (17.01.4 and up)

static UIButton *makeUnderNewPlayerButton(ELMCellNode *node, NSString *title, NSString *accessibilityLabel) {
    NSInteger pageStyle = [%c(YTPageStyleController) pageStyle];
    YTCommonColorPalette *palette = pageStyle == 1 ? [%c(YTCommonColorPalette) darkPalette] : [%c(YTCommonColorPalette) lightPalette];
    if (!palette) palette = [%c(YTColorPalette) colorPaletteForPageStyle:pageStyle]; // YouTube 17.18.4 and below
    UIColor *textColor = [palette textPrimary];

    ELMContainerNode *containerNode = (ELMContainerNode *)[[[[node yogaChildren] firstObject] yogaChildren] firstObject]; // To get node container properties
    UIButton *buttonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 65, containerNode.calculatedSize.height)];
    buttonView.center = CGPointMake(CGRectGetMaxX([node.layoutAttributes frame]) + 65 / 2, CGRectGetMidY([node.layoutAttributes frame]));
    buttonView.backgroundColor = containerNode.backgroundColor;
    buttonView.accessibilityLabel = accessibilityLabel;
    buttonView.layer.cornerRadius = 16;

    UIImageView *buttonImage = [[UIImageView alloc] initWithFrame:CGRectMake(12, ([buttonView frame].size.height - 15) / 2, 15, 15)];
    buttonImage.image = [%c(QTMIcon) tintImage:[UIImage imageWithContentsOfFile:TabBarPiPIconPath] color:textColor];

    UILabel *buttonTitle = [[UILabel alloc] initWithFrame:CGRectMake(33, 9, 20, 14)];
    buttonTitle.font = [UIFont boldSystemFontOfSize:10];
    buttonTitle.textColor = textColor;
    buttonTitle.text = title;

    [buttonView addSubview:buttonImage];
    [buttonView addSubview:buttonTitle];
    return buttonView;
}

%hook ASCollectionView

%property (retain, nonatomic) UIButton *pipButton;
%property (retain, nonatomic) YTTouchFeedbackController *pipTouchController;

- (ELMCellNode *)nodeForItemAtIndexPath:(NSIndexPath *)indexPath {
    ELMCellNode *node = %orig;
    if ([self.accessibilityIdentifier isEqualToString:@"id.video.scrollable_action_bar"] && UseTabBarPiPButton() && !self.pipButton) {
        self.contentInset = UIEdgeInsetsMake(0, 0, 0, 73);
        if ([self collectionView:self numberOfItemsInSection:0] - 1 == indexPath.row) {
            self.pipButton = makeUnderNewPlayerButton(node, @"PiP", @"Play in PiP");
            [self addSubview:self.pipButton];

            [self.pipButton addTarget:self action:@selector(didPressPiP:event:) forControlEvents:UIControlEventTouchUpInside];
            YTTouchFeedbackController *controller = [[%c(YTTouchFeedbackController) alloc] initWithView:self.pipButton];
            controller.touchFeedbackView.customCornerRadius = 16;
            self.pipTouchController = controller;
        }
    }
    return %orig;
}

- (void)nodesDidRelayout:(NSArray <ELMCellNode *> *)nodes {
    if ([self.accessibilityIdentifier isEqualToString:@"id.video.scrollable_action_bar"] && UseTabBarPiPButton() && [nodes count] == 1) {
        CGFloat offset = nodes[0].calculatedSize.width - [nodes[0].layoutAttributes frame].size.width;
        [UIView animateWithDuration:0.3 animations:^{
            self.pipButton.center = CGPointMake(self.pipButton.center.x + offset, self.pipButton.center.y);
        }];
    }
    %orig;
}

%new(v@:@@)
- (void)didPressPiP:(UIButton *)button event:(UIEvent *)event {
    CGPoint location = [[[event allTouches] anyObject] locationInView:button];
    if (CGRectContainsPoint(button.bounds, location)) {
        UIViewController *controller = [self.collectionNode closestViewController];
        YTPlaybackStrippedWatchController *provider;
        @try {
            provider = [controller valueForKey:@"_metadataPanelStateProvider"];
        } @catch (id ex) {
            provider = [controller valueForKey:@"_ngwMetadataPanelStateProvider"];
        }
        YTWatchViewController *watchViewController = [provider valueForKey:@"_watchViewController"];
        YTPlayerViewController *playerViewController = [watchViewController valueForKey:@"_playerViewController"];
        FromUser = YES;
        bootstrapPiP(playerViewController, YES);
    }
}

- (void)dealloc {
    self.pipButton = nil;
    self.pipTouchController = nil;
    %orig;
}

%end

#pragma mark - Overlay PiP Button

%hook YTMainAppVideoPlayerOverlayViewController

- (void)updateTopRightButtonAvailability {
    %orig;
    YTMainAppVideoPlayerOverlayView *v = [self videoPlayerOverlayView];
    YTMainAppControlsOverlayView *c = [v valueForKey:@"_controlsOverlayView"];
    c.pipButton.hidden = !UsePiPButton();
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
        [self.pipButton addTarget:self action:@selector(didPressPiP:) forControlEvents:UIControlEventTouchUpInside];
        @try {
            [[self valueForKey:@"_topControlsAccessibilityContainerView"] addSubview:self.pipButton];
        } @catch (id ex) {
            [self addSubview:self.pipButton];
        }
    }
}

static NSMutableArray *topControls(YTMainAppControlsOverlayView *self, NSMutableArray *controls) {
    if (UsePiPButton())
        [controls insertObject:self.pipButton atIndex:0];
    return controls;
}

%hook YTMainAppControlsOverlayView

%property (retain, nonatomic) YTQTMButton *pipButton;

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
    if (UsePiPButton())
        self.pipButton.alpha = canceledState || !visible ? 0.0 : 1.0;
    %orig;
}

%new(@@:)
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

%new(v@:@)
- (void)didPressPiP:(id)arg {
    YTMainAppVideoPlayerOverlayViewController *c = [self valueForKey:@"_eventsDelegate"];
    YTPlayerViewController *pvc = (YTPlayerViewController *)c.parentViewController;
    FromUser = YES;
    bootstrapPiP(pvc, YES);
}

%end

#pragma mark - PiP Support

%hook AVPictureInPictureController

+ (BOOL)isPictureInPictureSupported {
    return YES;
}

%end

%hook AVPlayerController

- (BOOL)isPictureInPictureSupported {
    return YES;
}

%end

%hook AVSampleBufferDisplayLayerPlayerController

- (void)setPictureInPictureAvailable:(BOOL)available {
    %orig(YES);
}

%end

%hook MLPIPController

- (void)activatePiPController {
    %orig;
    if (!IS_IOS_OR_NEWER(iOS_15_0) && !LegacyPiP()) {
        MLHAMSBDLSampleBufferRenderingView *view = [self valueForKey:@"_HAMPlayerView"];
        CGSize size = [self renderSizeForView:view];
        AVPictureInPictureController *avpip = [self valueForKey:@"_pictureInPictureController"];
        [avpip sampleBufferDisplayLayerRenderSizeDidChangeToSize:size];
        [avpip sampleBufferDisplayLayerDidAppear];
    }
}

- (BOOL)isPictureInPictureSupported {
    return YES;
}

%new(B@:@)
- (BOOL)pictureInPictureControllerPlaybackPaused:(AVPictureInPictureController *)pictureInPictureController {
    return [self pictureInPictureControllerIsPlaybackPaused:pictureInPictureController];
}

%new(v@:@)
- (void)pictureInPictureControllerStartPlayback:(id)arg1 {
    [self pictureInPictureControllerStartPlayback];
}

%new(v@:@)
- (void)pictureInPictureControllerStopPlayback:(id)arg1 {
    [self pictureInPictureControllerStopPlayback];
}

%new(v@:{CGSize=dd})
- (void)renderingViewSampleBufferFrameSizeDidChange:(CGSize)size {
    if (!IS_IOS_OR_NEWER(iOS_15_0) && size.width && size.height) {
        AVPictureInPictureController *avpip = [self valueForKey:@"_pictureInPictureController"];
        [avpip sampleBufferDisplayLayerRenderSizeDidChangeToSize:size];
    }
}

%new(v@:@)
- (void)appWillEnterForeground:(id)arg1 {
    if (!IS_IOS_OR_NEWER(iOS_15_0) && !LegacyPiP()) {
        AVPictureInPictureController *avpip = [self valueForKey:@"_pictureInPictureController"];
        [avpip sampleBufferDisplayLayerDidAppear];
    }
}

%new(v@:@)
- (void)appWillEnterBackground:(id)arg1 {
    if (!IS_IOS_OR_NEWER(iOS_15_0) && !LegacyPiP()) {
        AVPictureInPictureController *avpip = [self valueForKey:@"_pictureInPictureController"];
        [avpip sampleBufferDisplayLayerDidDisappear];
    }
}

%end

%hook YTIIosMediaHotConfig

%new(B@:)
- (BOOL)enablePictureInPicture {
    return YES;
}

%new(B@:)
- (BOOL)enablePipForNonBackgroundableContent {
    return NonBackgroundable();
}

%new(B@:)
- (BOOL)enablePipForNonPremiumUsers {
    return YES;
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
    YTSingleVideo_isLivePlayback_override = YES;
    BOOL value = %orig;
    YTSingleVideo_isLivePlayback_override = NO;
    return value;
}

- (BOOL)canEnablePictureInPicture {
    YTSingleVideo_isLivePlayback_override = YES;
    BOOL value = %orig;
    YTSingleVideo_isLivePlayback_override = NO;
    return value;
}

- (void)didStopPictureInPicture {
    FromUser = NO;
    %orig;
}

- (void)appWillResignActive:(id)arg1 {
    // If PiP button on, PiP doesn't activate on app resign unless it's from user
    BOOL hasPiPButton = UsePiPButton() || UseTabBarPiPButton();
    BOOL disablePiP = hasPiPButton && !FromUser;
    if (disablePiP) {
        MLPIPController *pip = [self valueForKey:@"_pipController"];
        [pip setValue:nil forKey:@"_pictureInPictureController"];
    } else {
        if (LegacyPiP())
            activatePiPBase(self, YES);
        %orig;
    }
}

%end

%hook YTSingleVideoController

- (void)playerStatusDidChange:(YTPlayerStatus *)playerStatus {
    %orig;
    PiPDisabled = NoMiniPlayerPiP() && playerStatus.visibility == 1;
}

%end

%hook AVPictureInPicturePlatformAdapter

- (BOOL)isSystemPictureInPicturePossible {
    return PiPDisabled ? NO : %orig;
}

%end

%hook YTIPlayabilityStatus

- (BOOL)isPlayableInPictureInPicture {
    return YES;
}

- (BOOL)hasPictureInPicture {
    return YES;
}

%end

NSBundle *YouPiPBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"YouPiP" ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:ROOT_PATH_NS(@"/Library/Application Support/YouPiP.bundle")];
    });
    return bundle;
}

%ctor {
    if (!TweakEnabled()) return;
    NSBundle *tweakBundle = YouPiPBundle();
    PiPIconPath = [tweakBundle pathForResource:@"yt-pip-overlay" ofType:@"png"];
    TabBarPiPIconPath = [tweakBundle pathForResource:@"yt-pip-tabbar" ofType:@"png"];
    %init;
}
