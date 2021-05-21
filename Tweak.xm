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

@interface MLHAMQueuePlayer : NSObject
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

@interface MLPlayerPoolImpl : NSObject
- (GIMMe *)gimme;
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
- (void)addPIPControllerObserver:(id)observer;
- (void)activatePiPController;
- (void)deactivatePiPController;
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
- (instancetype)initWithDelegate:(id)delegate;
- (GIMMe *)gimme;
- (BOOL)isPictureInPictureActive;
- (BOOL)canInvokePictureInPicture;
- (BOOL)canEnablePictureInPicture;
- (void)maybeInvokePictureInPicture;
- (void)maybeEnablePictureInPicture;
- (void)play;
- (void)pause;
@end

@interface YTBackgroundabilityPolicy : NSObject
- (void)addBackgroundabilityPolicyObserver:(id)observer;
@end

@interface YTPlayerViewControllerConfig : NSObject
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

static void activatePiP(YTPlayerPIPController *controller) {
    if ([controller respondsToSelector:@selector(maybeEnablePictureInPicture)])
        [controller maybeEnablePictureInPicture];
    else if ([controller respondsToSelector:@selector(maybeInvokePictureInPicture)])
        [controller maybeInvokePictureInPicture];
    else {
        MLPIPController *pip = [controller valueForKey:@"_pipController"];
        if ([controller canEnablePictureInPicture])
            [pip activatePiPController];
        // else
        //     [pip deactivatePiPController];
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
    self = %orig;
    if (!IS_IOS_OR_NEWER(iOS_14_0) && [self valueForKey:@"_pipController"] == nil) {
        MLPIPController *pip = InjectMLPIPController();
        YTBackgroundabilityPolicy *bgPolicy = InjectYTBackgroundabilityPolicy();
        YTPlayerViewControllerConfig *playerConfig = InjectYTPlayerViewControllerConfig();
        YTHotConfig *config = InjectYTHotConfig();
        [self setValue:pip forKey:@"_pipController"];
        [self setValue:bgPolicy forKey:@"_backgroundabilityPolicy"];
        [self setValue:playerConfig forKey:@"_config"];
        [self setValue:config forKey:@"_hotConfig"];
        [self setValue:delegate forKey:@"_delegate"];
        [bgPolicy addBackgroundabilityPolicyObserver:self];
        [pip addPIPControllerObserver:self];
    }
    return self;
}

%end

// %hook MLPIPController

// - (void)activatePiPController {
//     if (IS_IOS_OR_NEWER(iOS_14_0))
//         %orig;
//     else {
//         if (![self isPictureInPictureActive]) {
//             AVPictureInPictureController *pip = [self valueForKey:@"_pictureInPictureController"];
//             if (!pip) {
//                 MLAVPIPPlayerLayerView *avpip = [self valueForKey:@"_AVPlayerView"];
//                 if (avpip) {
//                     AVPlayerLayer *playerLayer = [avpip playerLayer];
//                     pip = [[AVPictureInPictureController alloc] initWithPlayerLayer:playerLayer];
//                     [self setValue:pip forKey:@"_pictureInPictureController"];
//                     pip.delegate = self;
//                 }
//             }
//             [pip startPictureInPicture];
//         }
//     }
// }

// %end

#import <MediaRemote/MediaRemote.h>

#pragma mark - This method is the method called to stop the playback after dismissing
#pragma mark - the PIP view. We need to implement a new way to pause playback from here;
#pragma mark - MRMediaRemoteCommandStop doesn't actually do anything, and
#pragma mark - MRMediaRemoteCommandPause does pause, but breaks playback unless
#pragma mark - delayed for a little bit after PIP dismiss animation is complete.
%hook AVPictureInPictureController
- (void)pictureInPicturePlatformAdapterPrepareToStopForDismissal:(id)arg1 {
    NSLog(@"[YOUPIP] (pictureInPicturePlatformAdapterPrepareToStopForDismissal) %@", [arg1 class]);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.75 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        MRMediaRemoteSendCommand(MRMediaRemoteCommandPause, 0);
    });
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
        NSString *frameworkPath = [NSString stringWithFormat:@"%@/Frameworks/Module_Framework.framework/Module_Framework", NSBundle.mainBundle.bundlePath];
        MSImageRef ref = MSGetImageByName([frameworkPath UTF8String]);
        InjectMLPIPController = (MLPIPController *(*)())MSFindSymbol(ref, "_InjectMLPIPController");
        InjectYTBackgroundabilityPolicy = (YTBackgroundabilityPolicy *(*)())MSFindSymbol(ref, "_InjectYTBackgroundabilityPolicy");
        InjectYTPlayerViewControllerConfig = (YTPlayerViewControllerConfig *(*)())MSFindSymbol(ref, "_InjectYTPlayerViewControllerConfig");
        InjectYTHotConfig = (YTHotConfig *(*)())MSFindSymbol(ref, "_InjectYTHotConfig");
        %init(Compat);
    }
}
