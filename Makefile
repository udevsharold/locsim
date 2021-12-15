export ARCHS = arm64 arm64e

export DEBUG = 1
export FINALPACKAGE = 0

export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/

TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = locsim

$(TOOL_NAME)_FILES = main.m
$(TOOL_NAME)_CFLAGS = -fobjc-arc
$(TOOL_NAME)_CODESIGN_FLAGS = -Sentitlements.plist
$(TOOL_NAME)_INSTALL_PATH = /usr/local/bin
$(TOOL_NAME)_FRAMEWORKS = CoreLocation

include $(THEOS_MAKE_PATH)/tool.mk
