ARCHS = arm64
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RobloxExecutor
RobloxExecutor_FILES = Tweak.mm
# السطر التالي يمنع المترجم من اعتبار التحذيرات أخطاء (مهم جداً)
RobloxExecutor_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error
RobloxExecutor_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
