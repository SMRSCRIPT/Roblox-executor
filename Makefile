ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = RobloxPlayer

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VR7Executor

VR7Executor_FILES = VR7Executor.mm
VR7Executor_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -O3 -fvisibility=hidden
VR7Executor_FRAMEWORKS = UIKit Foundation WebKit Security CoreGraphics
VR7Executor_LIBRARIES = substrate
VR7Executor_LDFLAGS = -Wl,-segalign,0x4000

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 RobloxPlayer || true"
