include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HSTodayWidget
HSTodayWidget_FILES = HSTodayWidgetViewController.xm
HSTodayWidget_FRAMEWORKS = UIKit CoreGraphics
HSTodayWidget_LIBRARIES = HSWidgets
HSTodayWidget_INSTALL_PATH = /Library/HSWidgets/HSTodayWidget

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
