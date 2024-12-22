TARGET = iphone:clang:latest:11.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = YouTube
PACKAGE_VERSION = 1.9.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouPiP
$(TWEAK_NAME)_FILES = Tweak.x Settings.x LegacyPiPCompat.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc $(EXTRA_CFLAGS)
$(TWEAK_NAME)_FRAMEWORKS = AVFoundation AVKit UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
