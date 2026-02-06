#import <UIKit/UIKit.h>

// دالة إظهار القائمة
static void ShowSuccessMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        
        // طريقة جلب النافذة المتوافقة مع iOS 26
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }

        if (window && window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"0x108 Status"
                                           message:@"\n✅ تم التفعيل بنجاح"
                                    preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"استمرار" 
                                                         style:UIAlertActionStyleDefault 
                                                       handler:nil];
            [alert addAction:ok];

            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

// محرك التشغيل عند الحقن (Constructor)
__attribute__((constructor))
static void initialize() {
    // انتظار 10 ثوانٍ لضمان استقرار اللعبة تماماً
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        ShowSuccessMenu();
    });
}
