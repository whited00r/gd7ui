include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Interface
Interface_FILES = Interface.mm
Interface_INSTALL_PATH = /Library/PreferenceBundles
Interface_FRAMEWORKS = UIKit
Interface_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Interface.plist$(ECHO_END)
