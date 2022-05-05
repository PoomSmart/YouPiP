// clang-format off

#import "../PSHeader/iOSVersions.h"
#import "Header.h"
#import "../YouTubeHeader/YTUIUtils.h"
#import "../YouTubeHeader/YTHotConfig.h"
#import "../YouTubeHeader/YTSettingsViewController.h"
#import "../YouTubeHeader/YTSettingsSectionItem.h"
#import "../YouTubeHeader/YTSettingsSectionItemManager.h"
#import "../YouTubeHeader/YTAppSettingsSectionItemActionController.h"

#define FEATURE_CUTOFF_VERSION @"16.46.5"

@interface YTSettingsSectionItemManager (YouPiP)
- (void)updateYouPiPSectionWithEntry:(id)entry;
@end

static const NSInteger YouPiPSection = 200;

extern BOOL UsePiPButton();
extern BOOL UseTabBarPiPButton();
extern BOOL NoMiniPlayerPiP();
extern BOOL LegacyPiP();
extern BOOL SampleBufferWork();
extern BOOL NonBackgroundable();
extern BOOL FakeVersion();

NSString *currentVersion;

static NSString *YouPiPWarnVersionKey = @"YouPiPWarnVersionKey";

%hook YTAppSettingsPresentationData

+ (NSArray *)settingsCategoryOrder {
    NSArray *order = %orig;
    NSMutableArray *mutableOrder = [order mutableCopy];
    NSUInteger insertIndex = [order indexOfObject:@(1)];
    if (insertIndex != NSNotFound)
        [mutableOrder insertObject:@(YouPiPSection) atIndex:insertIndex + 1]; // Add YouPiP under General (ID: 1) section
    return mutableOrder;
}

%end

%hook YTSettingsSectionItemManager

%new
- (void)updateYouPiPSectionWithEntry:(id)entry {
    YTSettingsViewController *delegate = [self valueForKey:@"_dataDelegate"];
    NSMutableArray *sectionItems = [NSMutableArray array];
    YTSettingsSectionItem *activationMethod = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Use PiP Button"
        titleDescription:@"Adds a PiP button over the video control overlay to activate PiP instead of dismissing the app."
        accessibilityIdentifier:nil
        switchOn:UsePiPButton()
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:PiPActivationMethodKey];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:activationMethod];
    YTSettingsSectionItem *activationMethod2 = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Use Video Tab Bar PiP Button"
        titleDescription:@"Adds a PiP button in video tab bar to activate PiP instead of dismissing the app. App restart is required."
        accessibilityIdentifier:nil
        switchOn:UseTabBarPiPButton()
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:PiPActivationMethod2Key];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:activationMethod2];
    YTSettingsSectionItem *miniPlayer = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Disable PiP for Mini Player"
        titleDescription:@"Disables PiP while playing a video in the mini player."
        accessibilityIdentifier:nil
        switchOn:NoMiniPlayerPiP()
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:NoMiniPlayerPiPKey];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:miniPlayer];
    if (IS_IOS_BETWEEN_EEX(iOS_14_0, iOS_15_0)) {
        YTSettingsSectionItem *sampleBuffer = [%c(YTSettingsSectionItem) switchItemWithTitle:@"PiP Sample Buffer Hack"
            titleDescription:@"Implements PiP sample buffering based on iOS 15.0b5, which should reduce the chance of getting playback speedup bug. Turn off this option if you face weird issues. App restart is required."
            accessibilityIdentifier:nil
            switchOn:SampleBufferWork()
            switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:SampleBufferWorkKey];
                return YES;
            }
            settingItemId:0];
        [sectionItems addObject:sampleBuffer];
    }
    if (IS_IOS_OR_NEWER(iOS_13_0) && [currentVersion compare:@"15.33.4" options:NSNumericSearch] == NSOrderedDescending) {
        YTSettingsSectionItem *legacyPiP = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Legacy PiP"
            titleDescription:@"Uses AVPlayerLayer for PiP. This gracefully fixes speedup bug but also removes UHD options (2K/4K) from any videos. App restart is required."
            accessibilityIdentifier:nil
            switchOn:LegacyPiP()
            switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:CompatibilityModeKey];
                return YES;
            }
            settingItemId:0];
        [sectionItems addObject:legacyPiP];
    }
    YTAppSettingsSectionItemActionController *sectionItemActionController = [delegate valueForKey:@"_sectionItemActionController"];
    YTSettingsSectionItemManager *sectionItemManager = [sectionItemActionController valueForKey:@"_sectionItemManager"];
    YTHotConfig *hotConfig;
    @try {
        hotConfig = [sectionItemManager valueForKey:@"_hotConfig"];
    } @catch (id ex) {
        hotConfig = [sectionItemManager.gimme instanceForType:%c(YTHotConfig)];
    }
    YTIIosMediaHotConfig *iosMediaHotConfig = [hotConfig hotConfigGroup].mediaHotConfig.iosMediaHotConfig;
    if ([iosMediaHotConfig respondsToSelector:@selector(setEnablePipForNonBackgroundableContent:)]) {
        YTSettingsSectionItem *nonBackgroundable = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Non-backgroundable PiP"
            titleDescription:@"Enables PiP for non-backgroundable content."
            accessibilityIdentifier:nil
            switchOn:NonBackgroundable()
            switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:NonBackgroundableKey];
                return YES;
            }
            settingItemId:0];
        [sectionItems addObject:nonBackgroundable];
    }
    if ([currentVersion compare:FEATURE_CUTOFF_VERSION options:NSNumericSearch] == NSOrderedDescending) {
        YTSettingsSectionItem *fakeVersion = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Fake YouTube version"
            titleDescription:[NSString stringWithFormat:@"Set YouTube version to %@ so that PiP button under video player may show.", FEATURE_CUTOFF_VERSION]
            accessibilityIdentifier:nil
            switchOn:FakeVersion()
            switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:FakeVersionKey];
                return YES;
            }
            settingItemId:0];
        [sectionItems addObject:fakeVersion];
    }
    [delegate setSectionItems:sectionItems forCategory:YouPiPSection title:@"YouPiP" titleDescription:nil headerHidden:NO];
}

- (void)updateSectionForCategory:(NSUInteger)category withEntry:(id)entry {
    if (category == YouPiPSection) {
        [self updateYouPiPSectionWithEntry:entry];
        return;
    }
    %orig;
}

%end

%hook YTVersionUtils

+ (NSString *)appVersion {
    return FakeVersion() ? FEATURE_CUTOFF_VERSION : %orig;
}

%end

%ctor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    currentVersion = [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey];
    if (![defaults boolForKey:YouPiPWarnVersionKey]) {
        if ([currentVersion compare:@(OS_STRINGIFY(MIN_YOUTUBE_VERSION)) options:NSNumericSearch] != NSOrderedDescending) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIAlertController *warning = [UIAlertController alertControllerWithTitle:@"YouPiP" message:[NSString stringWithFormat:@"YouTube version %@ is not tested and may not be supported by YouPiP, please upgrade YouTube to at least version %s", currentVersion, OS_STRINGIFY(MIN_YOUTUBE_VERSION)] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [warning addAction:action];
                UIViewController *rootViewController = [%c(YTUIUtils) topViewControllerForPresenting];
                [rootViewController presentViewController:warning animated:YES completion:nil];
                [defaults setBool:YES forKey:YouPiPWarnVersionKey];
            });
        }
    }
    %init;
}
