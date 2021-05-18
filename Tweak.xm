#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <version.h>

@interface AVPictureInPictureControllerContentSource : NSObject
- (AVSampleBufferDisplayLayer *)sampleBufferDisplayLayer;
@end

@interface AVPictureInPictureController (Private)
@property(nonatomic, retain) AVPictureInPictureControllerContentSource *contentSource;
@property(nonatomic, retain) id prerollDelegate;
- (instancetype)initWithContentSource:(AVPictureInPictureControllerContentSource *)contentSource;
- (void)sampleBufferDisplayLayerRenderSizeDidChangeToSize:(CGSize)renderSize;
- (void)sampleBufferDisplayLayerDidAppear;
@end

@class MLAVPlayer, MLVideo, MLInnerTubePlayerConfig;

@protocol MLPlayerViewProtocol
- (void)makeActivePlayer;
- (void)setVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig;
@end

@protocol MLHAMPlayerViewProtocol
- (void)makeActivePlayer;
- (void)setVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig;
@end

@protocol HAMPixelBufferRenderingView
@end

@interface YTIPictureInPictureRendererRoot : NSObject
+ (id)pictureInPictureRenderer;
@end

@interface YTCommonUtils : NSObject
+ (NSBundle *)bundleForClass:(Class)c;
@end

@interface YTIHamplayerHotConfig : NSObject
@property(assign) int renderViewType;
@end

@interface YTIHamplayerConfig : NSObject
@property(assign) int renderViewType;
@end

@interface YTIIosMediaHotConfig : NSObject
@property(nonatomic, assign, readwrite) BOOL enablePictureInPicture;
@end

@interface YTIMediaHotConfig : NSObject
- (YTIIosMediaHotConfig *)iosMediaHotConfig;
@end

@interface YTIHotConfigGroup : NSObject
- (YTIMediaHotConfig *)mediaHotConfig;
@end

@interface YTHotConfig : NSObject
- (YTIHotConfigGroup *)hotConfigGroup;
- (YTIIosMediaHotConfig *)mediaHotConfig;
- (YTIHamplayerHotConfig *)hamplayerHotConfig;
@end

@interface YTPlayerStatus : NSObject
@end

@interface GIMMe
- (instancetype)allocOf:(Class)cls;
- (id)nullableInstanceForType:(id)type;
- (id)instanceForType:(id)type;
@end

@interface MLAVPlayerLayerView : UIView <MLPlayerViewProtocol, HAMPixelBufferRenderingView>
@end

@interface MLAVPIPPlayerLayerView : MLAVPlayerLayerView
- (AVPlayerLayer *)playerLayer;
- (MLAVPlayer *)delegate;
@end

@interface MLHAMSBDLSampleBufferRenderingView : MLAVPIPPlayerLayerView
@end

@interface MLPIPController : NSObject <AVPictureInPictureControllerDelegate>
@property(retain, nonatomic) MLAVPIPPlayerLayerView *AVPlayerView;
@property(retain, nonatomic) MLHAMSBDLSampleBufferRenderingView *HAMPlayerView;
- (id)initWithPlaceholderPlayerItem:(AVPlayerItem *)playerItem;
- (id)initWithPlaceholderPlayerItemResourcePath:(NSString *)placeholderPath;
- (AVPictureInPictureControllerContentSource *)newContentSource;
- (BOOL)isPictureInPictureSupported;
- (BOOL)isPictureInPictureActive;
- (BOOL)contentSourceNeedsRefresh;
- (GIMMe *)gimme;
- (MLAVPIPPlayerLayerView *)playerLayerView;
- (CGSize)renderSizeForView:(MLAVPIPPlayerLayerView *)view;
- (void)setGimme:(GIMMe *)gimme;
- (void)initializePictureInPicture;
- (BOOL)startPictureInPicture;
- (void)stopPictureInPicture;
@end

@interface MLRemoteStream : NSObject
- (NSURL *)URL;
@end

@interface MLStreamingData : NSObject
- (NSArray <MLRemoteStream *> *)adaptiveStreams;
@end

@interface MLVideo : NSObject
- (MLStreamingData *)streamingData;
@end

@interface MLInnerTubePlayerConfig : NSObject
- (YTIHamplayerConfig *)hamplayerConfig;
@end

@interface MLPlayerStickySettings : NSObject
@property(assign) float rate;
@end

@interface MLAVAssetPlayer : NSObject
- (AVPlayerItem *)playerItem;
@end

@interface MLPlayer : AVPlayer
@property(assign) float rate;
- (instancetype)initWithVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings externalPlaybackActive:(BOOL)externalPlaybackActive;
- (BOOL)externalPlaybackActive;
@end

@interface MLAVPlayer : MLPlayer
@property(assign) BOOL active;
- (GIMMe *)gimme;
- (MLVideo *)video;
- (MLInnerTubePlayerConfig *)config;
- (UIView <MLPlayerViewProtocol> *)playerView;
- (UIView <MLPlayerViewProtocol> *)renderingView;
- (MLAVAssetPlayer *)assetPlayer;
- (void)setRenderingView:(UIView <MLPlayerViewProtocol> *)renderingView;
@end

@interface MLHAMPlayer : AVPlayer
- (instancetype)initWithVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings playerViewProvider:(id)playerViewProvider;
@end

@interface MLPlayerPool : NSObject
- (void)createHamResourcesForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig;
- (GIMMe *)gimme;
@end

@interface YTSingleVideo : NSObject
- (MLVideo *)video;
@end

@interface YTIFormatStream : NSObject
- (NSString *)URL;
@end

@interface MLFormat : NSObject
@end

@class YTLocalPlaybackController;

@interface YTSingleVideoController : NSObject
- (YTSingleVideo *)singleVideo;
- (YTSingleVideo *)videoData;
- (YTLocalPlaybackController *)delegate;
- (NSArray <MLFormat *> *)selectableVideoFormats;
@end

@interface YTPlaybackControllerUIWrapper : NSObject
- (YTSingleVideoController *)activeVideo;
- (YTSingleVideoController *)contentVideo;
@end

@interface YTPlayerViewController : UIViewController
@end

@interface YTPlayerView : UIView
@property(retain, nonatomic) MLAVPIPPlayerLayerView *pipRenderingView;
@property(retain, nonatomic) MLAVPlayerLayerView *renderingView;
- (YTPlaybackControllerUIWrapper *)playerViewDelegate;
@end

@interface YTPlayerPIPController : NSObject
@property(retain, nonatomic) YTSingleVideoController *activeSingleVideo;
- (instancetype)initWithPlayerView:(id)playerView delegate:(id)delegate;
- (GIMMe *)gimme;
- (BOOL)isPictureInPictureActive;
- (BOOL)canInvokePictureInPicture;
- (BOOL)canEnablePictureInPicture;
- (void)maybeInvokePictureInPicture;
- (void)maybeEnablePictureInPicture;
- (void)play;
- (void)pause;
@end

@interface YTLocalPlaybackController : NSObject {
    YTPlayerPIPController *_playerPIPController;
}
- (GIMMe *)gimme;
@end

@interface GIMBindingBuilder : NSObject
- (GIMBindingBuilder *)bindType:(Class)type;
- (GIMBindingBuilder *)initializedWith:(id (^)(id))block;
@end

@interface YTMainAppVideoPlayerOverlayView : UIView
@end

@interface YTMainAppControlsOverlayView : UIView
@end

@interface YTMainAppVideoPlayerOverlayViewController : UIViewController
- (YTMainAppVideoPlayerOverlayView *)videoPlayerOverlayView;
- (YTPlayerViewController *)delegate;
@end

@interface YTUIResources : NSObject
@end

@interface YTPlayerResources : NSObject
@end

@interface MLDefaultPlayerViewFactory : NSObject
- (BOOL)canUsePlayerView:(UIView *)playerView forVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)config;
- (MLAVPlayerLayerView *)AVPlayerViewForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)config;
@end

static void forceEnablePictureInPictureInternal(YTHotConfig *hotConfig) {
    [hotConfig mediaHotConfig].enablePictureInPicture = YES;
    [[[hotConfig hotConfigGroup] mediaHotConfig] iosMediaHotConfig].enablePictureInPicture = YES;
}

%hook YTMainAppControlsOverlayView

- (id)initWithDelegate:(id)delegate {
    self = %orig;
    if (self) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            YTMainAppVideoPlayerOverlayViewController *c = [self valueForKey:@"_eventsDelegate"];
            YTPlayerViewController *p = [c delegate];
            YTHotConfig *hotConfig = [p valueForKey:@"_hotConfig"];
            forceEnablePictureInPictureInternal(hotConfig);
            YTLocalPlaybackController *local = [p valueForKey:@"_playbackController"];
            YTPlayerPIPController *controller = [local valueForKey:@"_playerPIPController"];
            if ([controller respondsToSelector:@selector(maybeEnablePictureInPicture)])
                [controller maybeEnablePictureInPicture];
            else if ([controller respondsToSelector:@selector(maybeInvokePictureInPicture)])
                [controller maybeInvokePictureInPicture];
        });
    }
    return self;
}
%end

static BOOL overridePictureInPicture = NO;
static BOOL isInPictureInPicture = NO;

%hook YTLocalPlaybackController

- (id)initWithParentResponder:(id)arg2 overlayFactory:(id)arg3 playerView:(id)playerView playbackControllerDelegate:(id)arg5 viewportSizeProvider:(id)arg6 lightweightPlayback:(bool)arg7 {
    self = %orig;
    if ([self valueForKey:@"_playerPIPController"] == nil) {
        YTPlayerPIPController *pip = [(YTPlayerPIPController *)[[self gimme] allocOf:%c(YTPlayerPIPController)] initWithPlayerView:playerView delegate:self];
        [self setValue:pip forKey:@"_playerPIPController"];
    }
    return self;
}

- (void)videoSequencer:(id)sequencer didActivateVideoController:(YTSingleVideoController *)videoController {
    %orig;
    if (!IS_IOS_OR_NEWER(iOS_14_0)) {
        YTPlayerPIPController *pip = [self valueForKey:@"_playerPIPController"];
        [pip setActiveSingleVideo:videoController];
    }
}

- (void)resetWithCurrentVideoSequencer {
    if (!IS_IOS_OR_NEWER(iOS_14_0)) {
        YTPlayerPIPController *pip = [self valueForKey:@"_playerPIPController"];
        [pip setActiveSingleVideo:nil];
    }
    %orig;
}

- (void)resetToState:(int)state {
    if (!IS_IOS_OR_NEWER(iOS_14_0)) {
        YTPlayerPIPController *pip = [self valueForKey:@"_playerPIPController"];
        [pip setActiveSingleVideo:nil];
    }
    %orig;
}

- (void)play {
    %orig;
    if (!IS_IOS_OR_NEWER(iOS_14_0)) {
        YTPlayerPIPController *pip = [self valueForKey:@"_playerPIPController"];
        [pip play];
    }
}

- (void)pause {
    %orig;
    if (!IS_IOS_OR_NEWER(iOS_14_0)) {
        YTPlayerPIPController *pip = [self valueForKey:@"_playerPIPController"];
        [pip pause];
    }
}

- (YTPlayerStatus *)playerStatusWithPlayerViewLayout:(int)layout {
    overridePictureInPicture = !IS_IOS_OR_NEWER(iOS_14_0);
    if (overridePictureInPicture) {
        YTPlayerPIPController *pip = [self valueForKey:@"_playerPIPController"];
        isInPictureInPicture = [pip isPictureInPictureActive];
    }
    YTPlayerStatus *status = %orig;
    overridePictureInPicture = NO;
    return status;
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

%hook MLHAMQueuePlayer

- (id)initWithStickySettings:(id)stickySettings playerViewProvider:(id)playerViewProvider playerConfiguration:(id)playerConfiguration {
    self = %orig;
    if ([self valueForKey:@"_pipController"] == nil)
        [self setValue:[[self gimme] nullableInstanceForType:%c(MLPIPController)] forKey:@"_pipController"];
    return self;
}

%end

%hook MLAVPlayer

- (bool)isPictureInPictureActive {
    return [(MLPIPController *)[[self gimme] nullableInstanceForType:%c(MLPIPController)] isPictureInPictureActive];
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
        MLPIPController *pip = (MLPIPController *)[[self gimme] nullableInstanceForType:%c(MLPIPController)];
        [r setValue:pip forKey:@"_pipController"];
    }
    return r;
}

- (id)acquirePlayerForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings {
    if (IS_IOS_OR_NEWER(iOS_14_0))
        return %orig;
    MLAVPlayer *player = [(MLAVPlayer *)[[self gimme] allocOf:%c(MLAVPlayer)] initWithVideo:video playerConfig:playerConfig stickySettings:stickySettings externalPlaybackActive:[(MLPlayer *)[self valueForKey:@"_activePlayer"] externalPlaybackActive]];
    if (stickySettings)
        player.rate = stickySettings.rate;
    return player;
}

- (void)setActivePlayer:(MLAVPlayer *)player {
    %orig;
    if (!IS_IOS_OR_NEWER(iOS_14_0)) {
        UIView <MLPlayerViewProtocol> *renderingView = [self valueForKey:@"_renderingView"];
        MLPIPController *pip = [self valueForKey:@"_pipController"];
        if ([renderingView isKindOfClass:%c(MLAVPIPPlayerLayerView)]) {
            [pip setAVPlayerView:(MLAVPIPPlayerLayerView *)renderingView];
        } else if ([renderingView isKindOfClass:%c(MLHAMSBDLSampleBufferRenderingView)]) {
            [pip setHAMPlayerView:(MLHAMSBDLSampleBufferRenderingView *)renderingView];
        }
    }
}

%end

%hook YTPlayerStatus

- (id)initWithExternalPlayback:(BOOL)externalPlayback
    backgroundPlayback:(BOOL)backgroundPlayback
    inlinePlaybackActive:(BOOL)inlinePlaybackActive
    cardboardModeActive:(BOOL)cardboardModeActive
    layout:(int)layout
    userAudioOnlyModeActive:(BOOL)userAudioOnlyModeActive
    blackoutActive:(BOOL)blackoutActive
    clipID:(id)clipID
    accountLinkState:(id)accountLinkState
    muted:(BOOL)muted
    pictureInPicture:(BOOL)pictureInPicture {
        return %orig(externalPlayback,
            backgroundPlayback,
            inlinePlaybackActive,
            cardboardModeActive,
            layout,
            userAudioOnlyModeActive,
            blackoutActive,
            clipID,
            accountLinkState,
            muted,
            overridePictureInPicture ? isInPictureInPicture : pictureInPicture);
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
    %init;
    if (!IS_IOS_OR_NEWER(iOS_14_0)) {
        %init(Compat);
    }
}