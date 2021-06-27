TARGET = iphone:clang:latest:11.0
ARCHS = arm64
PACKAGE_VERSION = 1.4.0

ifeq ($(SIDELOADED),1)
EXTRA_CFLAGS = -DSIDELOADED
else
EXTRA_CFLAGS =
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouPiP
$(TWEAK_NAME)_FILES = Tweak.xm Compat.xm SampleBufferCompat.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc $(EXTRA_CFLAGS)
$(TWEAK_NAME)_FRAMEWORKS = AVKit

include $(THEOS_MAKE_PATH)/tweak.mk

ifneq ($(SIDELOADED),1)
internal-stage::
	$(ECHO_NOTHING)cp Resources/$(TWEAK_NAME).plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/YouPiP/YouPiP.plist$(ECHO_END)
endif
