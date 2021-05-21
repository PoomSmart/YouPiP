#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

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