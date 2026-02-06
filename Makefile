# استهداف معمارية 64 بت وأنظمة iOS الحديثة
ARCHS = arm64
TARGET := iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RobloxExecutor
RobloxExecutor_FILES = Tweak.mm
RobloxExecutor_CFLAGS = -fobjc-arc
RobloxExecutor_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
