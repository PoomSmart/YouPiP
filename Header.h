#ifndef YOUPIP_H_
#define YOUPIP_H_

#import "AVKit-Header.h"

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

@interface YTIIosMediaHotConfig : NSObject
@property(nonatomic, assign, readwrite) BOOL enablePictureInPicture;
@property(nonatomic, assign, readwrite) BOOL enablePipForNonBackgroundableContent;
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
- (bool)iosReleasePipControllerOnMain;
@end

@interface YTPlayerStatus : NSObject
@end

@interface GPBExtensionRegistry : NSObject
- (void)addExtension:(id)extension;
@end

@interface GIMMe : NSObject
- (instancetype)allocOf:(Class)cls;
- (id)nullableInstanceForType:(id)type;
- (id)instanceForType:(id)type;
@end

@interface GIMBindingBuilder : NSObject
- (instancetype)bindType:(Class)type;
- (instancetype)initializedWith:(id (^)(id))block;
@end

@interface MLPlayerPoolImpl : NSObject
@end

@interface HAMSBDLSampleBufferRenderingView : UIView
@property(retain, nonatomic, readonly) AVSampleBufferDisplayLayer *displayLayer;
@end

@interface MLAVPlayerLayerView : UIView <MLPlayerViewProtocol, HAMPixelBufferRenderingView>
@end

@interface MLAVPIPPlayerLayerView : MLAVPlayerLayerView
- (AVPlayerLayer *)playerLayer;
- (MLAVPlayer *)delegate;
@end

@interface MLHAMSBDLSampleBufferRenderingView : HAMSBDLSampleBufferRenderingView
@end

@interface MLPIPController : NSObject <AVPictureInPictureControllerDelegate, AVPictureInPictureSampleBufferPlaybackDelegate>
@property(retain, nonatomic) MLAVPIPPlayerLayerView *AVPlayerView;
@property(retain, nonatomic) MLHAMSBDLSampleBufferRenderingView *HAMPlayerView;
- (id)initWithPlaceholderPlayerItem:(AVPlayerItem *)playerItem;
- (id)initWithPlaceholderPlayerItemResourcePath:(NSString *)placeholderPath;
- (AVPictureInPictureControllerContentSource *)newContentSource;
- (BOOL)isPictureInPictureSupported;
- (BOOL)isPictureInPictureActive;
- (BOOL)contentSourceNeedsRefresh;
- (MLAVPIPPlayerLayerView *)playerLayerView;
- (CGSize)renderSizeForView:(MLAVPIPPlayerLayerView *)view;
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

@interface MLHAMQueuePlayer : MLHAMPlayer
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
- (GIMMe *)gimme;
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

@interface YTLocalPlaybackController : NSObject
- (GIMMe *)gimme;
@end

@interface QTMIcon : NSObject
+ (UIImage *)imageWithName:(NSString *)name color:(UIColor *)color;
+ (UIImage *)tintImage:(UIImage *)image color:(UIColor *)color;
@end

@interface YTQTMButton : UIButton
@end

@interface YTMainAppVideoPlayerOverlayView : UIView
@end

@interface YTColor : NSObject
+ (UIColor *)white1;
@end

@interface YTMainAppControlsOverlayView : UIView
+ (CGFloat)topButtonAdditionalPadding;
- (YTQTMButton *)buttonWithImage:(UIImage *)image accessibilityLabel:(NSString *)accessibilityLabel verticalContentPadding:(CGFloat)verticalContentPadding;
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

@interface YTSettingsSectionItemManager : NSObject
@end

@interface YTSystemNotifications : NSObject
- (void)addSystemNotificationsObserver:(id)observer;
@end

#endif