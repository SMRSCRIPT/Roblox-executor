#import <UIKit/UIKit.h>

// دالة البدء عند تشغيل اللعبة وحقن الملف
__attribute__((constructor))
static void initialize() {
    // ننتظر 10 ثوانٍ لضمان استقرار محرك اللعبة وتجاوز الفحوصات الأولية
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        @try {
            // الوصول للنافذة الرئيسية للعبة (KeyWindow)
            UIWindow *keyWindow = nil;
            if (@available(iOS 13.0, *)) {
                for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if (scene.activationState == UISceneActivationStateForegroundActive) {
                        for (UIWindow *window in scene.windows) {
                            if (window.isKeyWindow) {
                                keyWindow = window;
                                break;
                            }
                        }
                    }
                }
            } else {
                keyWindow = [UIApplication sharedApplication].keyWindow;
            }

            // التأكد من وجود الـ RootViewController لإظهار الرسالة فوقه
            UIViewController *root = keyWindow.rootViewController;
            if (root) {
                // إنشاء نافذة التنبيه (Alert)
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"0x108 Executor"
                                                                               message:@"Dylib Injected Successfully!\nReady for Lua Execution."
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                [alert addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:nil]];
                
                // عرض التنبيه
                [root presentViewController:alert animated:YES completion:nil];
            }
        } @catch (NSException *exception) {
            // في حال حدوث خطأ، سيتم طباعته في الـ Logs بدلاً من إغلاق اللعبة
            NSLog(@"[0x108] Initialization Error: %@", exception.reason);
        }
    });
}
