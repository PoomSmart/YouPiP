TARGET = iphone:clang:latest:11.0
ARCHS = arm64
PACKAGE_VERSION = 1.5.8
DEBUG = 0
MIN_YOUTUBE_VERSION = 15.10.4

EXTRA_CFLAGS = -DMIN_YOUTUBE_VERSION=$(MIN_YOUTUBE_VERSION)
ifeq ($(SIDELOADED),1)
EXTRA_CFLAGS += -DSIDELOADED
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouPiP
$(TWEAK_NAME)_FILES = Tweak.x Settings.x LegacyPiPCompat.x SampleBufferCompat.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc $(EXTRA_CFLAGS)
$(TWEAK_NAME)_FRAMEWORKS = AVKit

include $(THEOS_MAKE_PATH)/tweak.mk
