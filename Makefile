TARGET = iphone:clang:latest:9.0
ARCHS = armv7 arm64
PACKAGE_VERSION = 1.0.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouPiP
$(TWEAK_NAME)_FILES = Tweak.x Settings.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = AVKit

include $(THEOS_MAKE_PATH)/tweak.mk
