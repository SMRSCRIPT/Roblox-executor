ARCHS = arm64
TARGET := iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RobloxExecutor
# تأكد أن اسم الملف هنا يطابق اسم ملف الكود الخاص بك
RobloxExecutor_FILES = Tweak.mm
RobloxExecutor_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error
# إضافة المكتبات المطلوبة للكود الجديد
RobloxExecutor_FRAMEWORKS = UIKit Foundation WebKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
