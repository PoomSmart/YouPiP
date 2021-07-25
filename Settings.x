#import "../PSHeader/iOSVersions.h"
#import "Header.h"
#import "../YouTubeHeader/YTHotConfig.h"
#import "../YouTubeHeader/YTSettingsViewController.h"
#import "../YouTubeHeader/YTSettingsSectionItem.h"
#import "../YouTubeHeader/YTSettingsSectionItemManager.h"
#import "../YouTubeHeader/YTAppSettingsSectionItemActionController.h"
#import "../YouTubeHeader/YTAppSettingsStore.h"

static const int PiPActivationMethodNumber = 1030;
static const int CompatibilityModeNumber = 1031;
static const int SampleBufferWorkNumber = 1032;
static const int NonBackgroundableNumber = 1033;
// static const int PiPStartPausedNumber = 1034;

extern BOOL PiPActivationMethod();
extern BOOL CompatibilityMode();
extern BOOL SampleBufferWork();
extern BOOL NonBackgroundable();
// extern BOOL PiPStartPaused();

NSString *currentVersion;
NSArray <NSString *> *PiPActivationMethods;

static NSString *YouPiPWarnVersionKey = @"YouPiPWarnVersionKey";

static BOOL IsCustomSetting(int setting) {
    return setting == PiPActivationMethodNumber || setting == CompatibilityModeNumber || setting == SampleBufferWorkNumber || setting == NonBackgroundableNumber;
}

%hook YTAppSettingsStore

+ (NSUInteger)valueTypeForSetting:(int)setting {
    return IsCustomSetting(setting) ? 1 : %orig;
}

- (void)setBool:(BOOL)value forSetting:(int)setting {
    if (IsCustomSetting(setting)) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        switch (setting) {
            case PiPActivationMethodNumber:
                [defaults setBool:value forKey:PiPActivationMethodKey];
                break;
            case CompatibilityModeNumber:
                [defaults setBool:value forKey:CompatibilityModeKey];
                break;
            case SampleBufferWorkNumber:
                [defaults setBool:value forKey:SampleBufferWorkKey];
                break;
            case NonBackgroundableNumber:
                [defaults setBool:value forKey:NonBackgroundableKey];
                break;
            // case PiPStartPausedNumber:
            //     [defaults setBool:value forKey:PiPStartPausedKey];
            //     break;
        }
        return;
    }
    %orig;
}

- (BOOL)boolForSetting:(int)setting {
    if (IsCustomSetting(setting)) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        switch (setting) {
            case PiPActivationMethodNumber:
                return [defaults boolForKey:PiPActivationMethodKey];
            case CompatibilityModeNumber:
                return [defaults boolForKey:CompatibilityModeKey];
            case SampleBufferWorkNumber:
                return [defaults boolForKey:SampleBufferWorkKey];
            case NonBackgroundableNumber:
                return [defaults boolForKey:NonBackgroundableKey];
            // case PiPStartPausedNumber:
            //     return [defaults boolForSetting:PiPStartPausedKey];
        }
    }
    return %orig;
}

%end

%hook YTSettingsViewController

- (void)setSectionItems:(NSMutableArray <YTSettingsSectionItem *> *)sectionItems forCategory:(NSInteger)category title:(NSString *)title titleDescription:(NSString *)titleDescription headerHidden:(BOOL)headerHidden {
    if (category == 1) {
        NSUInteger defaultPiPIndex = [sectionItems indexOfObjectPassingTest:^BOOL (YTSettingsSectionItem *item, NSUInteger idx, BOOL *stop) { 
            return item.settingItemId == 366;
        }];
        YTAppSettingsSectionItemActionController *sectionItemActionController = [self valueForKey:@"_sectionItemActionController"];
        YTSettingsSectionItemManager *sectionItemManager = [sectionItemActionController valueForKey:@"_sectionItemManager"];
        YTAppSettingsStore *appSettingsStore = [sectionItemManager valueForKey:@"_appSettingsStore"];
        if (defaultPiPIndex != NSNotFound) {
            YTSettingsSectionItem *activationMethod = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Use PiP Button"
                titleDescription:@"Adds a PiP button over the video control overlay to activate PiP instead of dismissing the app."
                accessibilityIdentifier:nil
                switchOn:[appSettingsStore boolForSetting:PiPActivationMethodNumber]
                switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                    if (appSettingsStore) {
                        [appSettingsStore setBool:enabled forSetting:PiPActivationMethodNumber];
                        return YES;
                    }
                    return NO;
                }
                settingItemId:PiPActivationMethodNumber];
            [sectionItems insertObject:activationMethod atIndex:defaultPiPIndex + 1];
            if (IS_IOS_BETWEEN_EEX(iOS_14_0, iOS_15_0)) {
                YTSettingsSectionItem *sampleBuffer = [%c(YTSettingsSectionItem) switchItemWithTitle:@"PiP Sample Buffer Hack"
                    titleDescription:@"Implements PiP sample buffering based on iOS 15.0b2, which should reduce the chance of getting playback speedup bug. Turn off this option if you face weird issues. App restart is required."
                    accessibilityIdentifier:nil
                    switchOn:[appSettingsStore boolForSetting:SampleBufferWorkNumber]
                    switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                        if (appSettingsStore) {
                            [appSettingsStore setBool:enabled forSetting:SampleBufferWorkNumber];
                            return YES;
                        }
                        return NO;
                    }
                    settingItemId:SampleBufferWorkNumber];
                [sectionItems insertObject:sampleBuffer atIndex:defaultPiPIndex + 1];
            }
            if ([currentVersion compare:@"15.33.4" options:NSNumericSearch] == NSOrderedDescending) {
                YTSettingsSectionItem *legacyPiP = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Legacy PiP"
                    titleDescription:@"Uses AVPlayerLayer where there's no playback speed bug. This also removes UHD video quality options (2K/4K) from any videos and YTUHD tweak cannot fix this. PiP button will be forcefully enabled. App restart is required."
                    accessibilityIdentifier:nil
                    switchOn:[appSettingsStore boolForSetting:CompatibilityModeNumber]
                    switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                        if (appSettingsStore) {
                            [appSettingsStore setBool:enabled forSetting:CompatibilityModeNumber];
                            return YES;
                        }
                        return NO;
                    }
                    settingItemId:CompatibilityModeNumber];
                [sectionItems insertObject:legacyPiP atIndex:defaultPiPIndex + 1];
            }
            YTHotConfig *hotConfig = [sectionItemManager valueForKey:@"_hotConfig"];
            YTIIosMediaHotConfig *iosMediaHotConfig = [[[hotConfig hotConfigGroup] mediaHotConfig] iosMediaHotConfig];
            if ([iosMediaHotConfig respondsToSelector:@selector(setEnablePipForNonBackgroundableContent:)]) {
                YTSettingsSectionItem *nonBackgroundable = [%c(YTSettingsSectionItem) switchItemWithTitle:@"Non-backgroundable PiP"
                    titleDescription:@"Enables PiP for non-backgroundable content."
                    accessibilityIdentifier:nil
                    switchOn:[appSettingsStore boolForSetting:NonBackgroundableNumber]
                    switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                        if (appSettingsStore) {
                            [appSettingsStore setBool:enabled forSetting:NonBackgroundableNumber];
                            return YES;
                        }
                        return NO;
                    }
                    settingItemId:NonBackgroundableNumber];
                [sectionItems insertObject:nonBackgroundable atIndex:defaultPiPIndex + 1];
            }
            // if (IS_IOS_OR_NEWER(iOS_14_0)) {
            //     YTSettingsSectionItem *startPaused = [%c(YTSettingsSectionItem) switchItemWithTitle:@"PiP starts paused"
            //         titleDescription:@"When PiP is activated, it's paused by default."
            //         accessibilityIdentifier:nil
            //         switchOn:[appSettingsStore boolForSetting:PiPStartPausedNumber]
            //         switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            //             if (appSettingsStore) {
            //                 [appSettingsStore setBool:enabled forSetting:PiPStartPausedNumber];
            //                 return YES;
            //             }
            //             return NO;
            //         }
            //         settingItemId:PiPStartPausedNumber];
            //     [sectionItems insertObject:startPaused atIndex:defaultPiPIndex + 1];
            // }
        }
    }
    %orig(sectionItems, category, title, titleDescription, headerHidden);
}

%end

%ctor {
    NSBundle *bundle = [NSBundle mainBundle];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    currentVersion = [bundle infoDictionary][(__bridge NSString *)kCFBundleVersionKey];
    PiPActivationMethods = @[@"On App Dismiss", @"On PiP button tap"];
    if (![defaults boolForKey:YouPiPWarnVersionKey]) {
        if ([currentVersion compare:@(OS_STRINGIFY(MIN_YOUTUBE_VERSION)) options:NSNumericSearch] != NSOrderedAscending) {
            UIAlertController *warning = [UIAlertController alertControllerWithTitle:@"YouPiP" message:[NSString stringWithFormat:@"YouTube version %@ is not tested and may not be supported by YouPiP, please upgrade YouTube to at least version %s", currentVersion, OS_STRINGIFY(MIN_YOUTUBE_VERSION)] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [warning addAction:action];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:warning animated:YES completion:nil];
            [defaults setBool:YES forKey:YouPiPWarnVersionKey];
        }
    }
    %init;
}