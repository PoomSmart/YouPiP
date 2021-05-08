TARGET = iphone:latest:10.0
ARCHS = armv7 arm64
PACKAGE_VERSION = 0.0.9
INSTALL_TARGET_PROCESSES = YouTube

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouPip
YouPip_FILES = Tweak.xm
YouPip_FRAMEWORKS = AVKit

include $(THEOS_MAKE_PATH)/tweak.mk
