#import "../PSHeader/iOSVersions.h"
#import "Header.h"
#import "../YouTubeHeader/YTHotConfig.h"
#import "../YouTubeHeader/YTSettingsViewController.h"
#import "../YouTubeHeader/YTSettingsSectionItem.h"

extern BOOL PiPActivationMethod();

NSArray <NSString *> *PiPActivationMethods;

%hook YTSettingsViewController

- (void)setSectionItems:(NSMutableArray <YTSettingsSectionItem *> *)sectionItems title:(NSString *)title titleDescription:(NSString *)titleDescription headerHidden:(BOOL)headerHidden {
    YTSettingsSectionItem *activationMethod = [[%c(YTSettingsSectionItem) alloc] initWithTitle:@"Use PiP Button" titleDescription:@"Adds a PiP button over the video control overlay to activate PiP instead of dismissing the app."];
    activationMethod.hasSwitch = activationMethod.switchVisible = YES;
    activationMethod.on = PiPActivationMethod();
    activationMethod.switchBlock = ^BOOL (YTSettingsCell *cell, BOOL enabled) {
        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:PiPActivationMethodKey];
        return YES;
    };
    [sectionItems insertObject:activationMethod atIndex:defaultPiPIndex + 1];
    %orig(sectionItems, title, titleDescription, headerHidden);
}

%end

%ctor {
    PiPActivationMethods = @[@"On App Dismiss", @"On PiP button tap"];
    %init;
}