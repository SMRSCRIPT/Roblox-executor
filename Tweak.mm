#import <UIKit/UIKit.h>

static void ShowSuccessAlert() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *mainWindow = nil;
        
        // الطريقة الحديثة المتوافقة مع iOS 13 وصولاً إلى iOS 26
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *window in scene.windows) {
                        if (window.isKeyWindow) {
                            mainWindow = window;
                            break;
                        }
                    }
                }
            }
        }
        
        // إذا لم نجد النافذة بالطريقة الحديثة، نحاول جلب النافذة الأولى
        if (!mainWindow) {
            mainWindow = [UIApplication sharedApplication].windows.firstObject;
        }

        if (mainWindow && mainWindow.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"0x108 System"
                                           message:@"\n✅ تم التفعيل بنجاح"
                                    preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"موافق" 
                                                               style:UIAlertActionStyleDefault 
                                                             handler:nil];
            [alert addAction:okAction];

            [mainWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        ShowSuccessAlert();
    });
}
