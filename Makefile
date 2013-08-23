ARCHS = armv7
TARGET = iphone:clang::5.0
include theos/makefiles/common.mk

BUNDLE_NAME = GTrendsWidget
GTrendsWidget_FILES = TrendsData.m TrendsInfoView.m InfiniteScrollView.m GTrendsWidgetController.m Reachability.m
GTrendsWidget_INSTALL_PATH = /Library/WeeLoader/Plugins/
GTrendsWidget_FRAMEWORKS = UIKit CoreGraphics QuartzCore SystemConfiguration

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
