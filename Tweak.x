#import <version.h>
#import <rootless.h>
#import "Header.h"
#import "../YouTubeHeader/_ASCollectionViewCell.h"
#import "../YouTubeHeader/_ASDisplayView.h"
#import "../YouTubeHeader/ASCollectionView.h"
#import "../YouTubeHeader/ELMTextNode.h"
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
#import "../YouTubeHeader/YTSlimVideoScrollableActionBarCellController.h"
#import "../YouTubeHeader/YTSlimVideoScrollableDetailsActionsView.h"
#import "../YouTubeHeader/YTSlimVideoDetailsActionView.h"
#import "../YouTubeHeader/YTISlimMetadataButtonSupportedRenderers.h"
#import "../YouTubeHeader/YTPageStyleController.h"
#import "../YouTubeHeader/YTPlaybackStrippedWatchController.h"
#import "../YouTubeHeader/YTPlayerStatus.h"
#import "../YouTubeHeader/YTWatchViewController.h"

#define PiPButtonType 801

@interface YTMainAppControlsOverlayView (YP)
@property (retain, nonatomic) YTQTMButton *pipButton;
- (void)didPressPiP:(id)arg;
- (UIImage *)pipImage;
@end

@interface ASCollectionView (YP)
@property (nonatomic) BOOL canTogglePip;
@property (retain, nonatomic) _ASDisplayView *pipButton;
@end

BOOL FromUser = NO;
BOOL PiPDisabled = NO;
_ASCollectionViewCell *saveButton = nil;

extern BOOL LegacyPiP();
extern YTHotConfig *(*InjectYTHotConfig)(void);

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

BOOL FakeVersion() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:FakeVersionKey];
}

BOOL isPictureInPictureActive(MLPIPController *pip) {
    return [pip respondsToSelector:@selector(pictureInPictureActive)] ? [pip pictureInPictureActive] : [pip isPictureInPictureActive];
}

static NSString *PiPIconPath;
static NSString *TabBarPiPIconPath;
static NSString *PiPVideoPath;

static void forcePictureInPicture(YTHotConfig *hotConfig, BOOL value) {
    [hotConfig mediaHotConfig].enablePictureInPicture = value;
    YTIIosMediaHotConfig *iosMediaHotConfig = hotConfig.hotConfigGroup.mediaHotConfig.iosMediaHotConfig;
    iosMediaHotConfig.enablePictureInPicture = value;
    if ([iosMediaHotConfig respondsToSelector:@selector(setEnablePipForNonBackgroundableContent:)])
        iosMediaHotConfig.enablePipForNonBackgroundableContent = value && NonBackgroundable();
    if ([iosMediaHotConfig respondsToSelector:@selector(setEnablePipForNonPremiumUsers:)])
        iosMediaHotConfig.enablePipForNonPremiumUsers = value;
}

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
    YTHotConfig *hotConfig;
    @try {
        if (InjectYTHotConfig)
            hotConfig = InjectYTHotConfig();
        else
            hotConfig = [self valueForKey:@"_hotConfig"];
    } @catch (id ex) {
        hotConfig = [[self gimme] instanceForType:%c(YTHotConfig)];
    }
    forcePictureInPicture(hotConfig, YES);
    YTLocalPlaybackController *local = [self valueForKey:@"_playbackController"];
    activatePiP(local, playPiP);
}

#pragma mark - Video tab bar PiP Button (16.x.x and below)

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
            if ([[_delegate valueForKey:@"_metadataPanelStateProvider"] isKindOfClass:%c(YTWatchController)]) {
                id provider = [_delegate valueForKey:@"_metadataPanelStateProvider"];
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

#pragma mark - Video tab bar PiP Button (17.x.x and up)

static _ASDisplayView *makeUnderNewPlayerButton(CGRect contentFrame, NSString *title, NSMutableAttributedString *titleAttr, NSString *accessibilityLabel) {
    CGRect buttonFrame = CGRectMake([saveButton frame].size.width, contentFrame.origin.y, 65, contentFrame.size.height);
    _ASDisplayView *buttonView = [[%c(_ASDisplayView) alloc] initWithFrame:buttonFrame];
    buttonView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.102];
    buttonView.accessibilityLabel = accessibilityLabel;
    buttonView._cornerRadius = 16; 

    UIImage *image = [%c(QTMIcon) tintImage:[UIImage imageWithContentsOfFile:TabBarPiPIconPath] color:[%c(YTColor) white1]];
    UIImageView *buttonImage = [[UIImageView alloc] initWithImage:image];
    [buttonImage setFrame:CGRectMake(12, (buttonFrame.size.height - 15.5) / 2, 15.5, 15.5)];

    UILabel *buttonTitle = [[UILabel alloc] initWithFrame:CGRectMake(33, 8, 20, 16)];
    titleAttr.mutableString.string = title;
    buttonTitle.attributedText = titleAttr;
    buttonTitle.textColor = [%c(YTColor) white3];

    [buttonView addSubview:buttonImage];
    [buttonView addSubview:buttonTitle];
    return buttonView;
}

%hook _ASCollectionViewCell

- (void)didMoveToSuperview {
    %orig;
    if (!UseTabBarPiPButton() || ![self.superview.accessibilityIdentifier isEqual:@"id.video.scrollable_action_bar"]) return;
    if ([self frame].size.width == 79 || [self frame].size.width == 86) {
        ASCollectionView *scrollView = (ASCollectionView *)self.superview;
        if ([self frame].origin.x >= [scrollView contentSize].width - 86 && [self.subviews[0].subviews count] == 1) {
            saveButton = self;
            [self layoutIfNeeded];
            _ASDisplayView *contentContainer = (_ASDisplayView *)self.subviews[0].subviews[0].subviews[0].subviews[0];
            ELMTextNode *textNode = contentContainer.keepalive_node.yogaChildren[1];
            NSMutableAttributedString *textAttr = [[NSMutableAttributedString alloc] initWithAttributedString:textNode.attributedText];
            CGRect contentFrame = [self.subviews[0].subviews[0].subviews[0] frame];
            scrollView.pipButton = makeUnderNewPlayerButton(contentFrame, @"PiP", textAttr, @"PiP button");
            // Why `self.subview[0]` ? Because when you scroll, `self` is changed and that may causes misdetection, not `self.subview[0]`
            [self.subviews[0] insertSubview:scrollView.pipButton atIndex:0];
        }
    }
}

- (void)layoutSubviews {
    %orig;
    // Handle the transition between "Save" and "Saved" buttons
    if (UseTabBarPiPButton() && self == saveButton) {
        ASCollectionView *scrollView = (ASCollectionView *)self.superview;
        scrollView.pipButton.center = CGPointMake([self frame].size.width + 32.5, [self frame].size.height / 2);
    }
}

%end

%hook ASCollectionView

%property (nonatomic) BOOL canTogglePip;
%property (retain, nonatomic) _ASDisplayView *pipButton;

- (void)layoutSubviews {
    %orig;
    if (UseTabBarPiPButton() && [self.accessibilityIdentifier isEqual:@"id.video.scrollable_action_bar"]) {
        self.delaysContentTouches = NO;
        self.contentInset = UIEdgeInsetsMake(0, 0, 0, 73);
        
        // Fake calls
        for (_ASCollectionViewCell *cell in self.subviews) {
            [cell didMoveToSuperview];
        }
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig;
    if (UseTabBarPiPButton() && [self.accessibilityIdentifier isEqual:@"id.video.scrollable_action_bar"]) {
        self.canTogglePip = NO;
        UITouch *touch = [[touches allObjects] objectAtIndex:0];
        CGPoint location = [touch locationInView:self];
        CGRect validRect = CGRectMake(CGRectGetMaxX([saveButton frame]), [self.pipButton frame].origin.y, 65, [self.pipButton frame].size.height);
        if (CGRectContainsPoint(validRect, location)) {
            self.canTogglePip = YES;
            [UIView animateWithDuration:0.1 animations:^{
                self.pipButton.transform = CGAffineTransformMakeScale(0.929, 0.929);
            } completion:nil];
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig;
    if (UseTabBarPiPButton() && [self.accessibilityIdentifier isEqual:@"id.video.scrollable_action_bar"] && self.canTogglePip) {
        UITouch *touch = [[touches allObjects] objectAtIndex:0];
        CGPoint location = [touch locationInView:self];
        CGRect validRect = CGRectMake(CGRectGetMaxX([saveButton frame]), [self.pipButton frame].origin.y, 65, [self.pipButton frame].size.height);
        self.canTogglePip = CGRectContainsPoint(validRect, location);
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig;
    if (UseTabBarPiPButton() && [self.accessibilityIdentifier isEqual:@"id.video.scrollable_action_bar"]) {
        [UIView animateWithDuration:0.2 animations:^{
            self.pipButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];

        if (self.canTogglePip) {
            UIViewController *controller = [[self.superview valueForKey:@"_keepalive_node"] closestViewController];
            YTPlaybackStrippedWatchController *provider = [controller valueForKey:@"_metadataPanelStateProvider"];
            YTWatchViewController *watchViewController = [provider valueForKey:@"_watchViewController"];
            YTPlayerViewController *playerViewController = [watchViewController valueForKey:@"_playerViewController"];
            FromUser = YES;
            bootstrapPiP(playerViewController, YES);
        }
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig;
    if (UseTabBarPiPButton() && [self.accessibilityIdentifier isEqual:@"id.video.scrollable_action_bar"]) {
        [UIView animateWithDuration:0.2 animations:^{
            self.pipButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    }
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
    FromUser = YES;
    bootstrapPiP([c delegate], YES);
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

%hook MLDefaultPlayerViewFactory

- (MLAVPlayerLayerView *)AVPlayerViewForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig {
    forcePictureInPicture([self valueForKey:@"_hotConfig"], YES);
    return %orig;
}

%end

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

- (YTSettingsSectionItem *)pictureInPictureSectionItem {
    forcePictureInPicture([self valueForKey:@"_hotConfig"], YES);
    return %orig;
}

- (YTSettingsSectionItem *)pictureInPictureSectionItem:(id)arg1 {
    forcePictureInPicture([self valueForKey:@"_hotConfig"], YES);
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
    forcePictureInPicture(getHotConfig(self), YES);
    YTSingleVideo_isLivePlayback_override = YES;
    BOOL value = %orig;
    YTSingleVideo_isLivePlayback_override = NO;
    return value;
}

- (BOOL)canEnablePictureInPicture {
    forcePictureInPicture(getHotConfig(self), YES);
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
    PiPVideoPath = [tweakBundle pathForResource:@"PiPPlaceholderAsset" ofType:@"mp4"];
    PiPIconPath = [tweakBundle pathForResource:@"yt-pip-overlay" ofType:@"png"];
    TabBarPiPIconPath = [tweakBundle pathForResource:@"yt-pip-tabbar" ofType:@"png"];
    %init;
}
