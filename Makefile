GO_EASY_ON_ME = 1
THEOS_DEVICE_IP = 192.168.1.218
include $(THEOS)/makefiles/common.mk
ARCHS= armv7

TWEAK_NAME = gd7ui
gd7ui_FILES = Tweak.xm UIImage+AverageColor.m UIImage+StackBlur.m UIImage+Resize.m UIImage+LiveBlur.m NSData+Base64.m DCRoundSwitch/DCRoundSwitch.m DCRoundSwitch/DCRoundSwitchKnobLayer.m DCRoundSwitch/DCRoundSwitchOutlineLayer.m DCRoundSwitch/DCRoundSwitchToggleLayer.m SevenSwitch.m
gd7ui_FRAMEWORKS = UIKit CoreGraphics Foundation QuartzCore Accelerate Security

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += interface
include $(THEOS_MAKE_PATH)/aggregate.mk
