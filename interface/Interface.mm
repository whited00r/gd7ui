#import <Preferences/Preferences.h>

@interface InterfaceListController: PSListController {
}
@end

@implementation InterfaceListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Interface" target:self] retain];
	}
	return _specifiers;
}
@end

// vim:ft=objc
