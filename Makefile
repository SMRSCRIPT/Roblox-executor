TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VR7Executor

VR7Executor_FILES = VR7Executor.mm
VR7Executor_CFLAGS = -fobjc-arc -O3 -Wno-explicit-initialize-call -Wno-int-conversion -Wno-incompatible-pointer-types -Wno-unused-function -Wno-unused-variable -Wno-deprecated-declarations
VR7Executor_FRAMEWORKS = UIKit WebKit Foundation Security CoreGraphics
VR7Executor_LIBRARIES = substrate
VR7Executor_LDFLAGS = -Wl,-segalign,0x4000

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 RobloxPlayer || true"
