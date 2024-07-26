//Something something to add here.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


@interface GDUIController : NSObject{

}
@property (nonatomic, assign) bool interfaceLoaded;
@property (nonatomic, assign) NSString *interfaceName;
+(GDUIController *)sharedInstance;
-(void)loadInterface;


-(BOOL)respondsToSelector:(SEL)aSelector;
-(id)forwardingTargetForSelector:(SEL)aSelector;
@end

@interface UIApplication (Private)
-(NSString*)displayIdentifier;
@end


@protocol GDUI
-(id)initWithController:(GDUIController*)controller;
-(void)loadUp;
-(float)gduiVersion; //In case there are updates to the GDUI tweak, I can provide legacy support for your plugin if I know the version.
-(BOOL)shouldThemeApp; //Return false if an app open shouldn't be themed. Otherwise, just return true for everything eh? Maybe, just maybe, I'll put in specific enable/disable options for elements to be themed later on.

-(UIColor*)fallbackTitleTintColor:(BOOL)enabled; //use this as a fallback global tint colour. Helpful for when new things can be themed but they aren't updated in a module yet.
-(UIColor*)fallBackButtonTintColor:(BOOL)enabled;
-(UIColor*)fallbackImageTintColor:(BOOL)enabled;
-(UIColor*)fallbackBackgroundTintColor;

@property (nonatomic, assign) GDUIController* controller; //Has some API you can use to perform actions or get information
@optional


//Navbar stuff
-(UIColor*)navBarTitleColor;
-(UIColor*)navBarBackgroundColor; //Shouldn't have to set this, beacuse the UI has a color anyway. I'll put it in there though just for... fun.
-(UIImage*)navBarBackgroundImage; //Shouldn't have to use this either, but if implemented this is used as the navigation bar background image.
-(UIColor*)navBarButtonItemTextColor:(BOOL)enabled;
-(UIColor*)navBarButtonItemShadowColor:(BOOL)enabled;


//BarButtonItems
-(UIImage*)barButtonItemBackgroundImage:(BOOL)enabled;
-(UIImage*)barButtonItemBackButtonBackgroundImage:(BOOL)enabled;
-(UIColor*)barButtonItemBackgroundColor:(BOOL)enabled; //Basically just a solid color all throughout for the image?
-(UIColor*)barButtonItemBackButtonBackgroundColor:(BOOL)enabled; 
-(UIColor*)barButtonItemTintColor:(BOOL)enabled; //Return the relevant tint color, also for if enabled or not. Used for text and images. 

//ToolbarButton
-(UIColor*)toolbarButtonTextColor:(BOOL)enabled;
-(UIColor*)toolbarButtonImageColor:(BOOL)enabled;


//Toolbar
-(UIColor*)toolbarTintColor;
-(UIColor*)toolBarBackgroundColor;


//NavigationButton
-(UIImage*)navButtonItemBackgroundImage:(BOOL)enabled;
-(UIImage*)navButtonItemBackButtonBackgroundImage;
-(UIColor*)navButtonItemBackgroundColor:(BOOL)enabled; //Basically just a solid color all throughout for the image?
-(UIColor*)navButtonItemBackButtonBackgroundColor; 
-(UIColor*)navButtonItemTintColor:(BOOL)enabled; //Return the relevant tint color, also for if enabled or not. Used for text and images. 
-(BOOL)hideBackgroundImage;


@end






