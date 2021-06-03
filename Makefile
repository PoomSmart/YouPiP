TARGET = iphone:latest:10.0
ARCHS = armv7 arm64
PACKAGE_VERSION = 1.2.1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouPiP
YouPiP_FILES = Tweak.xm Compat.xm
YouPiP_CFLAGS = -fobjc-arc
YouPiP_FRAMEWORKS = AVKit
YouPiP_PRIVATE_FRAMEWORKS = MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)cp Resources/YouPiP.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/YouPiP/YouPiP.plist$(ECHO_END)
