TARGET = iphone:clang:latest:11.0
ARCHS = arm64
PACKAGE_VERSION = 1.4.10
DEBUG = 0
MIN_YOUTUBE_VERSION = 15.22.4
SAMPLE_BUFFER_HACK = 1

EXTRA_CFLAGS = -DMIN_YOUTUBE_VERSION=$(MIN_YOUTUBE_VERSION)
ifeq ($(SIDELOADED),1)
EXTRA_CFLAGS += -DSIDELOADED
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouPiP
$(TWEAK_NAME)_FILES = Tweak.x LegacyPiPCompat.x
ifeq ($(SAMPLE_BUFFER_HACK),1)
$(TWEAK_NAME)_FILES += SampleBufferCompat.x
endif
$(TWEAK_NAME)_CFLAGS = -fobjc-arc $(EXTRA_CFLAGS)
$(TWEAK_NAME)_FRAMEWORKS = AVKit

include $(THEOS_MAKE_PATH)/tweak.mk

ifneq ($(SIDELOADED),1)
internal-stage::
	$(ECHO_NOTHING)cp Resources/$(TWEAK_NAME).plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/YouPiP/YouPiP.plist$(ECHO_END)
endif
