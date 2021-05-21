TARGET = iphone:latest:10.0
ARCHS = armv7 arm64
PACKAGE_VERSION = 0.0.12
INSTALL_TARGET_PROCESSES = YouTube

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouPip
YouPip_FILES = Tweak.xm Compat.xm
YouPip_CFLAGS = -fobjc-arc
YouPip_FRAMEWORKS = AVKit
YouPip_PRIVATE_FRAMEWORKS = MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk
