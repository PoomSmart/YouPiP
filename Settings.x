// clang-format off

#import "../PSHeader/iOSVersions.h"
#import "Header.h"
#import "../YouTubeHeader/YTUIUtils.h"
#import "../YouTubeHeader/YTHotConfig.h"
#import "../YouTubeHeader/YTSettingsViewController.h"
#import "../YouTubeHeader/YTSettingsSectionItem.h"
#import "../YouTubeHeader/YTSettingsSectionItemManager.h"
#import "../YouTubeHeader/YTAppSettingsSectionItemActionController.h"

extern BOOL UsePiPButton();
extern BOOL UseTabBarPiPButton();
extern BOOL NoMiniPlayerPiP();
extern BOOL LegacyPiP();
extern BOOL SampleBufferWork();
extern BOOL NonBackgroundable();
// extern BOOL PiPStartPaused();

NSString *currentVersion;

static NSString *YouPiPWarnVersionKey = @"YouPiPWarnVersionKey";

%hook YTSettingsViewController

- (void)setSectionItems:(NSMutableArray <YTSettingsSectionItem *> *)sectionItems forCategory:(NSInteger)category title:(NSString *)title titleDescription:(NSString *)titleDescription headerHidden:(BOOL)headerHidden {
    if (category == 1) {
        NSUInteger defaultPiPIndex = [sectionItems indexOfObjectPassingTest:^BOOL (YTSettingsSectionItem *item, NSUInteger idx, BOOL *stop) { 
            return item.settingItemId == 366;
        }];
        if (defaultPiPIndex == NSNotFound) {
            defaultPiPIndex = [sectionItems indexOfObjectPassingTest:^BOOL (YTSettingsSectionItem *item, NSUInteger idx, BOOL *stop) { 
                return [[item valueForKey:@"_accessibilityIdentifier"] isEqualToString:@"id.settings.restricted_mode.switch"];
            }];
        }
        if (defaultPiPIndex != NSNotFound) {
            YTSettingsSectionItem *activationMethod = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Use PiP Button"
                titleDescription:@"Adds a PiP button over the video control overlay to activate PiP instead of dismissing the app."
                accessibilityIdentifier:nil
                switchOn:UsePiPButton()
                switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:PiPActivationMethodKey];
                    return YES;
                }
                settingItemId:0];
            [sectionItems insertObject:activationMethod atIndex:defaultPiPIndex + 1];
            YTSettingsSectionItem *activationMethod2 = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Use Video Tab Bar PiP Button"
                titleDescription:@"Adds a PiP button in video tab bar to activate PiP instead of dismissing the app. App restart is required."
                accessibilityIdentifier:nil
                switchOn:UseTabBarPiPButton()
                switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:PiPActivationMethod2Key];
                    return YES;
                }
                settingItemId:0];
            [sectionItems insertObject:activationMethod2 atIndex:defaultPiPIndex + 1];
            YTSettingsSectionItem *miniPlayer = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Disable PiP for Mini Player"
                titleDescription:@"Disables PiP while playing a video in the mini player."
                accessibilityIdentifier:nil
                switchOn:NoMiniPlayerPiP()
                switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:NoMiniPlayerPiPKey];
                    return YES;
                }
                settingItemId:0];
            [sectionItems insertObject:miniPlayer atIndex:defaultPiPIndex + 1];
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
                [sectionItems insertObject:sampleBuffer atIndex:defaultPiPIndex + 1];
            }
            if (IS_IOS_OR_NEWER(iOS_13_0) && [currentVersion compare:@"15.33.4" options:NSNumericSearch] == NSOrderedDescending) {
                YTSettingsSectionItem *legacyPiP = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Legacy PiP"
                    titleDescription:@"Uses AVPlayerLayer where there's no playback speed bug. This also removes UHD video quality options (2K/4K) from any videos. App restart is required."
                    accessibilityIdentifier:nil
                    switchOn:LegacyPiP()
                    switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:CompatibilityModeKey];
                        return YES;
                    }
                    settingItemId:0];
                [sectionItems insertObject:legacyPiP atIndex:defaultPiPIndex + 1];
            }
            YTAppSettingsSectionItemActionController *sectionItemActionController = [self valueForKey:@"_sectionItemActionController"];
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
                [sectionItems insertObject:nonBackgroundable atIndex:defaultPiPIndex + 1];
            }
            // if (IS_IOS_OR_NEWER(iOS_14_0)) {
            //     YTSettingsSectionItem *startPaused = [%c(YTSettingsSectionItem) switchItemWithTitle:@"PiP starts paused"
            //         titleDescription:@"When PiP is activated, it's paused by default."
            //         accessibilityIdentifier:nil
            //         switchOn:PiPStartPaused()
            //         switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            //             [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:PiPStartPausedKey];
            //             return YES;
            //         }
            //         settingItemId:0];
            //     [sectionItems insertObject:startPaused atIndex:defaultPiPIndex + 1];
            // }
        }
    }
    %orig(sectionItems, category, title, titleDescription, headerHidden);
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
