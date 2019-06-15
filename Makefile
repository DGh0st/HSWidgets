export ARCHS = armv7 arm64 arm64e
export TARGET = iphone:clang:latest:10.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HSWidgets
HSWidgets_FILES = $(wildcard *.xm *.mm)
HSWidgets_FRAMEWORKS = UIKit CoreGraphics QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = Assets
Assets_INSTALL_PATH = /Library/Application Support/HSWidgets

include	$(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"

internal-all::
	mkdir -p $(THEOS)/include/HSWidgets
	cp $(THEOS_PROJECT_DIR)/*.h $(THEOS)/include/HSWidgets/
	cp $(THEOS_OBJ_DIR)/HSWidgets.dylib $(THEOS)/lib/libHSWidgets.dylib

SUBPROJECTS += hsspacerwidget
SUBPROJECTS += hstodaywidget
SUBPROJECTS += hsclockwidget
include $(THEOS_MAKE_PATH)/aggregate.mk
