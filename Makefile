# تحديد النظام المستهدف (iOS) والمعمارية (arm64 للجوالات الحديثة)
TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RobloxExecutor
# الملف البرمجي الذي سيتم ترجمته
RobloxExecutor_FILES = Tweak.mm
# خيارات المترجم (تجاهل التحذيرات لضمان نجاح البناء)
RobloxExecutor_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-function
# المكتبات الأساسية لواجهة النظام
RobloxExecutor_FRAMEWORKS = UIKit Foundation WebKit
# مكتبة Substrate الضرورية للحقن
RobloxExecutor_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
