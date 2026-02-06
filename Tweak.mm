#import <UIKit/UIKit.h>

@interface SuccessNotifier : NSObject
+ (void)show;
@end

@implementation SuccessNotifier
+ (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                    win = ((UIWindowScene *)scene).windows.firstObject;
                    break;
                }
            }
        }
        if (!win) win = [UIApplication sharedApplication].windows.firstObject;

        if (win && win.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"0x108"
                                           message:@"\n✅ تم التفعيل بنجاح"
                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"موافق" style:UIAlertActionStyleDefault handler:nil]];
            [win.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
@end

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [SuccessNotifier show];
    });
}
