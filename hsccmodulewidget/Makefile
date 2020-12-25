ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = HSCCModuleWidget
HSCCModuleWidget_FILES = HSCCModuleWidgetViewController.x HSCCModuleController.x CCSupportCompatibility.x HSCCModulesListViewController.x HSCCNotifications.x
HSCCModuleWidget_FRAMEWORKS = UIKit
HSCCModuleWidget_EXTRA_FRAMEWORKS = CydiaSubstrate HSWidgets
HSCCModuleWidget_INSTALL_PATH = /Library/HSWidgets
HSCCModuleWidget_CFLAGS += -Iprivate_headers

include $(THEOS_MAKE_PATH)/bundle.mk
