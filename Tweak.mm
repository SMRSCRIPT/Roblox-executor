#import <UIKit/UIKit.h>

// دالة إظهار الرسالة
static void ShowAlert() {
    // محاولة جلب النافذة بأكثر من طريقة لضمان التوافق
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                window = scene.windows.firstObject;
                break;
            }
        }
    }
    
    // إذا فشلت الطريقة الأولى، نستخدم الطريقة التقليدية
    if (!window) {
        window = [UIApplication sharedApplication].keyWindow;
    }

    if (window && window.rootViewController) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"0x108 Menu"
                                                                       message:@"\n✅ تم التفعيل بنجاح"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *action = [UIAlertAction actionWithTitle:@"موافق" 
                                                         style:UIAlertActionStyleDefault 
                                                       handler:nil];
        [alert addAction:action];

        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

// نقطة الانطلاق
__attribute__((constructor))
static void init() {
    // انتظار 10 ثوانٍ لضمان استقرار اللعبة
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        ShowAlert();
    });
}
