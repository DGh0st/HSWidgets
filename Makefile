export ARCHS = armv7 arm64 arm64e
export TARGET = iphone:clang:latest:10.0

PUBLIC_HEADERS_DIR := api api/core

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HSWidgets
HSWidgets_FILES = $(wildcard api/core/*.mm api/*.mm api/*.xm editing/*.mm *.mm *.xm)
HSWidgets_FRAMEWORKS = UIKit CoreGraphics QuartzCore
HSWidgets_PRIVATE_FRAMEWORKS = Preferences
HSWidgets_CFLAGS = -Iapi -Iapi/core -Iediting -Iprivate_headers -std=c++11 -stdlib=libc++
HSWidgets_LDFLAGS = -std=c++11 -stdlib=libc++

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = Assets
Assets_INSTALL_PATH = /Library/Application Support/HSWidgets

include	$(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"

FRAMEWORK_NAME = HSWidgets
HSWIDGETS_THEOS_TEMPLATE_STAGING_DIR = $(THEOS_PROJECT_DIR)/theos_template
FRAMEWORK_PATH = $(HSWIDGETS_THEOS_TEMPLATE_STAGING_DIR)/$(FRAMEWORK_NAME).framework
export TBD_INPUT_PATH = $(THEOS_OBJ_DIR)/$(FRAMEWORK_NAME).dylib
export TBD_OUTPUT_PATH = $(FRAMEWORK_PATH)/$(FRAMEWORK_NAME).tbd
internal-all::
	mkdir -p $(FRAMEWORK_PATH)/Headers
	find $(PUBLIC_HEADERS_DIR) -maxdepth 1 -name "*.h" -exec cp {} $(FRAMEWORK_PATH)/Headers \;
	chmod +x $(HSWIDGETS_THEOS_TEMPLATE_STAGING_DIR)/create_tbd.sh
	$(HSWIDGETS_THEOS_TEMPLATE_STAGING_DIR)/create_tbd.sh
	cp -r $(FRAMEWORK_PATH) $(THEOS)/lib/$(FRAMEWORK_NAME).framework

clean-env:
	rm -r $(HSWIDGETS_THEOS_TEMPLATE_STAGING_DIR)/$(FRAMEWORK_NAME).framework $(THEOS)/lib/$(FRAMEWORK_NAME).framework

create-framework-zip:
	cd $(HSWIDGETS_THEOS_TEMPLATE_STAGING_DIR) && zip -r $(FRAMEWORK_PATH).zip $(FRAMEWORK_NAME).framework

clean-framework-zip:
	rm $(FRAMEWORK_PATH).zip

SUBPROJECTS += hsclockwidget
SUBPROJECTS += hsspacerwidget
SUBPROJECTS += hstodaywidget
include $(THEOS_MAKE_PATH)/aggregate.mk
