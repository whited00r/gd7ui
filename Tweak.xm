#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
//#import <UI7Kit/UI7Kit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <SpringBoard/SpringBoard.h>
#import <Accelerate/Accelerate.h>
#import "UIImage+StackBlur.h"
#import "UIImage+LiveBlur.h"

#import "DCRoundSwitch/DCRoundSwitch.h"
#import "SevenSwitch.h"
#import "GDUI.h"
#import "UIImage+AverageColor.h"


#define KNORMAL  "\x1B[0m"
#define KRED  "\x1B[31m"
#define REDLog(fmt, ...) NSLog((@"%s" fmt @"%s"),KRED,##__VA_ARGS__,KNORMAL)


#define lsPrefsPath @"/var/mobile/Library/Preferences/com.grayd00r.liblockscreen.plist"
#define uiPrefsPath @"/var/mobile/Library/Preferences/com.greyd00r.gd7ui.plist"




@interface GDUI : NSObject{

}
@property (nonatomic, assign) GDUIController* controller;
-(id)initWithController:(GDUIController*)controller;
-(void)loadUp;
-(float)gduiVersion; //In case there are updates to the GDUI tweak, I can provide legacy support for your plugin if I know the version.
-(BOOL)shouldThemeApp; //Return false if an app open shouldn't be themed. Otherwise, just return true for everything eh? Maybe, just maybe, I'll put in specific enable/disable options for elements to be themed later on.

-(UIColor*)fallbackTitleTintColor:(BOOL)enabled; //use this as a fallback global tint colour. Helpful for when new things can be themed but they aren't updated in a module yet.
-(UIColor*)fallBackButtonTintColor:(BOOL)enabled;
-(UIColor*)fallbackImageTintColor:(BOOL)enabled;
-(UIColor*)fallbackBackgroundTintColor;


@end

static BOOL iOSLSEnabled = TRUE;
static BOOL blurDock = TRUE;
static BOOL debug = TRUE;
static BOOL iconAnimations = TRUE;
static BOOL replaceLinen = TRUE;

static BOOL themeAlerts = TRUE;
static BOOL themeNavigationBar = TRUE;

static BOOL resizeIcons = TRUE;
static int iconResizeType = 1;
static float iconScaleSize = 1.1;
static float iconResizeAddition = 0;
static BOOL allowIconDenyResize = FALSE;
static NSArray *iconDenyResizeList = nil;

static NSDictionary *themeOverrideDict = nil; //Loaded up if it exists... disables loading of hooks at runtime. (customizable?)



static BOOL dynamicInterfaceEnabled = FALSE;
static GDUI *interface = nil;
static Class GDUIClass;
static NSBundle *interfaceBundle;
static BOOL interfaceLoaded = false;

static GDUIController *gduiController;

static float gduiAPIVersion = 0.01;
static GDUIController *_instance;



NSString *UI7BarButtonItemIconNames[] = {
    @"Done",
    @"Cancel",
    @"Edit",
    @"Save",
    @"New",
    nil,
    nil,
    @"Compose",
    @"Reply",
    @"Action",
    @"Organize",
    @"Bookmarks",
    @"Search",
    @"Refresh",
    @"Stop",
    @"Camera",
    @"Trash",
    @"Play",
    @"Pause",
    @"Rewind",
    @"FastForward",
#if __IPHONE_3_0 <= __IPHONE_OS_VERSION_MAX_ALLOWED
    @"Undo",
    @"Redo",
#endif
#if __IPHONE_4_0 <= __IPHONE_OS_VERSION_MAX_ALLOWED
    @"PageCurl",
#endif
};



/*

@interface UIImage (Additions)

- (UIImage *)tintedImageUsingColor:(UIColor *)tintColor alpha:(float)alpha;
@end

@implementation UIImage (Additions)



- (UIImage *)tintedImageUsingColor:(UIColor *)tintColor alpha:(float)alpha;
{
    UIGraphicsBeginImageContextWithOptions (self.size, NO, [[UIScreen mainScreen] scale]);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);

    // draw original image
    [self drawInRect:rect blendMode:kCGBlendModeNormal alpha:alpha];

    // tint image (loosing alpha). 
    // kCGBlendModeOverlay is the closest I was able to match the 
    // actual process used by apple in navigation bar 
    CGContextSetBlendMode(context, kCGBlendModeColor);
    [tintColor setFill];
    CGContextFillRect(context, rect);

    // mask by alpha values of original image
    [self drawInRect:rect blendMode:kCGBlendModeDestinationIn alpha:1.0f];

    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tintedImage;
}


@end

*/

static BOOL shouldLoadHookGroup(NSString* hookGroup){
 NSLog(@"shouldLoadHookGroup?");
  if(!themeOverrideDict || !hookGroup){
   //NSLog(@"Stage 1");
    return TRUE;
  }

  if([themeOverrideDict objectForKey:@"global"]){
   //NSLog(@"Stage 2 a");
     if(![[themeOverrideDict objectForKey:@"global"] containsObject:hookGroup]){
        if([[NSBundle mainBundle] bundleIdentifier]){
          if([[themeOverrideDict objectForKey:[[NSBundle mainBundle] bundleIdentifier]] containsObject:hookGroup]){
            return FALSE;
          }
          else{
            return TRUE;
          }
        }
 
        return TRUE;
        
     }
     else{
      return FALSE;
     }
  }
        if([[NSBundle mainBundle] bundleIdentifier]){
          if([[themeOverrideDict objectForKey:[[NSBundle mainBundle] bundleIdentifier]] containsObject:hookGroup]){
            return FALSE;
          }
          else{
            return TRUE;
          }
        }
        else{
          NSLog(@"No display identifer!");
        }
       NSLog(@"RETURNING TRUE!");
  return TRUE;
}


@interface UIImage (Images)

- (UIImageView *)view;

+ (UIImage *)roundedImageWithSize:(CGSize)size color:(UIColor *)color radius:(CGFloat)radius;

@end


@implementation UIImage (Images)

- (UIImageView *)view {
    return [[[UIImageView alloc] initWithImage:self] autorelease];
}

+ (UIImage *)imageWithSize:(CGSize)size color:(UIColor *)color radius:(CGFloat)radius {
    CGRect rect = CGRectZero;
    rect.size = size;

    UIBezierPath* path = [UIBezierPath bezierPathWithRect:rect];

    return [UIImage imageWithBezierPath:path color:color backgroundColor:color];
}

@end


@interface UIColor (LightAndDark)


@end

@implementation UIColor (LightAndDark)

- (UIColor *)lighterColor
{
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s * 1.2
                          brightness:MIN(b * 1.6, 1.0)
                               alpha:a];
    return nil;
}

- (UIColor *)darkerColor
{
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s * 1.2
                          brightness:b * 0.50
                               alpha:a];
    return nil;
}
@end

//For the lockscreen notificaitons, to make them nice looking
@interface SBAwayListItemCell : UITableViewCell{

}
@property (nonatomic, retain) UIImageView *seperatorBlur;
@property (nonatomic, retain) UIView *brightenView;
@end



//For the lockscreen notificaitons, to make them nice looking
@interface SBAwayBulletinListView{

}
@property (nonatomic, retain) UIImageView *headerBlur;
@end
static SBApplicationIcon *lastLaunchedIcon = nil;
static UIImageView *homescreenSnapshotImageView;
static UIImageView *appPreviewImageView;
static UIImageView *wallpaperView;
UIImage *homescreenSnapshot = nil;
UIWindow *appAnimationWindow = nil;

static NSString *lastAnimatedApp = nil;
CGPoint screenCenter;
CGPoint lastIconCenter;
static float screenWidth;
static float screenHeight;

CGPoint CGRectCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

static UIAlertView *blurAlert;

 //This tints without blending the images together properly... Although I may have fixed it using voodoo.
@interface UIImage (Tint)

- (UIImage *)tintedImageUsingColor:(UIColor *)tintColor alpha:(float)alpha;
+ (UIImage *)imageWithColor:(UIColor *)color;
@end

@implementation UIImage (Tint)

- (UIImage *)tintedImageUsingColor:(UIColor *)tintColor alpha:(float)alpha {
  UIGraphicsBeginImageContext(self.size);
  CGRect drawRect = CGRectMake(0, 0, self.size.width, self.size.height);
  [self drawInRect:drawRect blendMode:kCGBlendModeNormal alpha:alpha];

  [tintColor set];
  UIRectFillUsingBlendMode(drawRect, kCGBlendModeColor);

  [self drawInRect:drawRect blendMode:kCGBlendModeDestinationIn alpha:1.0f];
  UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return tintedImage;
}

+ (UIImage *)imageWithColor:(UIColor *)color {
   CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
   UIGraphicsBeginImageContext(rect.size);
   CGContextRef context = UIGraphicsGetCurrentContext();

   CGContextSetFillColorWithColor(context, [color CGColor]);
   CGContextFillRect(context, rect);

   UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();

   return image;
}

@end


@interface UIColor (Shades)

-(BOOL)isLightColor;
@end


@implementation UIColor (Shades)

-(BOOL)isLightColor{

    const CGFloat *componentColors = CGColorGetComponents(self.CGColor);

    CGFloat colorBrightness = ((componentColors[0] * 299) + (componentColors[1] * 587) + (componentColors[2] * 114)) / 1000;
    if (colorBrightness < 0.6)
    {
        return FALSE;
    }
    else
    {
        return TRUE;
    }

}

@end

@interface UIBarButtonItem (SelectedHack)
@property(nonatomic) BOOL selected;
@end

#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
//#import <sys/sysctl.h>
#import "NSData+Base64.h"
static inline void alertIfNeeded(){
  //NSLog(@"Should show for update check");
  NSLog(@"SHOULDALERTIFNEEDED");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  BOOL shouldAlert = FALSE; //Only alert if both the lockscreen tweak *and* GD7UI are disabled. GD7UI should always be enabled because everything else depends on it so use that as the fallback alert tweak.
  if(![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/liblockscreen.dylib"]){
     NSLog(@"SHOULDALERT THIS BLOODY THING");
        shouldAlert = TRUE;
   
  }


  if(shouldAlert){
            UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle: @"Grayd00r Error"
                                       message: @"Your acitvation key for Grayd00r is invalid.\n\nIt also seems as though your re-activtion lockscreen is also invalid .\n\nNone of the features of Grayd00r will function until this is resolved.\nPlease re-install Grayd00r using the latest version of the installer from\nhttp://grayd00r.com."
                                      delegate: nil
                             cancelButtonTitle: @"OK"
                             otherButtonTitles: nil];
            [alert show];
            [alert release];
  }
  [pool drain];
}

static inline BOOL isSlothSleeping(){
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
NSData* fileData = [NSData dataWithContentsOfFile:@"/var/mobile/Library/Greyd00r/ActivationKeys/com.greyd00r.installerInfo.plist"];
NSData* signatureData = [NSData dataWithContentsOfFile:@"/var/mobile/Library/Greyd00r/ActivationKeys/com.greyd00r.installerInfo.plist.sig"];
//Okay, this is technically not good to do, but it's even worse if I just include the bloody certificate on the device by default because then it just gets replaced easier. Same for keeping it in the keychain perhaps because it isn't sandboxed? Hide it in the binary they said, it will be safer, they said.
NSData* certificateData = [NSData dataFromBase64String:[NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@",@"MIIC6jCCAdICCQC2Zs0BWO+dxzANBgkqhkiG9w0BAQsFADA3MQswCQYDVQQGEwJV",
@"UzERMA8GA1UECgwIR3JheWQwMHIxFTATBgNVBAMMDGdyYXlkMDByLmNvbTAeFw0x",
@"NTEwMjQyMzEzNTNaFw0yMTA0MTUyMzEzNTNaMDcxCzAJBgNVBAYTAlVTMREwDwYD",
@"VQQKDAhHcmF5ZDAwcjEVMBMGA1UEAwwMZ3JheWQwMHIuY29tMIIBIjANBgkqhkiG",
@"9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsWSkvU26FQlb/IOE/QWKSyt3L5ekj+uvdVQq",
@"Eljo35THov9qKSqTMhdgMGkWDCVnqHsgf0+LjHZcFfz+cI1++1bsHCxvhJvytvYx",
@"uRQmjh0+yAA28729dDCKhawQ5YLHbVC+4tHoyHhvK+Ww0mx+g7Y8bVh+qc1EBf6h",
@"VOrspUvoGHLQYAa15Wbca8mmXVpxuZVfviLskqffKtsPVe7EIx8WwzrI+v9GOXNi",
@"dR/rBJDU91u1AQc5BT9zAOFlLZq4VJLdNNWCs4w58f6260xDiUjMEAKzILhSjmN/",
@"Dys9McYE9Iu3lGPvFn2HCfOOgTg1sv3Hz/mogL5sbjvCCtQnrwIDAQABMA0GCSqG",
@"SIb3DQEBCwUAA4IBAQBLQ+66GOyKY4Bxn9ODiVf+263iLTyThhppHMRguIukRieK",
@"sVvngMd6BQU4N4b0T+RdkZGScpAe3fdre/Ty9KIt/9E0Xqak+Cv+x7xCzEbee8W+",
@"sAV+DViZVes67XXV65zNdl5Nf7rqGqPSBLwuwB/M2mwmDREMJC90VRJBFj4QK14k",
@"FuwtTpNW44NUSQRUIxiZM/iSwy9rqekRRAKWo1s5BOLM3o7ph002BDyFPYmK5UAN",
@"EM/aKFGVMMwhAUHjgej5iEPxPuks+lGY1cKUAgoxbvXJakybosgmDFfSN+DMT7ZU",
@"HbUgWDsLySwU8/+C4vDP0pmMqJFgrna9Wto49JNz"]];//[NSData dataWithContentsOfFile:@"/var/mobile/Library/Greyd00r/ActivationKeys/certificate.cer"];  

//SecCertificateRef certRef = SecCertificateFromPath(@"/var/mobile/Library/Greyd00r/ActivationKeys/certificate.cer");
//SecCertificateRef certificateFromFile = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certRef);



//SecKeyRef publicKey = SecKeyFromCertificate(certRef);

//recoverFromTrustFailure(publicKey);

if(fileData && signatureData && certificateData){


SecCertificateRef certificateFromFile = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData); // load the certificate

SecPolicyRef secPolicy = SecPolicyCreateBasicX509();

SecTrustRef trust;
OSStatus statusTrust = SecTrustCreateWithCertificates( certificateFromFile, secPolicy, &trust);
SecTrustResultType resultType;
OSStatus statusTrustEval =  SecTrustEvaluate(trust, &resultType);
SecKeyRef publicKey = SecTrustCopyPublicKey(trust);


//ONLY iOS6+ supports SHA256! >:(
uint8_t sha1HashDigest[CC_SHA1_DIGEST_LENGTH];
CC_SHA1([fileData bytes], [fileData length], (unsigned char*)sha1HashDigest);

OSStatus verficationResult = SecKeyRawVerify(publicKey,  kSecPaddingPKCS1SHA1,  (const uint8_t *)sha1HashDigest, (size_t)CC_SHA1_DIGEST_LENGTH,  (const uint8_t *)[signatureData bytes], (size_t)[signatureData length]);
CFRelease(publicKey);
CFRelease(trust);
CFRelease(secPolicy);
CFRelease(certificateFromFile);
[pool drain];
if (verficationResult == errSecSuccess){
  return TRUE;
}
else{
  return FALSE;
}



}
[pool drain];
return false;
}

//static OSStatus SecKeyRawVerify;
static inline BOOL isSlothAlive(){

if(!isSlothSleeping()){ //Don't want to pass this off as valid if the user didn't actually install via the grayd00r installer from the website.
  //alertIfNeeded();
  return FALSE;
}

NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

//Go from NSString to NSData
NSData *udidData = [[NSString stringWithFormat:@"%@-%@-%c%c%c%@-%@%c%c%@%@%c",[[UIDevice currentDevice] uniqueIdentifier],@"I",'l','i','k',@"e",@"s",'l','o',@"t",@"h",'s'] dataUsingEncoding:NSUTF8StringEncoding];
uint8_t digest[CC_SHA1_DIGEST_LENGTH];
CC_SHA1(udidData.bytes, udidData.length, digest);
NSMutableString *hashedUDID = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
//To NSMutableString to calculate hash

    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [hashedUDID appendFormat:@"%02x", digest[i]];
    }

//Then back to NSData for use in verification. -__-. I probably could skip a couple steps here...
NSData *hashedUDIDData = [hashedUDID dataUsingEncoding:NSUTF8StringEncoding];
NSData* signatureData = [NSData dataWithContentsOfFile:@"/var/mobile/Library/Greyd00r/ActivationKeys/com.greyd00r.activationKey"];

//Okay, this is technically not good to do, but it's even worse if I just include the bloody certificate on the device by default because then it just gets replaced easier. Same for keeping it in the keychain perhaps because it isn't sandboxed? Hide it in the binary they said, it will be safer, they said.
NSData* certificateData = [NSData dataFromBase64String:[NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@",@"MIIDJzCCAg+gAwIBAgIJAPyR9ASSBbF9MA0GCSqGSIb3DQEBCwUAMCoxETAPBgNV",
@"BAoMCEdyYXlkMDByMRUwEwYDVQQDDAxncmF5ZDAwci5jb20wHhcNMTUxMDI4MDEy",
@"MjQyWhcNMjUxMDI1MDEyMjQyWjAqMREwDwYDVQQKDAhHcmF5ZDAwcjEVMBMGA1UE",
@"AwwMZ3JheWQwMHIuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA",
@"94OZ2u2gJfdWgqWKV7yDY5pJXLZuRho6RO2OJtK04Xg3gUk46GBkYLo+/Z33rOvs",
@"XA041oAINRmdaiTDRa5VbGitQMYfObMz8m0lHQeb4/wwOasRMgAT2WCcKVulwpCG",
@"C7PiotF3F85VAuqJsbu1gxjJaQGIgR2L35LTR/fQq3N5+2+bsc0wUbPcLk7uhyYJ",
@"tna+CYRc+3qGRsv/t8MYF0T7LU2xwCcGV0phmr3er5ocAj9X57i92zYGMPlz8kMZ",
@"HfXqMova0prF9vuN7mo54kY+SF2rp/G/v+u5MicONpXwY6adJ0eIuXFjqsUjKTi6",
@"4Bjzhvf+Z6O5TARJzdVMqwIDAQABo1AwTjAdBgNVHQ4EFgQUDBxB98iHJnBsonVM",
@"LHF5WVXvhqgwHwYDVR0jBBgwFoAUDBxB98iHJnBsonVMLHF5WVXvhqgwDAYDVR0T",
@"BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEA4tyP/hMMJBYVFhRmdjAj9wnCr31N",
@"7tmyksLR76gqfLJL3obPDW+PIFPjdhBWNjcjNuw/qmWUXcEkqu5q9w9uMs5Nw0Z/",
@"prTbIIW861cZVck5dBlTkzQXySqgPwirXUKP/l/KrUYYV++tzLJb/ete2HHYwAyA",
@"2kl72gIxdqcXsChdO5sVB+Fsy5vZ2pw9Qan6TGkSIDuizTLIvbFuWw53MCBibdDn",
@"Y+CY2JrcX0/YYs4BSk5P6w/VInU5pn6afYew4XO7jRrGyIIPRJyR3faULqOLkenG",
@"Z+VNoXdO4+FShkEEfHb+Y8ie7E+bB0GBPb9toH/iH4cVS8ddaV3KiLkkJg=="]];//[NSData dataWithContentsOfFile:@"/var/mobile/Library/Greyd00r/ActivationKeys/certificate.cer"];  

//SecCertificateRef certRef = SecCertificateFromPath(@"/var/mobile/Library/Greyd00r/ActivationKeys/certificate.cer");
//SecCertificateRef certificateFromFile = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certRef);



//SecKeyRef publicKey = SecKeyFromCertificate(certRef);

//recoverFromTrustFailure(publicKey);

if(hashedUDIDData && signatureData && certificateData){


SecCertificateRef certificateFromFile = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData); // load the certificate

SecPolicyRef secPolicy = SecPolicyCreateBasicX509();

SecTrustRef trust;
OSStatus statusTrust = SecTrustCreateWithCertificates( certificateFromFile, secPolicy, &trust);
SecTrustResultType resultType;
OSStatus statusTrustEval =  SecTrustEvaluate(trust, &resultType);
SecKeyRef publicKey = SecTrustCopyPublicKey(trust);


//ONLY iOS6+ supports SHA256! >:(
uint8_t sha1HashDigest[CC_SHA1_DIGEST_LENGTH];
CC_SHA1([hashedUDIDData bytes], [hashedUDIDData length], (unsigned char*)sha1HashDigest);

OSStatus verficationResult = SecKeyRawVerify(publicKey,  kSecPaddingPKCS1SHA1, (const uint8_t*)sha1HashDigest, (size_t)CC_SHA1_DIGEST_LENGTH,  (const uint8_t *)[signatureData bytes], (size_t)[signatureData length]);
CFRelease(publicKey);
CFRelease(trust);
CFRelease(secPolicy);
CFRelease(certificateFromFile);
[pool drain];

if (verficationResult == errSecSuccess){

  return TRUE;
}
else{
  //alertIfNeeded();
  return FALSE;
}



}
[pool drain];
//alertIfNeeded();
return false;
}





@implementation GDUIController

+(GDUIController*)sharedInstance{
  if(!_instance){
    return [[GDUIController alloc] init];
  }
  return _instance;
}

-(id)init{
    if (_instance == nil)
    {

        _instance = [super init];

        //shouldUpdateBackground = TRUE;
        self.interfaceLoaded = FALSE;
        self.interfaceName = @"StockInterface.bundle";
  NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.greyd00r.gd7ui.plist"];
  if(settings){
    REDLog(@"GD7UIDEBUG: loadPrefs - called");
   
    self.interfaceName = [settings objectForKey:@"interfaceName"] ? [[settings objectForKey:@"interfaceName"] copy] : @"StockInterface.bundle";
  }
  [settings release];
   REDLog(@"GD7UIDEBUG: loadPrefs - finished");
       
    }
    return _instance;
}


-(void)loadInterface{
    REDLog(@"GD7UIDEBUG: Attempting to load up interface for bundle %@", self.interfaceName);
  
  interface = nil;

    interfaceBundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/Library/GDUI/Interfaces/%@", self.interfaceName]];
    NSError *err;
    if(![interfaceBundle loadAndReturnError:&err]) {
      REDLog(@"GD7UIDEBUG: %@ seems not to load up properly", self.interfaceName);
      /*
          UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle: @"Panel Error"
                                       message: [NSString stringWithFormat:@"%@ seems not to load up properly", self.interfaceName]
                                      delegate: nil
                             cancelButtonTitle: @"OK"
                             otherButtonTitles: nil];
            [alert show];
            [alert release];
            */
            interfaceLoaded = false;
    } else {
        // bundle loaded
        GDUIClass = [interfaceBundle principalClass]; 
        if([GDUIClass conformsToProtocol:@protocol(GDUI)]){ //Checking that the lockscreen is actually properly implimenting the protocol of a lockscreen. Otherwise crashes will occur.
          REDLog(@"GD7UIDEBUG: %@ loaded up and seems to conform to the protocol", self.interfaceName);
        interface = [[GDUIClass alloc] initWithController:self];
        if([interface gduiVersion] < gduiAPIVersion){
          REDLog(@"GD7UIDEBUG: %@ is using an outdated GDUI API", self.interfaceName);
          /*
          UIAlertView *alert =
          [[UIAlertView alloc] initWithTitle: @"Interface Error"
                                       message: [NSString stringWithFormat:@"%@ is using an outdated GDUI API.", self.interfaceName]
                                      delegate: nil
                             cancelButtonTitle: @"OK"
                             otherButtonTitles: nil];
          [alert show];
          [alert release];
          */
          interfaceLoaded = FALSE;
          [interfaceBundle unload];
          [interfaceBundle release], interfaceBundle = nil;
        }else{
 
        interface.controller = self;
        [interface loadUp];
    
       
        interfaceLoaded = TRUE;
      }
      }
      else{
       REDLog(@"GD7UIDEBUG: %@ seems not to correctly impliment the Panel class.", self.interfaceName);
       /*
        UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle: @"Interface Error"
                                       message: [NSString stringWithFormat:@"%@ seems not to correctly impliment the GDUI class.", self.interfaceName]
                                      delegate: nil
                             cancelButtonTitle: @"OK"
                             otherButtonTitles: nil];
            [alert show];
            [alert release];
            */
        interfaceLoaded = FALSE;
        [interfaceBundle unload];
        [interfaceBundle release], interfaceBundle = nil;
      }
      }

}

-(BOOL)respondsToSelector:(SEL)aSelector {
  if(interfaceLoaded && !(interface == nil)){
    return TRUE;
  }
    return [super respondsToSelector:aSelector];
}


-(id)forwardingTargetForSelector:(SEL)aSelector {
  if(interfaceLoaded && !(interface == nil)){
    return interface;
  }
    if ([interface respondsToSelector:aSelector]) {
        return interface;
    }
    else{
      NSString *selectorString = NSStringFromSelector(aSelector);
      if([selectorString rangeOfString:@"title" options:NSCaseInsensitiveSearch].location != NSNotFound){
        if ([interface respondsToSelector:aSelector]) {
          return interface;
        }
      }
    }
    return [super forwardingTargetForSelector:aSelector];
}

@end


//So we can blur the wallpaper whenever it updates.

%group hookGroup
%hook SBWallpaperView 
-(void)_wallpaperChanged{

    blurAlert =
        [[UIAlertView alloc] initWithTitle:nil
                             message: @"Applying Wallpaper and creating blurs. This may take a moment."
                             delegate: self
                             cancelButtonTitle:nil
                             otherButtonTitles: nil];
    [blurAlert show];

	%orig;

	if(debug) NSLog(@"GD7UIDEBUG: Wallpaper changed called.");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];


    dispatch_queue_t queue = dispatch_queue_create("Blur queue", NULL); 
    dispatch_async(queue, ^ {
     [self generatedBlurredWallpapers];
      dispatch_async(dispatch_get_main_queue(), ^{
           [blurAlert dismiss];
    [blurAlert release];
        if(blurDock){
      [[[%c(SBIconController) sharedInstance] dock] updateDockBackground];
      [[%c(SBIconController) sharedInstance] updateWallpaperLightness];
    }
        });
        });
         dispatch_release(queue);


 

    [pool drain];
}

%new
-(UIImage *)lockBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap"]){
	return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
else{
	return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new
-(UIImage *)homeBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap"]){
	return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
else{
	return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new
-(void)generatedBlurredWallpapers{
    UIImage *homeWallpaper = [self homeBackgroundImage];
     UIImage *blurredHome = nil;
    if(!homeWallpaper == NULL){
      if([[homeWallpaper mergedColor] isLightColor]){
        blurredHome = [[homeWallpaper fastBlurWithQuality:4 interpolation:4 blurRadius:15] retain];
      }
      else{
        blurredHome = [[[homeWallpaper tintedImageUsingColor:[[homeWallpaper mergedColor] lighterColor] alpha:0.8] fastBlurWithQuality:4 interpolation:4 blurRadius:15] retain];
      }
       //UIImage *homeBlurStep1 = [[homeWallpaper tintedImageUsingColor:[homeWallpaper averageColor] alpha:0.9f] stackBlur:20];
       //UIImage *blurredHome = [[homeWallpaper fastBlurWithQuality:4 interpolation:4 blurRadius:15] retain];//[[[homeBlurStep1 tintedImageUsingColor:[homeBlurStep1 averageColor] alpha:0.9f] stackBlur:90] retain];
        //UIImage *homeBlurStep1 = [[homeWallpaper tintedImageUsingColor:[homeWallpaper averageColor]] stackBlur:20];
        //UIImage *blurredHome = [[[homeBlurStep1 tintedImageUsingColor:[homeBlurStep1 averageColor]] stackBlur:90] retain];
        [UIImagePNGRepresentation(blurredHome) writeToFile:@"/var/mobile/Library/SpringBoard/HomeBackgroundBlurred.png" atomically:YES];
        [blurredHome release];
    }
    UIImage *lockWallpaper = [self lockBackgroundImage];
    UIImage *blurredLock = nil;
    if(!lockWallpaper == NULL){
      if([[lockWallpaper mergedColor] isLightColor]){
        blurredLock = [[lockWallpaper fastBlurWithQuality:4 interpolation:4 blurRadius:15] retain];
      }
      else{
        blurredLock = [[[lockWallpaper tintedImageUsingColor:[[lockWallpaper mergedColor] lighterColor] alpha:0.8] fastBlurWithQuality:4 interpolation:4 blurRadius:15] retain];
      }
       //UIImage *lockBlurStep1 = [[lockWallpaper tintedImageUsingColor:[lockWallpaper averageColor] alpha:0.9f] stackBlur:20];
       //UIImage *blurredLock = [[lockWallpaper fastBlurWithQuality:4 interpolation:4 blurRadius:15] retain];//[[[lockBlurStep1 tintedImageUsingColor:[lockBlurStep1 averageColor] alpha:0.9f] stackBlur:90] retain];
       // UIImage *lockBlurStep1 = [[lockWallpaper tintedImageUsingColor:[lockWallpaper averageColor]] stackBlur:20];
       // UIImage *blurredLock = [[[lockBlurStep1 tintedImageUsingColor:[lockBlurStep1 averageColor]] stackBlur:90] retain];

        [UIImagePNGRepresentation(blurredLock) writeToFile:@"/var/mobile/Library/SpringBoard/LockBackgroundBlurred.png" atomically:YES];
        [blurredLock release];
    }
}




%end

@interface SBIconController (WallpaperLightness)


@property (nonatomic, assign) BOOL isLightWallpaper;
@end

//So the icons can reference this to see if the wallpaper is dark or light, and so it only gets set once. Memory efficient? I don't really know.
%hook SBIconController


-(id)init{
  self = %orig;
  if(self){
    [self updateWallpaperLightnessFirstStart];
  }
  return self;
}

%new
-(void)updateWallpaperLightnessFirstStart{
    [self setIsLightWallpaper:[[[self homeBackgroundImage] mergedColor] isLightColor]];
}


%new
-(void)updateWallpaperLightness{

  [self setIsLightWallpaper:[[[self homeBackgroundImage] mergedColor] isLightColor]];
  [[self valueForKey:@"iconModel"] loadAllIcons]; //Force a refresh of the icons. Doesn't work for some icons it seems...
  if([[self valueForKey:@"iconModel"] respondsToSelector:@selector(relayout)]) [[self valueForKey:@"iconModel"] relayout];


}

%new
-(UIImage *)lockBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap"]){
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
else{
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new
-(UIImage *)homeBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap"]){
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
else{
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new
- (BOOL)isLightWallpaper {
  NSNumber *number = objc_getAssociatedObject(self, @selector(isLightWallpaper));
  if([number respondsToSelector:@selector(boolValue)]){

    return [number boolValue];
  }
  else{
    return false;
  }
}
 
%new
- (void)setIsLightWallpaper:(BOOL)value {
  objc_setAssociatedObject(self, @selector(isLightWallpaper), [NSNumber numberWithBool:value], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end


//Make the homescreen icons slightly larger
%hook SBIconView

-(void)layoutSubviews{
   %orig;
    [[self valueForKey:@"reflection"] setHidden:TRUE];
    [[self valueForKey:@"shadow"] setHidden:TRUE];
    if(!resizeIcons){
      
      return;
    }

    if(!(iconDenyResizeList == nil) && allowIconDenyResize){
      //NSLog(@"Checking if things should be denied... %@" ,[[self valueForKey:@"icon"] applicationBundleID]);
      if([iconDenyResizeList containsObject:[[self valueForKey:@"icon"] applicationBundleID]]){
        
        return;
      }
    }


    UIImageView *icon = [self valueForKey:@"iconImageView"];
   
    UIImageView *ghostlyIcon = [self valueForKey:@"ghostlyImageView"];
    UIImageView *darkeningOverlay = [self valueForKey:@"iconDarkeningOverlay"];
    UIImageView *dropGlow = [self valueForKey:@"dropGlow"];
        
    if(iconResizeType == 1){
      icon.transform = CGAffineTransformMakeScale(iconScaleSize, iconScaleSize);

      ghostlyIcon.transform = CGAffineTransformMakeScale(iconScaleSize, iconScaleSize);
      darkeningOverlay.transform = CGAffineTransformMakeScale(iconScaleSize, iconScaleSize);
      dropGlow.transform = CGAffineTransformMakeScale(iconScaleSize, iconScaleSize);

      //And now re-render it of sorts, so it doesn't look *as* blurry?
      icon.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

      //[icon setContentMode:UIViewContentModeScaleAspectFill];

    
    }

    if(iconResizeType == 2){
     // NSLog(@"Resizing icon %@ to +%f", [[self valueForKey:@"icon"] applicationBundleID], iconResizeAddition);
      CGRect iFrame = icon.frame;
      [icon setFrame:CGRectMake(iFrame.origin.x - (iconResizeAddition / 2), iFrame.origin.y - (iconResizeAddition / 2), iFrame.size.width + iconResizeAddition, iFrame.size.height + iconResizeAddition)];
      icon.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
      [icon setContentMode:UIViewContentModeScaleAspectFill];
      ghostlyIcon.frame = icon.frame;
      darkeningOverlay.frame = icon.frame;
      dropGlow.frame = icon.frame;

    }

   

}


%end

%hook SBIconLabel

-(UIColor*)_textShadowColor{
  return [UIColor clearColor];
}

-(UIColor*)_textColor{
  if([[%c(SBIconController) sharedInstance] isLightWallpaper]){
    return [UIColor blackColor];
  }
  else{
    return %orig;
  }
}
%end


%hook SBCalendarApplicationIcon
-(id)generateIconImage:(int)image{
  return %orig;
}

%end



/*

TO-DO/FIXME:
Make this play nicely with the album art backgrounds. May be more difficult because they are different sizes and don't scale as well/properly to the default wallpaper shape?

Load up custom code from NSBundles, check what things it implements, and then call off the relevant method/object/class for it so it initializes everything it needs to for that element. 

*/


%hook SBAwayListItemCell

-(void)_createContentView{
    %orig;
    if(iOSLSEnabled){
        [self setBackgroundColor:[UIColor clearColor]];


    }  
}

-(id)initWithReuseIdentifier:(id)reuseIdentifier{
    self = %orig;
    NSLog(@"Replaced method!");
  if(self){
      if(iOSLSEnabled){


      if(!self.brightenView){

        self.brightenView = [[UIView alloc] initWithFrame:CGRectMake(10,self.frame.size.height -0.5, self.frame.size.width - 10, 0.5)];
        //brightenView.alpha = 0.1;
        self.brightenView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        [self addSubview:self.brightenView];
      }
      

      if(!self.seperatorBlur){
        self.seperatorBlur = [[UIImageView alloc] initWithFrame:CGRectMake(10,self.frame.size.height -0.5, self.frame.size.width - 10, 0.5)];
     
        self.seperatorBlur.image = [self blurredBackgroundImage];//[[self blurredBackgroundImage] tintedImageUsingColor:[UIColor colorWithRed:200.0f green:200.0f blue:200.0f alpha:0.6f] alpha:0.9];
      
      NSLog(@"Blurred background image is :%@", [self blurredBackgroundImage]);
      self.seperatorBlur.contentMode = UIViewContentModeTopLeft; 
      self.seperatorBlur.clipsToBounds = YES;
      self.seperatorBlur.layer.contentsRect = CGRectMake(0.0, 0.0, 1, 1);
      self.seperatorBlur.alpha = 0.9;

      [self addSubview:self.seperatorBlur];
    }

      

      
    }
  }
    return self;
}

-(void)layoutSubviews{
  %orig;

  if(iOSLSEnabled){
    self.seperatorBlur.frame = CGRectMake(10,self.frame.size.height -0.5, self.frame.size.width - 10, 0.5);
    self.brightenView.frame = CGRectMake(10,self.frame.size.height -0.5, self.frame.size.width - 10, 0.5);
  }
}

-(void)dealloc{
  if(iOSLSEnabled){
    [self.seperatorBlur release];
    [self.brightenView release];
  }
  %orig;
}

%new
- (id)seperatorBlur {
  return objc_getAssociatedObject(self, @selector(seperatorBlur));
}
 
%new
- (void)setSeperatorBlur:(id)value {
  objc_setAssociatedObject(self, @selector(seperatorBlur), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


%new
- (id)brightenView {
  return objc_getAssociatedObject(self, @selector(brightenView));
}
 
%new
- (void)setBrightenView:(id)value {
  objc_setAssociatedObject(self, @selector(brightenView), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(BOOL)_hasBackgroundColor{
    if(iOSLSEnabled){
        return FALSE;
    }
    return %orig;
}


+(float)_cellContentExtraPadding{
    if(iOSLSEnabled){
        return 15.0;
    }
    return %orig; 
}


-(BOOL)_drawsSeparator{
  if(iOSLSEnabled){
    return FALSE;
  }
  return %orig;
}


%new
-(UIImage *)lockBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap"]){
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
else{
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new
-(UIImage *)homeBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap"]){
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
else{
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new(@:@)
-(UIImage *)blurredBackgroundImage{
  if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/LockBackgroundBlurred.png"]){
    return [UIImage imageWithContentsOfFile:@"/var/mobile/Library/SpringBoard/LockBackgroundBlurred.png"];
  }
return [[self lockBackgroundImage] fastBlurWithQuality:4 interpolation:4 blurRadius:15]; //Fallback code I guess, to make it live if needed?
}


%end


//MSHookInterface(SBAwayListItemCell, SBAwayListItemCellMod, UITableViewCell);


%hook SBAwayBulletinListController
%new
- (void)scrollViewDidScroll:(UIScrollView *)scrollView_ {
   // NSLog(@"TableView scrolled!");
   
   //Nasty nasty nasty hack to get the blurred background to sort of "show through" as the divider between cells.
    if(iOSLSEnabled){
      [self updateTableCellsSeperator];
    }

    /*
    NSInteger nSections = [tableView numberOfSections];
for (int j=0; j<nSections; j++) {
  NSInteger nRows = [tableView numberOfRowsInSection:j];
  for (int i=0; i<nRows; i++) {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:j];
    //Do something with your indexPath. Maybe you want to get your cell,
    // like this:
    //UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    SBAwayListItemCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    CGRect rect = [tableView convertRect:[tableView rectForRowAtIndexPath:indexPath] toView:[tableView superview]];
    cell.seperatorBlur.layer.contentsRect = CGRectMake(0.0, (rect.origin.y + (cell.contentView.frame.size.height - 6.5))/ [tableView superview].frame.size.height, 1, 1);
    
     NSLog(@"Y is: %f", rect.origin.y / [tableView superview].frame.size.height);
  }
}
*/
}


-(void)_updateModelAndTableViewForAddition:(id)addition{
  %orig;
  if(iOSLSEnabled){
    [self updateTableCellsSeperator];
  }
}

-(void)_updateModelAndTableViewForModification:(id)modification originalHeight:(float)height{
  %orig;
  if(iOSLSEnabled){
    [self updateTableCellsSeperator];
  }
}

-(void)_updateModelAndTableViewForRemoval:(id)removal originalHeight:(float)height{
  %orig;
  if(iOSLSEnabled){
    [self updateTableCellsSeperator];
  }
}


%new
-(void)updateTableCellsSeperator{ //Is this slower in it's own method, or is it quicker when built into the original method that calls it of on scroll, or is it just the same speed either way. Didn't make sense to just copy/paste all the same code loop over and over again though when it would just be used right there anyway.
    UITableView *tableView = [[self valueForKey:@"view"] valueForKey:@"tableView"];
    /*
    for(SBAwayListItemCell *cell in [tableView visibleCells]){
      //NSLog(@"Cell is :%@");
    }
  */
  for (NSIndexPath *indexPath in [tableView indexPathsForVisibleRows]) {
    //Do something with your indexPath. Maybe you want to get your cell,
    // like this:
    //UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    SBAwayListItemCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    CGRect rect = [tableView convertRect:[tableView rectForRowAtIndexPath:indexPath] toView:[tableView superview]];
    cell.seperatorBlur.layer.contentsRect = CGRectMake(0.0, (rect.origin.y + (cell.contentView.frame.size.height - 6.5))/ [tableView superview].frame.size.height, 1, 1);
    
     //NSLog(@"Y is: %f", rect.origin.y / [tableView superview].frame.size.height);
  }
}
%end





%hook SBAwayBulletinListView
-(id)initWithFrame:(CGRect)frame{
  self = %orig;
  if(self){
    if(iOSLSEnabled){
      [[self valueForKey:@"tableView"] setShowsVerticalScrollIndicator:FALSE];
    }
  }
  return self;
}

-(id)_tableHeaderView{
  if(iOSLSEnabled){
    UIImageView *view = %orig;
    [view setBackgroundColor:[UIColor clearColor]];

     
    return view;
  }
  return %orig;
}

-(id)_tableFooterView{
  if(iOSLSEnabled){
    UIView *view = %orig;

    [(UIImageView*)view setBackgroundColor:[UIColor clearColor]];

    return view;
  }
  return %orig;
}


%new
-(UIImage *)lockBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap"]){
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
else{
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new
-(UIImage *)homeBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap"]){
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
else{
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new(@:@)
-(UIImage *)blurredBackgroundImage{
  if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/LockBackgroundBlurred.png"]){
    return [UIImage imageWithContentsOfFile:@"/var/mobile/Library/SpringBoard/LockBackgroundBlurred.png"];
  }
return [[self lockBackgroundImage] fastBlurWithQuality:4 interpolation:4 blurRadius:15]; //Fallback code I guess, to make it live if needed?
}

%end

@interface SBIconViewMap

@end



%hook SBApplicationIcon

-(void)launch{

  if(iconAnimations && ![self isFolderIcon] && ![self isNewsstandIcon]){
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if(!appAnimationWindow){
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    screenWidth = screenFrame.size.width;
    screenHeight = screenFrame.size.height;
    screenCenter = CGRectCenter(screenFrame);
    appAnimationWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)]; //[[SlideyWindow alloc] initWithFrame:CGRectMake(screenWidth - visibleEdge,(screenHeight /2) - ((screenHeight / 3) / 2 ), screenWidth, screenHeight / 3)];
    appAnimationWindow.backgroundColor = [UIColor blueColor];


    wallpaperView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    wallpaperView.hidden = TRUE;
    [appAnimationWindow addSubview:wallpaperView];

    homescreenSnapshotImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    homescreenSnapshotImageView.hidden = TRUE;
    [appAnimationWindow addSubview:homescreenSnapshotImageView];

    appPreviewImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    appPreviewImageView.hidden = TRUE;
    [appAnimationWindow addSubview:appPreviewImageView];
  }
   appAnimationWindow.windowLevel = 100001.0f;
    appAnimationWindow.userInteractionEnabled = TRUE;
    appAnimationWindow.hidden = TRUE;  


    wallpaperView.image = [[[%c(SBUIController) sharedInstance] wallpaperView] image];
 // SBIconController *controller = [%c(SBIconController) sharedInstance];
    SBIconViewMap *iconMap = [%c(SBIconViewMap) homescreenMap];
    SBIconView *iconView = [iconMap iconViewForIcon:self];
    SBIconController *iconController = [%c(SBIconController) sharedInstance];


    SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:[self applicationBundleID]];
    NSString *snapshotName = @"UIApplicationAutomaticSnapshotDefault";
    if([app _currentDefaultPNGName]){
      snapshotName = [app _currentDefaultPNGName];
    }
    UIImage *snapshotImage = [UIImage imageWithContentsOfFile:[app defaultImagePathForCurrentOrientationWithName:snapshotName]];
    appPreviewImageView.image = snapshotImage;

    NSLog(@"GD7UIDEBUG: SBApplicationIcon - launch - snapshotImage is: %@", [app defaultImagePathForCurrentOrientationWithName:snapshotName]);
    homescreenSnapshot = [UIImage snapshotView:[iconController contentView]];
    homescreenSnapshotImageView.image = homescreenSnapshot;

    appAnimationWindow.hidden = FALSE;
    homescreenSnapshotImageView.hidden = FALSE;
    wallpaperView.hidden = FALSE;

    lastLaunchedIcon = self;


    CGRect frame; 
    if(![iconView isInDock]){
      frame = [[iconController contentView] convertRect:[iconView frame] toView:[iconController contentView]];
    }
    else{
      frame = [[iconController dock] convertRect:[iconView frame] toView:[iconController contentView]];
    }



//appPreviewImageView.transform=CGAffineTransformMakeScale(0.0, 0.0);
appPreviewImageView.alpha = 0.0;
appPreviewImageView.hidden = FALSE;
homescreenSnapshotImageView.transform=CGAffineTransformMakeScale(1.0, 1.0);
wallpaperView.transform=CGAffineTransformMakeScale(1.0, 1.0);
homescreenSnapshotImageView.center = CGPointMake(homescreenSnapshotImageView.frame.size.width /2, homescreenSnapshotImageView.frame.size.height /2);
//appPreviewImageView.center = CGPointMake(screenWidth /2, screenHeight /2);
appPreviewImageView.frame = CGRectMake(0,0,0,0);
appPreviewImageView.center = CGRectCenter(frame);
lastIconCenter = CGRectCenter(frame);
CGFloat s = 4;
CGPoint p = CGRectCenter(frame);
CGAffineTransform tr = CGAffineTransformScale(homescreenSnapshotImageView.transform, s, s);
//CGAffineTransform tr2 = CGAffineTransformScale(appPreviewImageView.transform, 1.0, 1.0);
CGFloat h = homescreenSnapshotImageView.frame.size.height;
CGFloat w = homescreenSnapshotImageView.frame.size.width;

[[iconController contentView] setHidden:TRUE];

//Animate the opacity quicker than everything else so it doesn't look too funny when opening, but also doesn't look funny by not animating it out from the icon at first
       [UIView animateWithDuration:0.15
                delay:0.0
                options:UIViewAnimationCurveEaseIn
                animations:^{
                appPreviewImageView.alpha = 0.0;
             }
              completion:nil];

[UIView animateWithDuration:0.4
                delay:0
                options:UIViewAnimationCurveEaseIn
                animations:^{
               homescreenSnapshotImageView.transform = tr;
             // appPreviewImageView.transform = tr2;
    CGFloat cx = w/2-s*(p.x-w/2);
    CGFloat cy = h/2-s*(p.y-h/2);

    appPreviewImageView.frame = CGRectMake(0,20,screenWidth, screenHeight - 20);
    appPreviewImageView.alpha = 1.0;
    wallpaperView.transform=CGAffineTransformMakeScale(1.2, 1.2);
    homescreenSnapshotImageView.center = CGPointMake(cx, cy);
    //appPreviewImageView.center = CGPointMake(cx, cy);
              //appAnimationWindow.layer.position = oldCenter;
              //appAnimationWindow.center = CGRectCenter(frame);
                //appAnimationWindow.transform=CGAffineTransformMakeScale(3.0, 3.0);
             }
              completion:^(BOOL finished){
                appAnimationWindow.hidden = TRUE;
                homescreenSnapshotImageView.hidden = TRUE;
                wallpaperView.hidden = TRUE;
                homescreenSnapshotImageView.transform=CGAffineTransformMakeScale(1.0, 1.0);
                wallpaperView.transform=CGAffineTransformMakeScale(1.0, 1.0);
                appPreviewImageView.frame = CGRectMake(0,0,0,0);
                //appPreviewImageView.transform=CGAffineTransformMakeScale(0.0, 0.0);
                //appPreviewImageView.frame = CGRectMake(0,0,0,0);
                [[iconController contentView] setHidden:FALSE];
              }];

lastAnimatedApp = [self applicationBundleID];

  NSLog(@"GD7UIDEBUG: SBApplicationIcon - launch: %@", NSStringFromCGRect(frame));
    %orig;
[pool drain];
}
else{
  %orig;
}
}
%end






%hook SBUIController

-(void)animateApplicationSuspend:(id)animate{
  if(iconAnimations){
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSLog(@"GD7UIDEBUG: SBUIController - animateApplicationSuspend: %@", animate);
  appAnimationWindow.windowLevel = 100001.0f;
  appAnimationWindow.userInteractionEnabled = TRUE;
  appAnimationWindow.hidden = TRUE; 
  appPreviewImageView.image = [UIImage liveSnapshotOfScreen];
  homescreenSnapshotImageView.image = homescreenSnapshot;
  homescreenSnapshotImageView.center = screenCenter;
appPreviewImageView.frame = CGRectMake(0,0,screenWidth, screenHeight);
  wallpaperView.transform=CGAffineTransformMakeScale(1.2, 1.2);

appPreviewImageView.alpha = 1.0;
  if([[animate bundleIdentifier] isEqual:lastAnimatedApp]){ //We have coordinates then!
CGFloat s = 4;
CGPoint p = lastIconCenter;
CGAffineTransform tr = CGAffineTransformScale(homescreenSnapshotImageView.transform, s, s);
CGFloat h = homescreenSnapshotImageView.frame.size.height;
CGFloat w = homescreenSnapshotImageView.frame.size.width;
               homescreenSnapshotImageView.transform = tr;
             // appPreviewImageView.transform = tr2;
    CGFloat cx = w/2-s*(p.x-w/2);
    CGFloat cy = h/2-s*(p.y-h/2);

   // appPreviewImageView.frame = CGRectMake(0,0,screenWidth, screenHeight);
  
    homescreenSnapshotImageView.center = CGPointMake(cx, cy);

    appAnimationWindow.hidden = FALSE;
    homescreenSnapshotImageView.hidden = FALSE;
    wallpaperView.hidden = FALSE;
appPreviewImageView.hidden = FALSE;




       [UIView animateWithDuration:0.2
                delay:0.2
                options:UIViewAnimationCurveEaseIn
                animations:^{
                appPreviewImageView.alpha = 0.0;
             }
              completion:nil];

[UIView animateWithDuration:0.4
                delay:0
                options:UIViewAnimationCurveEaseIn
                animations:^{
                
                homescreenSnapshotImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                wallpaperView.transform=CGAffineTransformMakeScale(1.0, 1.0);
                homescreenSnapshotImageView.center = screenCenter;
                appPreviewImageView.frame = CGRectMake(lastIconCenter.x, lastIconCenter.y, 0, 0); 
              //appAnimationWindow.layer.position = oldCenter;
              //appAnimationWindow.center = CGRectCenter(frame);
                //appAnimationWindow.transform=CGAffineTransformMakeScale(3.0, 3.0);
             }
              completion:^(BOOL finished){
                appAnimationWindow.hidden = TRUE;
                homescreenSnapshotImageView.hidden = TRUE;
                wallpaperView.hidden = TRUE;
                homescreenSnapshotImageView.transform=CGAffineTransformMakeScale(1.0, 1.0);
                wallpaperView.transform=CGAffineTransformMakeScale(1.0, 1.0);
                appPreviewImageView.frame = CGRectMake(0,0,0,0);
                //appPreviewImageView.transform=CGAffineTransformMakeScale(0.0, 0.0);
                //appPreviewImageView.frame = CGRectMake(0,0,0,0);
                //[[iconController contentView] setHidden:FALSE];
              }];
  }
  else{ //We don't have the last coordinates of the app icon :( just use the silly default zoom out animation.

    appAnimationWindow.hidden = FALSE;
    homescreenSnapshotImageView.hidden = FALSE;
    wallpaperView.hidden = FALSE;
appPreviewImageView.hidden = FALSE;
       [UIView animateWithDuration:0.2
                delay:0.2
                options:UIViewAnimationCurveEaseIn
                animations:^{
                appPreviewImageView.alpha = 0.0;
             }
              completion:nil];
[UIView animateWithDuration:0.4
                delay:0
                options:UIViewAnimationCurveEaseIn
                animations:^{
               
               homescreenSnapshotImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
               appPreviewImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
             // appPreviewImageView.transform = tr2
    
    wallpaperView.transform=CGAffineTransformMakeScale(1.0, 1.0);
   // homescreenSnapshotImageView.center = CGPointMake(cx, cy);
    //appPreviewImageView.center = CGPointMake(cx, cy);
              //appAnimationWindow.layer.position = oldCenter;
              //appAnimationWindow.center = CGRectCenter(frame);
                //appAnimationWindow.transform=CGAffineTransformMakeScale(3.0, 3.0);
             }
              completion:^(BOOL finished){
                appAnimationWindow.hidden = TRUE;
                homescreenSnapshotImageView.hidden = TRUE;
                wallpaperView.hidden = TRUE;
                homescreenSnapshotImageView.transform=CGAffineTransformMakeScale(1.0, 1.0);
                wallpaperView.transform=CGAffineTransformMakeScale(1.0, 1.0);
                appPreviewImageView.frame = CGRectMake(0,0,0,0);
                //appPreviewImageView.transform=CGAffineTransformMakeScale(0.0, 0.0);
                //appPreviewImageView.frame = CGRectMake(0,0,0,0);
                //[[iconController contentView] setHidden:FALSE];
              }];
  }

  %orig;
  [pool drain];
}
else{
  %orig;
}
}

%end

@interface SBLinenView : UIView

+(CGRect)_scaledRectForIndex:(unsigned)index ofImage:(id)image;
-(float)_vOffsetOfTop;
@end

%hook SBLinenView



/*
-(void)setFrame:(CGRect)frame{
  //%log;
   %orig;
   return;
   if(!replaceLinen){
    return;
   }
  //NSLog(@"GD7UIDEBUG: subviews: %@", [self subviews]);
    int currentOrientation = [UIDevice currentDevice].orientation;
    float screenHeight = [[UIScreen mainScreen] bounds].size.height;
if (UIDeviceOrientationIsLandscape(currentOrientation))
{
     screenHeight = [[UIScreen mainScreen] bounds].size.width;
       
}
else{
     
    screenHeight = [[UIScreen mainScreen] bounds].size.height;
}
  for(UIImageView *imageView in [self subviews]){
    if([imageView isKindOfClass:[UIImageView class]]){
      CGRect rect = [[imageView superview] convertRect:imageView.frame toView:[[UIApplication sharedApplication] keyWindow]];
      float newOffset = ([self superview].frame.origin.y - [self _vOffsetOfTop]) / screenHeight;
      //NSLog(@"GD7UIDEBUG: Rect is %@ - imageView frame is %@, offset is %f", NSStringFromCGRect([self superview].frame), NSStringFromCGRect(imageView.frame), newOffset);
      //imageView.image = imageView.image;//[self homeBackgroundImage];
      //imageView.contentMode = UIViewContentModeTopLeft; 
      //imageView.clipsToBounds = YES;
      imageView.layer.contentsRect = CGRectMake(0.0, newOffset, 1, 1);
    
      //imageView.layer.contentsRect = CGRectMake(0.0, 0.0, 1, 1);

    }
  }
  
 
}
*/

+(id)squareImageForBounds:(CGRect)bounds{
  if(!replaceLinen){
    return %orig;
  }
  return [[self blurredHomeBackgroundImage] croppedImage:bounds];
}

+(id)_imageViewForIndex:(int)index{
  if(!replaceLinen){
    return %orig;
  }
  UIImageView *imageView = %orig;

  CGRect scaledRect = [self _scaledRectForIndex:index ofImage:[self _imageForIndex:index]];
  CGRect rect = [[[UIApplication sharedApplication] keyWindow] convertRect:scaledRect toView:[[UIApplication sharedApplication] keyWindow]];
  imageView.image = [[self blurredHomeBackgroundImage] croppedImage:rect];
  return imageView;
/*
  CGRect rect = [[[UIApplication sharedApplication] keyWindow] convertRect:imageView.frame toView:[[UIApplication sharedApplication] keyWindow]];
  //NSLog(@"GD7UIDEBUG: Rect would be %@, convertedRect would be: %@", NSStringFromCGRect([self _scaledRectForIndex:index ofImage:[self _imageForIndex:index]]), NSStringFromCGRect(rect));
  imageView.image = [self blurredHomeBackgroundImage];
  imageView.frame = [self _scaledRectForIndex:index ofImage:[self _imageForIndex:index]];
  imageView.contentMode = UIViewContentModeTopLeft; 
  imageView.clipsToBounds = YES;
  imageView.layer.contentsRect = CGRectMake(0.0, 0.0, 1, 1);
  return imageView;
  */
}

%new
+(UIImage *)lockBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap"]){
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
else{
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new
+(UIImage *)homeBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap"]){
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
else{
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new(@:@)
+(UIImage *)blurredHomeBackgroundImage{
  if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/HomeBackgroundBlurred.png"]){
    return [UIImage imageWithContentsOfFile:@"/var/mobile/Library/SpringBoard/HomeBackgroundBlurred.png"];
  }
return [[self homeBackgroundImage] fastBlurWithQuality:4 interpolation:4 blurRadius:15]; //Fallback code I guess, to make it live if needed?
}


%end


%hook SBLinenNotchView

+(id)_squareImageForNotchInfo:(id)notchInfo orientation:(int)orientation{
  if(!replaceLinen){
    return %orig;
  }
  return [self blurredHomeBackgroundImage];
}

%new
+(UIImage *)lockBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap"]){
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
else{
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new
+(UIImage *)homeBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap"]){
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
else{
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new(@:@)
+(UIImage *)blurredHomeBackgroundImage{
  if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/HomeBackgroundBlurred.png"]){
    return [UIImage imageWithContentsOfFile:@"/var/mobile/Library/SpringBoard/HomeBackgroundBlurred.png"];
  }
return [[self homeBackgroundImage] fastBlurWithQuality:4 interpolation:4 blurRadius:15]; //Fallback code I guess, to make it live if needed?
}

%end




/*


Dock magic!


*/

@interface SBDockIconListView : UIImageView
-(UIImage *)blurredHomeBackgroundImage;
@end

%hook SBDockIconListView


-(void)_updateForOrientation:(int)orientation duration:(double)duration{
  %orig;
  if(blurDock){
    [self updateDockBackground];
  }
}

-(void)layoutSubviews{
  %orig;
  if(blurDock){
   // [self updateDockBackground];
  }
}

-(float)topIconInset{
  if(!blurDock){
    return %orig;
  }

  
    

  if([[UIScreen mainScreen] bounds].size.width >= 480){
    return 30;
  }
  else{
    return 15;
  }

}

%new
-(void)updateDockBackground{
    float screenHeight = [[UIScreen mainScreen] bounds].size.height;
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
     float wallpaperHeight = [self blurredHomeBackgroundImage].size.height;
    float wallpaperWidth = [self blurredHomeBackgroundImage].size.width;
if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
{
     screenHeight = [[UIScreen mainScreen] bounds].size.width;
    screenWidth = [[UIScreen mainScreen] bounds].size.height;
       if(wallpaperHeight < wallpaperWidth){
        wallpaperHeight = [self blurredHomeBackgroundImage].size.height;
        wallpaperWidth = [self blurredHomeBackgroundImage].size.width;
    }
    else{
        wallpaperHeight = [self blurredHomeBackgroundImage].size.height;
        wallpaperWidth = [self blurredHomeBackgroundImage].size.width * 2;
    }
}
else{
     
    screenHeight = [[UIScreen mainScreen] bounds].size.height;
    screenWidth = [[UIScreen mainScreen] bounds].size.width;
        if(wallpaperHeight < wallpaperWidth){
        wallpaperWidth = [self blurredHomeBackgroundImage].size.height * 2;
        wallpaperHeight = [self blurredHomeBackgroundImage].size.width; 
    }
    else{

    }
}
UIView *dockContainerView = [[%c(SBIconController) sharedInstance] dockContainerView];
//NSLog(@"GD7UIDEBUG: Dock subviews are %@", [[%c(SBIconController) sharedInstance] dockContainerView]);

for(UIView *view in [[[%c(SBIconController) sharedInstance] dockContainerView] subviews]){
  [view setBackgroundColor:[UIColor clearColor]];
}
//FIXEME (IF IT BREAKS) - Used to be [[self blurredHomeBackgroundImage] copy] in there. Maybe for good reason? Replace it elsewhere when used such as in the the Greyd00rStockLSView.m file from the stock lockscreen.

UIImage *blurredImage = nil;
//NSLog(@"DOCKY is %f", dockContainerView.frame.origin.y);
//[[[%c(SBIconController) sharedInstance] dockContainerView] setBackgroundColor:[UIColor colorWithPatternImage:blurredImageDockContainer]];



 if([[UIScreen mainScreen] bounds].size.width >= 480){
  //NSLog(@"Device is iPad, setting dock blur for iPad. width is %f height is %f", screenWidth, screenHeight);
  blurredImage = [[self blurredHomeBackgroundImage] croppedImage:CGRectMake(0,screenHeight - 140, screenWidth, 140)];
  [self setBackgroundColor:[UIColor colorWithPatternImage:blurredImage]];

dockContainerView.frame = CGRectMake(0, screenHeight - 140, screenWidth, 140);
self.frame = CGRectMake((screenWidth / 2 )- (screenWidth / 2), 0, screenWidth, 140);

  }
  else{
    blurredImage = [[self blurredHomeBackgroundImage] croppedImage:CGRectMake(0,screenHeight - 90, screenWidth, 90)];
    [self setBackgroundColor:[UIColor colorWithPatternImage:blurredImage]];
    dockContainerView.frame = CGRectMake(0, screenHeight - 90, screenWidth, 90);
self.frame = CGRectMake(0, 0, screenWidth, 90); //To make the dock slightly bigger like on iOS 7+
  }
}


%new
-(UIImage *)lockBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap"]){
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
else{
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new
-(UIImage *)homeBackgroundImage{
if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap"]){
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap" flags:nil]; //Flags?
}
else{
  return [UIImage imageWithContentsOfCPBitmapFile:@"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap" flags:nil]; //Flags?
}
}

%new(@:@)
-(UIImage *)blurredHomeBackgroundImage{
  if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/HomeBackgroundBlurred.png"]){
    return [UIImage imageWithContentsOfFile:@"/var/mobile/Library/SpringBoard/HomeBackgroundBlurred.png"];
  }
return [[self homeBackgroundImage] fastBlurWithQuality:4 interpolation:4 blurRadius:15]; //Fallback code I guess, to make it live if needed?
}
%end

%hook UIApplication

-(void)dealloc{
  NSLog(@"GD7UIDEBUG: UIAPPLICATION_DEALLOC called!");
  if(gduiController && interfaceBundle){
          interfaceLoaded = FALSE;
          [interfaceBundle unload];
          [interfaceBundle release], interfaceBundle = nil;
          //[interface release];
          [gduiController release];
  }
  %orig;
}

%end


%end


%group UIPSTableHooks


%hook UIColor
+ (id)groupTableViewBackgroundColor{
  //if(!shouldLoadHookGroup(@"UIPSTableHooks")) return %orig;
  return [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0];
}

+ (id)scrollViewTexturedBackgroundColor{
  //if(!shouldLoadHookGroup(@"UIPSTableHooks")) return %orig;
  return [UIColor colorWithPatternImage:[self blurredHomeBackgroundImage]];
}

+ (id)pinStripeColor{
  //if(!shouldLoadHookGroup(@"UIPSTableHooks")) return %orig;
  return [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0];
}

%new(@:@)
+(UIImage *)blurredHomeBackgroundImage{
  if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/SpringBoard/HomeBackgroundBlurred.png"]){
    return [UIImage imageWithContentsOfFile:@"/var/mobile/Library/SpringBoard/HomeBackgroundBlurred.png"];
  }
return [[self homeBackgroundImage] fastBlurWithQuality:4 interpolation:4 blurRadius:15]; //Fallback code I guess, to make it live if needed?
}

%end


%hook UIPreferencesTableCell

- (void)_drawSeparatorInRect:(CGRect)arg1{
    //if(!shouldLoadHookGroup(@"UIPSTableHooks")){ %orig; return;}
  CGRect newRect = CGRectMake(0,arg1.origin.y, [[UIScreen mainScreen] bounds].size.width, arg1.size.height);
  %orig(newRect);
}

- (void)_setTableBackgroundCGColor:(struct CGColor *)arg1 withSystemColorName:(id)arg2{
  //if(!shouldLoadHookGroup(@"UIPSTableHooks")){ %orig; return;}
  %orig([UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0].CGColor, arg2);
}


-(id)outlineColor{
//if(!shouldLoadHookGroup(@"UIPSTableHooks")) return %orig;
    UIColor *seperatorColor = [UIColor colorWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1.0];
    seperatorColor = [UIColor greenColor];
    seperatorColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController tableViewCellSeperatorColor] : seperatorColor;
    return seperatorColor;
}

/*
- (id)initWithCoder:(id)arg1{
  self = %orig;
  if(self){

    UIColor *seperatorColor = [UIColor colorWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1.0];
    seperatorColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController tableViewCellSeperatorColor] : seperatorColor;
    [self setSeparatorColor:seperatorColor];

    UIColor *textColor = [UIColor greenColor];
    textColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController tableViewCellTextColor] : textColor;
    [self setTextColor:textColor];
  }
  return self;
}
*/

%end

%end


%group UIAlertViewHooks


%hook UIAlertViewButton
- (void)setImage:(id)arg1 forState:(unsigned int)arg2{
  //if(!shouldLoadHookGroup(@"UIAlertViewHooks")){ %orig; return;}
UIColor *tintColorSelected = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    UIColor *tintColorNormal = [UIColor colorWithRed:100/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0];
    UIColor *tintColorDisabled = [UIColor colorWithRed:160/255.0 green:160.0/255.0 blue:160.0/255.0 alpha:1.0];
    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColorSelected = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColorSelected = (gduiController && dynamicInterfaceEnabled) ? [gduiController alertButtonImageTintColor:TRUE] : tintColorSelected;
    tintColorNormal = (gduiController && dynamicInterfaceEnabled) ? [gduiController alertButtonImageTintColor:FALSE] : tintColorNormal;
    tintColorDisabled = (gduiController && dynamicInterfaceEnabled) ? [gduiController alertButtonImageTintColorDisabled] : tintColorDisabled;

    if(arg2 == UIControlStateDisabled){
      %orig([arg1 tintedImageUsingColor:tintColorDisabled alpha:1.0], arg2);
      return;
    }

    if(arg2 == UIControlStateNormal){
      %orig([arg1 tintedImageUsingColor:tintColorSelected alpha:1.0], arg2);
      return;
    }

    if(arg2 == UIControlStateHighlighted || arg2 == UIControlStateSelected){
      %orig([arg1 tintedImageUsingColor:tintColorNormal alpha:1.0], arg2);
      return;
    }

    %orig;


}

-(void)layoutSubviews{
  //if(!shouldLoadHookGroup(@"UIAlertViewHooks")){ %orig; return;}
  %orig;
      UIColor *tintColorSelected = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    UIColor *tintColorNormal = [UIColor colorWithRed:100/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0];
    UIColor *tintColorDisabled = [UIColor colorWithRed:160/255.0 green:160.0/255.0 blue:160.0/255.0 alpha:1.0];
    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColorSelected = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColorSelected = (gduiController && dynamicInterfaceEnabled) ? [gduiController alertButtonImageTintColor:TRUE] : tintColorSelected;
    tintColorNormal = (gduiController && dynamicInterfaceEnabled) ? [gduiController alertButtonImageTintColor:FALSE] : tintColorNormal;
    tintColorDisabled = (gduiController && dynamicInterfaceEnabled) ? [gduiController alertButtonImageTintColorDisabled] : tintColorDisabled;

    [self setTitleColor:tintColorSelected forState:UIControlStateNormal];
    [self setTitleColor:tintColorDisabled forState:UIControlStateDisabled];
    [self setTitleColor:tintColorNormal forState:UIControlStateHighlighted|UIControlStateSelected];
}



%end

%hook UIAlertView


+ (id)_popupAlertBackground:(BOOL)arg1{
    //if(!shouldLoadHookGroup(@"UIAlertViewHooks")) return %orig;
  self = %orig;
  return [self tintedImageUsingColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0] alpha:0.0];
  //return [UIImage imageWithColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]];
 //return [UIImage liveBlurForScreenWithQuality:4 interpolation:4 blurRadius:15];
}


-(void)layout{
    //if(!shouldLoadHookGroup(@"UIAlertViewHooks")){ %orig; return;}
  %orig;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  UIColor *tintColorSelected = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    UIColor *tintColorNormal = [UIColor colorWithRed:100/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0];
    UIColor *tintColorDisabled = [UIColor colorWithRed:160/255.0 green:160.0/255.0 blue:160.0/255.0 alpha:1.0];
    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColorSelected = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColorSelected = (gduiController && dynamicInterfaceEnabled) ? [gduiController alertButtonImageTintColor:TRUE] : tintColorSelected;
    tintColorNormal = (gduiController && dynamicInterfaceEnabled) ? [gduiController alertButtonImageTintColor:FALSE] : tintColorNormal;
    tintColorDisabled = (gduiController && dynamicInterfaceEnabled) ? [gduiController alertButtonImageTintColorDisabled] : tintColorDisabled;

  UIImageView *imageView = [self valueForKey:@"backgroundImageView"];
  /*
  if(imageView){
      imageView.contentMode = UIViewContentModeTopLeft; 
      float yOffset = [[self valueForKey:@"startY"] floatValue] / [[UIScreen mainScreen] bounds].size.height;
      imageView.layer.contentsRect = CGRectMake(0.0, yOffset, 1, 1);
      imageView.layer.masksToBounds = YES;
  }
  */

  for(UIButton *oldButton in [self buttons]){
   [oldButton setTitleColor:tintColorSelected forState:UIControlStateNormal];
    [oldButton setTitleColor:tintColorDisabled forState:UIControlStateDisabled];
    [oldButton setTitleColor:tintColorSelected forState:UIControlStateHighlighted];
    [oldButton setTitleColor:tintColorSelected forState:UIControlStateSelected];
    [oldButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [oldButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateDisabled];
    [oldButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [oldButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateSelected];
    [oldButton setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor]] forState:UIControlStateNormal];
    [oldButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0]] forState:UIControlStateSelected];
    [oldButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0]] forState:UIControlStateHighlighted];
  }

  UILabel *titleLabel = [self valueForKey:@"titleLabel"];
  UILabel *subtitleLabel = [self valueForKey:@"subtitleLabel"];
  UILabel *bodyTextLabel = [self valueForKey:@"bodyTextLabel"];
  UILabel *tagLineTextLabel = [self valueForKey:@"taglineTextLabel"];

UIColor *tintColorTitle = [UIColor blackColor];
tintColorTitle = (gduiController && dynamicInterfaceEnabled) ? [gduiController alertViewTitleColor] : tintColorTitle;

UIColor *tintColorBody = [UIColor blackColor];
tintColorBody = (gduiController && dynamicInterfaceEnabled) ? [gduiController alertViewBodyTextColor] : tintColorBody;

if(titleLabel){
  titleLabel.textColor = tintColorTitle;
  titleLabel.shadowColor = [UIColor clearColor];
}

if(subtitleLabel){
  subtitleLabel.textColor = tintColorBody;
  subtitleLabel.shadowColor = [UIColor clearColor];
}

if(bodyTextLabel){
  bodyTextLabel.textColor = tintColorBody;
  bodyTextLabel.shadowColor = [UIColor clearColor];
}

if(tagLineTextLabel){
  tagLineTextLabel.textColor = tintColorBody;
  tagLineTextLabel.shadowColor = [UIColor clearColor];
}

  [pool drain];

}



/*
-(id)buttonAtIndex:(int)index{
  UIButton *oldButton = %orig;
  UIButton *newButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
  [button setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]] forState:UIControlStateDisabled];
  [button setBackgroundImage:[UIImage imageWithColor:[UIColor grayColor]] forState:UIControlStateSelected];
  [button setBackgroundImage:[UIImage imageWithColor:[UIColor grayColor]] forState:UIControlStateHighlighted];
  [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  [button setText]
  [mybutton titleForState:UIControlStateNormal]
  for (id target in oldButton.allTargets) {
     NSArray *actions = [oldButton actionsForTarget:target
                                      forControlEvent:UIControlEventTouchUpInside];
     for (NSString *action in actions) {
          [newButton addTarget:target action:NSSelectorFromString(action) forControlEvents:UIControlEventTouchUpInside];
     }
}

  return button;
}

*/
%end



%end


%group UINavigationBarHooks

%hook UINavigationBar


- (void)_setBarStyle:(UIBarStyle)barStyle {
    //if(!shouldLoadHookGroup(@"UINavigationBarHooks")){ %orig; return;}
 // NSLog(@"GD7UIDEBUG: TintColor is: %@", self.titleTextAttributes);
 %orig;
/*
   NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIColor blackColor],UITextAttributeTextColor, 
                                            [UIColor clearColor], UITextAttributeTextShadowColor, 
                                            [NSValue valueWithUIOffset:UIOffsetMake(0, 0)], UITextAttributeTextShadowOffset, nil];

[[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];

*/
    UIColor *backgroundColor = nil;
    UIColor *titleColor = nil;
    switch (barStyle) {
        case UIBarStyleDefault: {
            backgroundColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navBarBackgroundColor] : [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0];
            titleColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navBarTitleColor] : [UIColor blackColor];
        }   break;
        case UIBarStyleBlackOpaque:
        case UIBarStyleBlackTranslucent: {
           backgroundColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navBarBackgroundColor] : [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0];
            titleColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navBarTitleColor] : [UIColor blackColor];
            //backgroundColor = [UIColor colorWithWhite:0 alpha:167];
            //titleColor = [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0];
        }   break;
        default:
            break;
    }

    if (titleColor) {
        NSDictionary *dict = @{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor: titleColor,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               };
        self.titleTextAttributes = dict;
        // Trick to force rerender title
        NSString *title = [self.topItem.title retain];
        self.topItem.title = @"";
        self.topItem.title = title;
        [title release];
        self.backgroundColor = backgroundColor;
    }


       
}

- (void)pushNavigationItem:(UINavigationItem *)item {
    %orig;
   // [item setTintColor:[UIColor redColor]];
}

/*
- (void)drawBackgroundInRect:(struct CGRect)rect withStyle:(int)arg2{
 NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
     CGContextRef context = UIGraphicsGetCurrentContext(); 

    CGRect drawRect = CGRectMake(rect.origin.x, rect.origin.y,rect.size.width, rect.size.height);
//First off-white
       CGContextStrokePath(context);
        CGContextSetRGBFillColor(context, 242.0/255.0, 242.0/255.0, 242.0/255.0, 1.0f);
        CGContextFillRect(context, CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height ));

//Then grey

        CGContextStrokePath(context);
        CGContextSetRGBFillColor(context, 200.0/255.0, 200.0/255.0, 200.0/255.0, 1.0f);
        CGContextFillRect(context, CGRectMake(0, rect.size.height -1, rect.size.width, 1));
       
[pool drain];
}
*/

/*
- (id)backgroundImageForBarMetrics:(int)arg1{
 
  return [UIImage imageWithColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]];
}
*/
- (void)setBackgroundImage:(id)arg1 forBarMetrics:(int)arg2{
      //if(!shouldLoadHookGroup(@"UINavigationBarHooks")){ %orig; return;}
  if(arg1 == nil){ //only run this if the argument for the image is nil, which means it is our hack-around for iPad.
  UIImage *navImage = ({
    UIImage *image;
    if(gduiController && dynamicInterfaceEnabled){
        if(![gduiController navBarBackgroundImage] == nil){
          image = [gduiController navBarBackgroundImage];
        }
    } 
    else{
      image = [UIImage imageWithColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]];
    }
    image;
 
  });

   %orig(navImage,arg2);
   return;
 }

 %orig(arg1,arg2);
}

-(UIColor*)buttonItemTextColor{
      //if(!shouldLoadHookGroup(@"UINavigationBarHooks")) return %orig;
    UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }

    tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navBarButtonItemTextColor:TRUE] : tintColor; //Well... okay? basically only update the tint color if it is actually available...

  return tintColor;
}

-(UIColor*)buttonItemShadowColor{
      //if(!shouldLoadHookGroup(@"UINavigationBarHooks")) return %orig;
  return [UIColor clearColor];
}

-(void)layoutSubviews{
      //if(!shouldLoadHookGroup(@"UINavigationBarHooks")){ %orig; return;}
  %orig;
    if(gduiController && dynamicInterfaceEnabled){
        if(![gduiController navBarBackgroundImage] == nil){
          [self setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault]; //Only need this if there is a background image, which only happens if the device is an iPad.
        }
    }else{
      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [self setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    }  


  [[self valueForKey:@"backgroundView"] setBackgroundColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]];
  //[self setTintColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]];

}

- (void)drawBackgroundInRect:(struct CGRect)arg1 withStyle:(int)arg2{
      //if(!shouldLoadHookGroup(@"UINavigationBarHooks")){ %orig; return;}
  %orig(arg1,1);
}


- (void)drawBackButtonBackgroundInRect:(struct CGRect)arg1 withStyle:(int)arg2 pressed:(BOOL)arg3{
      //if(!shouldLoadHookGroup(@"UINavigationBarHooks")){ %orig; return;}
  %orig(arg1,1,arg3); //Like that, iPads use the back button properly. Is this a bad idea? probably. :)
}

/*
-(UIColor*)_effectiveTintColor{
  return [UIColor blackColor];
}
*/
%end


%hook UINavigationButton

-(id)_backgroundForState:(unsigned)state usesBackgroundForNormalState:(BOOL*)normalState{
      //if(!shouldLoadHookGroup(@"UINavigationBarHooks")) return %orig;
    if(self.title){
        return nil;
    }
    return %orig;
}

-(id)_imageForState:(unsigned)state usesImageForNormalState:(BOOL*)normalState{
      //if(!shouldLoadHookGroup(@"UINavigationBarHooks")) return %orig;
    if(self.title){
        return nil;
    }
    return %orig;
}

- (void)_setBackgroundImage:(id)arg1 forState:(unsigned int)arg2 barMetrics:(int)arg3{
      //if(!shouldLoadHookGroup(@"UINavigationBarHooks")){ %orig; return;}
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navButtonItemBackgroundImage:TRUE] : tintColor;

  %orig([arg1 tintedImageUsingColor:tintColor alpha:1.0],arg2,arg3);
  [pool drain];
}

-(id)initWithTitle:(id)title{
      //if(!shouldLoadHookGroup(@"UINavigationBarHooks")) return %orig;
self = %orig;
if(self){

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UIColor *titleTintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       titleTintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    titleTintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navButtonItemTintColor:TRUE] : titleTintColor;
    
    [self setTitleColor:titleTintColor forState:UIControlStateNormal];
   
    [self setImage:NULL forState:UIControlStateNormal];
    [self setImage:NULL forState:UIControlStateHighlighted];
   if (!UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [self setBackgroundImage:NULL forState:UIControlStateNormal];
   if (!UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [self setBackgroundImage:NULL forState:UIControlStateHighlighted];
    [[self valueForKey:@"backgroundView"] setHidden:TRUE];
    [[self valueForKey:@"imageView"] setHidden:TRUE];
    UIColor *selectedTitleTintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navButtonItemTintColor:FALSE] : titleTintColor;
    [self setTitleColor:selectedTitleTintColor forState:UIControlStateHighlighted];
    [self setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [self setTitleShadowColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [[self titleLabel] setShadowOffset:CGSizeMake(0.0, 1.0)];
    [[self titleLabel] setFont:[UIFont boldSystemFontOfSize:16.0]];
    CGRect buttonFrame = [self frame];
    buttonFrame.size.width = [self.title sizeWithFont:[UIFont boldSystemFontOfSize:16.0]].width + 24.0;
    buttonFrame.size.height = [self.title sizeWithFont:[UIFont boldSystemFontOfSize:16.0]].height + 10;
    [pool drain];
}
return self;
}

-(id)initWithTitle:(id)title style:(int)style{
      //if(!shouldLoadHookGroup(@"UINavigationBarHooks")) return %orig;
self = %orig;
if(self){

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UIColor *titleTintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       titleTintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    titleTintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navButtonItemTintColor:TRUE] : titleTintColor;
    
    [self setTitleColor:titleTintColor forState:UIControlStateNormal];
   
    [self setImage:NULL forState:UIControlStateNormal];
    [self setImage:NULL forState:UIControlStateHighlighted];
   if (!UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [self setBackgroundImage:NULL forState:UIControlStateNormal];
   if (!UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [self setBackgroundImage:NULL forState:UIControlStateHighlighted];
    [[self valueForKey:@"backgroundView"] setHidden:TRUE];
    [[self valueForKey:@"imageView"] setHidden:TRUE];
    UIColor *selectedTitleTintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navButtonItemTintColor:FALSE] : titleTintColor;
    [self setTitleColor:selectedTitleTintColor forState:UIControlStateHighlighted];
    [self setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [self setTitleShadowColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [[self titleLabel] setShadowOffset:CGSizeMake(0.0, 1.0)];
    [[self titleLabel] setFont:[UIFont boldSystemFontOfSize:16.0]];
    CGRect buttonFrame = [self frame];
    buttonFrame.size.width = [self.title sizeWithFont:[UIFont boldSystemFontOfSize:16.0]].width + 24.0;
    buttonFrame.size.height = [self.title sizeWithFont:[UIFont boldSystemFontOfSize:16.0]].height + 10;
    [pool drain];
}
return self;
}

-(id)initWithTitle:(id)title possibleTitles:(id)titles style:(int)style{
      //if(!shouldLoadHookGroup(@"UINavigationBarHooks")) return %orig;
self = %orig;
if(self){

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UIColor *titleTintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       titleTintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    titleTintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navButtonItemTintColor:TRUE] : titleTintColor;
    
    [self setTitleColor:titleTintColor forState:UIControlStateNormal];
   
    [self setImage:NULL forState:UIControlStateNormal];
    [self setImage:NULL forState:UIControlStateHighlighted];
   if (!UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [self setBackgroundImage:NULL forState:UIControlStateNormal];
   if (!UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) [self setBackgroundImage:NULL forState:UIControlStateHighlighted];
    [[self valueForKey:@"backgroundView"] setHidden:TRUE];
    [[self valueForKey:@"imageView"] setHidden:TRUE];
    UIColor *selectedTitleTintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navButtonItemTintColor:FALSE] : titleTintColor;
    [self setTitleColor:selectedTitleTintColor forState:UIControlStateHighlighted];
    [self setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [self setTitleShadowColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [[self titleLabel] setShadowOffset:CGSizeMake(0.0, 1.0)];
    [[self titleLabel] setFont:[UIFont boldSystemFontOfSize:16.0]];
    CGRect buttonFrame = [self frame];
    buttonFrame.size.width = [self.title sizeWithFont:[UIFont boldSystemFontOfSize:16.0]].width + 24.0;
    buttonFrame.size.height = [self.title sizeWithFont:[UIFont boldSystemFontOfSize:16.0]].height + 10;
    [pool drain];
}
return self;   
}

-(id)initWithValue:(id)value width:(float)width style:(int)style barStyle:(int)style4 possibleTitles:(id)titles tintColor:(id)color{
    //if(!shouldLoadHookGroup(@"UINavigationBarHooks")) return %orig;
self = %orig;
if(self){

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UIColor *titleTintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       titleTintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    titleTintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navButtonItemTintColor:TRUE] : titleTintColor;
    
    [self setTitleColor:titleTintColor forState:UIControlStateNormal];
   

    UIColor *selectedTitleTintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController navButtonItemTintColor:FALSE] : titleTintColor;
    [self setTitleColor:selectedTitleTintColor forState:UIControlStateHighlighted];
    [self setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [self setTitleShadowColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [[self titleLabel] setShadowOffset:CGSizeMake(0.0, 1.0)];
    [[self titleLabel] setFont:[UIFont boldSystemFontOfSize:16.0]];
    CGRect buttonFrame = [self frame];
    buttonFrame.size.width = [self.title sizeWithFont:[UIFont boldSystemFontOfSize:16.0]].width + 24.0;
    buttonFrame.size.height = [self.title sizeWithFont:[UIFont boldSystemFontOfSize:16.0]].height + 10;
    [pool drain];
}
return self; 

/*

self = %orig;
if(self){
    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
        [self setTitleColor:[UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    }
    else{
  [self setTitleColor:[UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    }



    [self setTitleColor:[UIColor colorWithRed:100/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0] forState:UIControlStateHighlighted];
    [self setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [self setTitleShadowColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [[self titleLabel] setShadowOffset:CGSizeMake(0.0, 1.0)];
    [[self titleLabel] setFont:[UIFont boldSystemFontOfSize:16.0]];
    CGRect buttonFrame = [self frame];
    buttonFrame.size.width = [self.title sizeWithFont:[UIFont boldSystemFontOfSize:16.0]].width + 24.0;
    buttonFrame.size.height = [self.title sizeWithFont:[UIFont boldSystemFontOfSize:16.0]].height + 10;
    [self setFrame:buttonFrame];

}
return self; 
*/
}
%end

%end
//----------------End of UINavigationBar hooks------------\\


@interface UIBarButtonItem (Private)

@property(retain, nonatomic, getter=_miniImage, setter=_setMiniImage:) UIImage *miniImage;
@end


//-------------Start of UIBar/UIBarItem hooks-------------\\
%group UIBarHooks
%hook UIBarButtonItem




%new
-(void)tintBackgroundImages{
  
  //NSLog(@"GD7UIDEBUG: - UIBarButtonItem tintBackgroundImages called!");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  UIImage *backgroundImage = ({
     UIImage *image;
      if(gduiController && interfaceLoaded){
        if(![interface barButtonItemBackgroundImage:FALSE] == nil){
            image = [interface barButtonItemBackgroundImage:FALSE];

        }
        image = [UIImage imageWithColor:[interface barButtonItemBackgroundColor:FALSE]];
        
      }
      image = [UIImage imageWithColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]];
      image;

  });

  UIImage *backgroundImageSelected = ({
     UIImage *image;
      if(gduiController && interfaceLoaded){
        if(![interface barButtonItemBackgroundImage:TRUE] == nil){
            image = [interface barButtonItemBackgroundImage:TRUE];
            
        }
        image = [UIImage imageWithColor:[interface barButtonItemBackgroundColor:TRUE]];

      }
      image = [UIImage imageWithColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]];
      image;

  });


  UIImage *backBackgroundImage = ({
     UIImage *image;
      if(gduiController && interfaceLoaded){
        if(![interface barButtonItemBackgroundImage:FALSE] == nil){
            image = [interface barButtonItemBackgroundImage:FALSE];
           
        }
        image = [UIImage imageWithColor:[interface barButtonItemBackgroundColor:FALSE]];
        
      }
      image = [UIImage imageWithColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]];
      image;

  });

  UIImage *backBackgroundImageSelected = ({
     UIImage *image;
      if(gduiController && interfaceLoaded){
        if(![interface barButtonItemBackButtonBackgroundImage:TRUE] == nil){
            image = [interface barButtonItemBackButtonBackgroundImage:TRUE];
           
        }
        image = [UIImage imageWithColor:[interface barButtonItemBackButtonBackgroundColor:TRUE]];
      
      }
      image = [UIImage imageWithColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]];
      image;
      
  });

  [self setBackgroundImage:backgroundImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault]; //Oh look magic hack around.

  [self setBackgroundImage:backgroundImageSelected forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
  [self setBackgroundImage:backgroundImageSelected forState:UIControlStateDisabled barMetrics:UIBarMetricsDefault];

  
  [self setBackButtonBackgroundImage:backBackgroundImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault]; //Oh look magic hack around.
  [self setBackButtonBackgroundImage:backBackgroundImageSelected forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
  [self setBackButtonBackgroundImage:backBackgroundImageSelected forState:UIControlStateDisabled barMetrics:UIBarMetricsDefault];

 
  //[[self valueForKey:@"backgroundView"] setBackgroundColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]];
  //[self setTintColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]];


UIColor *tintColorSelected = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    UIColor *tintColorNormal = [UIColor colorWithRed:100/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0];
    UIColor *tintColorDisabled = [UIColor colorWithRed:160/255.0 green:160.0/255.0 blue:160.0/255.0 alpha:1.0];
    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColorSelected = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColorSelected = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:TRUE] : tintColorSelected;
    tintColorNormal = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:FALSE] : tintColorNormal;
    tintColorDisabled = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColorDisabled] : tintColorDisabled;

    self.tintColor = tintColorSelected;

          NSDictionary *selectedStateDict = @{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColorSelected,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               };

  
     NSDictionary *normalStateDict = @{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColorSelected,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               };
      NSDictionary *disabledStateDict = @{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColorDisabled,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               };
 
  [self setTitleTextAttributes:selectedStateDict forState:UIControlStateHighlighted];
  [self setTitleTextAttributes:disabledStateDict forState:UIControlStateDisabled];
  [self setTitleTextAttributes:normalStateDict forState:UIControlStateNormal];


if(self.image){
 // NSLog(@"HAS BARBUTTONITEM IMAGE DAMMIT");
  self.image = [self.image tintedImageUsingColor:tintColorSelected alpha:1.0];
}

if(self.landscapeImagePhone){
 //NSLog(@"HAS BARBUTTONITEM landscapeImagePhone DAMMIT");
  self.landscapeImagePhone = [self.landscapeImagePhone tintedImageUsingColor:tintColorSelected alpha:1.0];
}

if(self.miniImage){
   //NSLog(@"HAS BARBUTTONITEM miniImage DAMMIT");
    self.landscapeImagePhone = [self.landscapeImagePhone tintedImageUsingColor:tintColorSelected alpha:1.0];
}
   [pool drain];
}


- (void)setImage:(id)arg1{
    //if(!shouldLoadHookGroup(@"UIBarHooks")){ %orig; return;}
    UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:self.selected] : tintColor;
    //NSLog(@"SETIMAGE CALLED");
  if([self isEnabled]){
    UIImage *tinted = [arg1 tintedImageUsingColor:tintColor alpha:1.0];
    %orig(tinted);
    return; 
  }
  else{
    UIImage *tinted = [arg1 tintedImageUsingColor:tintColor alpha:1.0];
    %orig(tinted);
    return;
  }
}


/*
- (void)setBackgroundImage:(id)arg1 forState:(unsigned int)arg2 barMetrics:(int)arg3{
    UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:self.selected] : tintColor;
  %orig([arg1 tintedImageUsingColor:tintColor alpha:1.0],arg2,arg3);
}
*/

- (void)setTitle:(id)arg1{
    //if(!shouldLoadHookGroup(@"UIBarHooks")){ %orig; return;}
  %orig;
    UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:TRUE] : tintColor;
  [self setTitleTextAttributes:@{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColor,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               } forState:UIControlStateNormal];
}

- (id)initWithImage:(id)arg1 landscapeImagePhone:(id)arg2 style:(int)arg3 target:(id)arg4 action:(SEL)arg5{
    //if(!shouldLoadHookGroup(@"UIBarHooks")) return %orig;
    UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:TRUE] : tintColor;
  return %orig([arg1 tintedImageUsingColor:tintColor alpha:1.0],[arg2 tintedImageUsingColor:tintColor alpha:1.0],arg3,arg4, arg5);
}

- (id)initWithImage:(id)arg1 style:(int)arg2 target:(id)arg3 action:(SEL)arg4{
  UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:TRUE] : tintColor;
  return %orig([arg1 tintedImageUsingColor:tintColor alpha:1.0],arg2,arg3,arg4);
}

-(id)initWithBarButtonSystemItem:(int)barButtonSystemItem target:(id)target action:(SEL)action{
  //if(!shouldLoadHookGroup(@"UIBarHooks")) return %orig;
switch (barButtonSystemItem) {
        case UIBarButtonSystemItemCompose:
        case UIBarButtonSystemItemReply:
        case UIBarButtonSystemItemAction:
        case UIBarButtonSystemItemOrganize:
        case UIBarButtonSystemItemBookmarks:
        case UIBarButtonSystemItemSearch:
        case UIBarButtonSystemItemRefresh:
        case UIBarButtonSystemItemStop:
        case UIBarButtonSystemItemCamera:
        case UIBarButtonSystemItemTrash:
        case UIBarButtonSystemItemPlay:
        case UIBarButtonSystemItemPause:
        case UIBarButtonSystemItemRewind:
        case UIBarButtonSystemItemFastForward:
        {
          NSString *name = UI7BarButtonItemIconNames[barButtonSystemItem];
          UIImage *image = [UIImage kitImageNamed:[NSString stringWithFormat:@"UIButtonBar%@.png",name]];
          UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

          if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
           tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
          }
          tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:TRUE] : tintColor;
            if(image){
              image = [image tintedImageUsingColor:tintColor alpha:1.0];
            }
            self = [self initWithImage:image style:UIBarButtonItemStylePlain target:target action:action];
            image = [UIImage kitImageNamed:[NSString stringWithFormat:@"UIButtonbar%@Landscape",name]];
            //self.tintColor = tintColor;
            [self setBackgroundImage:image forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
            return self;
            break;
        }   
        case UIBarButtonSystemItemAdd:{
          UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

    UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    UIColor *tintColorSelected = [UIColor colorWithRed:100/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:TRUE] : tintColor;
    tintColorSelected = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:FALSE] : tintColorSelected;
    // Since the buttons can be any width we use a thin image with a stretchable center point
    [[button titleLabel] setFont:[UIFont boldSystemFontOfSize:34.0]];
    [button setTitleColor:tintColor forState:UIControlStateNormal];

    [button setTitleColor:tintColorSelected forState:UIControlStateHighlighted];
    [button setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [button setTitleShadowColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [[button titleLabel] setShadowOffset:CGSizeMake(0.0, 1.0)];

    CGRect buttonFrame = [button frame];
    buttonFrame.size.width = [[NSString stringWithFormat:@"+"] sizeWithFont:[UIFont boldSystemFontOfSize:34.0]].width + 24.0;
    buttonFrame.size.height = [[NSString stringWithFormat:@"+"] sizeWithFont:[UIFont boldSystemFontOfSize:16.0]].height + 10;
    [button setFrame:buttonFrame];



    [button setTitle:@"+" forState:UIControlStateNormal];

    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

    //UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self tintBackgroundImages];

return [[UIBarButtonItem alloc] initWithCustomView:button];
break;
        }
        default: {
  self = %orig;
    UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
  tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:TRUE] : tintColor;
  //self.tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemBackgroundColor:TRUE] : [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]; //nasty hack probably will break things if the background is customized and then look ugly.
  //[self setBackgroundImage:[UIImage imageWithColor:self.tintColor] forState:UIControlStateNormal barMetrics:1];
    [self setTitleTextAttributes:@{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColor,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               } forState:UIControlStateNormal];
    [self tintBackgroundImages];

  return self;  
        }
    }


}


- (id)initWithCoder:(NSCoder *)aDecoder {
    //if(!shouldLoadHookGroup(@"UIBarHooks")) return %orig;
    self = %orig;
    if (self != nil) {
        if ([aDecoder containsValueForKey:@"UISystemItem"]) {
            UIBarButtonSystemItem item = [aDecoder decodeIntegerForKey:@"UISystemItem"];
            UIBarButtonItem *newy = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:item target:self.target action:self.action];
            [self release];
            self = newy;
        }
        //[self _barButtonItemInit];
    }
    return self;
}

- (id)initWithTitle:(id)arg1 style:(int)arg2 target:(id)arg3 action:(SEL)arg4{
    //if(!shouldLoadHookGroup(@"UIBarHooks")) return %orig;
  self = %orig;
     UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:TRUE] : tintColor;
  [self setTitleTextAttributes:@{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColor,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               } forState:UIControlStateNormal];
    if(self.isSystemItem) self.tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemBackgroundColor:TRUE] : [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]; //nasty hack probably will break things if the background is customized and then look ugly.
  //[self setBackgroundImage:[UIImage imageWithColor:self.tintColor] forState:UIControlStateNormal barMetrics:1];
  [self tintBackgroundImages];
  return self;
}


- (id)initWithCustomView:(id)arg1{
    //if(!shouldLoadHookGroup(@"UIBarHooks")) return %orig;
 self = %orig;
 //NSLog(@"INITWITHCUSTOMVIEWWWWW");
UIColor *tintColorSelected = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    UIColor *tintColorNormal = [UIColor colorWithRed:100/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0];
    UIColor *tintColorDisabled = [UIColor colorWithRed:160/255.0 green:160.0/255.0 blue:160.0/255.0 alpha:1.0];
    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColorSelected = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }

    tintColorSelected = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:TRUE] : tintColorSelected;
    tintColorNormal = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:FALSE] : tintColorNormal;
    tintColorDisabled = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColorDisabled] : tintColorDisabled;

  [self setTitleTextAttributes:@{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColorSelected,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               } forState:UIControlStateNormal];
    //if(self.isSystemItem) self.tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemBackgroundColor:TRUE] : [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]; //nasty hack probably will break things if the background is customized and then look ugly.
  //[self setBackgroundImage:[UIImage imageWithColor:self.tintColor] forState:UIControlStateNormal barMetrics:1];
    [self tintBackgroundImages];
   if([arg1 isKindOfClass:[UIButton class]]){
    NSLog(@"ISBUTTONCUSTOMVIEW");
      [arg1 setTitleColor:tintColorSelected forState:UIControlStateNormal];
      [arg1 setTitleColor:tintColorSelected forState:UIControlStateSelected];
      [arg1 setTitleColor:tintColorDisabled forState:UIControlStateDisabled];
      [arg1 setTintColor:tintColorSelected];
      if([arg1 imageForState:UIControlStateNormal]){
        NSLog(@"Has image for state?");
        [arg1 setBackgroundImage:[[arg1 imageForState:UIControlStateNormal] tintedImageUsingColor:tintColorSelected alpha:1.0] forState:UIControlStateNormal];
      }
      if([arg1 imageForState:UIControlStateHighlighted]){
        [arg1 setBackgroundImage:[[arg1 imageForState:UIControlStateHighlighted] tintedImageUsingColor:tintColorNormal alpha:1.0] forState:UIControlStateHighlighted];
      }
      if([arg1 imageForState:UIControlStateSelected]){
        [arg1 setBackgroundImage:[[arg1 imageForState:UIControlStateSelected] tintedImageUsingColor:tintColorSelected alpha:1.0] forState:UIControlStateSelected];
      }
      if([arg1 imageForState:UIControlStateDisabled]){
        [arg1 setBackgroundImage:[[arg1 imageForState:UIControlStateDisabled] tintedImageUsingColor:tintColorDisabled alpha:1.0] forState:UIControlStateDisabled];
      }
   } 

    if([arg1 isKindOfClass:[UILabel class]]){
      [arg1 setTextColor:tintColorSelected];

    }

    /* //Too slow and doesn't seem to catch anything anyway.
  for(id view in [arg1 subviews]){
    NSLog(@"CUSTOMVIEW SUBVIEW IS :%@", view);
    if([view isKindOfClass:[UIButton class]]){
       NSLog(@"ISBUTTONCUSTOMSUBVIEW");
      [view setTitleColor:tintColorSelected forState:UIControlStateNormal];
      [view setTitleColor:tintColorSelected forState:UIControlStateSelected];
      [view setTitleColor:tintColorDisabled forState:UIControlStateDisabled];
    }
    if([view isKindOfClass:[UIImageView class]]){
      [view setImage:[[view image] tintedImageUsingColor:tintColorSelected alpha:1.0]];
    }
    if([view isKindOfClass:[UILabel class]]){
      [view setTextColor:tintColorSelected];
    }

  }
  */
  return self;
}

-(id)init{
    //if(!shouldLoadHookGroup(@"UIBarHooks")) return %orig;
    self = %orig;
     UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:TRUE] : tintColor;
  [self setTitleTextAttributes:@{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColor,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               } forState:UIControlStateNormal];
     if(self.isSystemItem) self.tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemBackgroundColor:TRUE] : [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]; //nasty hack probably will break things if the background is customized and then look ugly.
  //[self setBackgroundImage:[UIImage imageWithColor:self.tintColor] forState:UIControlStateNormal barMetrics:1];
[self tintBackgroundImages];
  return self;
}


%end

%end

%group UIToolbarHooks

%hook UIToolbarButton

- (id)initWithImage:(id)image pressedImage:(id)image2 label:(UILabel*)label labelHeight:(float)height withBarStyle:(int)barStyle withStyle:(int)style withInsets:(struct UIEdgeInsets)insets possibleTitles:(id)titles withToolbarTintColor:(id)barTintColor bezel:(BOOL)bezel imageInsets:(struct UIEdgeInsets)insets11 glowInsets:(struct UIEdgeInsets)insets12{
      //if(!shouldLoadHookGroup(@"UIToolbarHooks")) return %orig;
    UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController toolbarButtonTextColor:TRUE] : tintColor;
  barTintColor = tintColor;
    if(label){

    image = nil;
    image2 = nil;
    bezel = FALSE;
    label.textColor = tintColor;
  
}

if([image isMemberOfClass:[UIImage class]]){
  //NSLog(@"UIToolbarButton image is of class UIIMAGE");
     UIColor *imageTintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       imageTintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    imageTintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController toolbarButtonImageColor:FALSE] : imageTintColor;
image = [image tintedImageUsingColor:imageTintColor alpha:1.0];
}

if([image2 isMemberOfClass:[UIImage class]]){
     UIColor *imageTintColorSelected = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       imageTintColorSelected = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    imageTintColorSelected = (gduiController && dynamicInterfaceEnabled) ? [gduiController toolbarButtonImageColor:TRUE] : imageTintColorSelected;
image2 = [image2 tintedImageUsingColor:imageTintColorSelected alpha:1.0];
}

    return %orig(image, image2, label, height, barStyle, style, insets, titles, barTintColor, bezel, insets11, insets12);

}


-(void)setImage:(UIImage*)image{
    //if(!shouldLoadHookGroup(@"UIToolbarHooks")){ %orig; return;}
//NSLog(@"UIToolbarButton setImage called!");
UIColor *imageTintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       imageTintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
}
imageTintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController toolbarButtonImageColor:[self _isOn]] : imageTintColor;
image = [image tintedImageUsingColor:imageTintColor];
%orig(image);
}

- (void)setToolbarTintColor:(id)arg1{
      UIColor *tintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }
    tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController toolbarButtonTextColor:TRUE] : tintColor;
  %orig(tintColor);
}

%end


%hook UIToolbar


-(void)layoutSubviews{
    //if(!shouldLoadHookGroup(@"UIToolbarHooks")){ %orig; return;}
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
UIColor *tintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController toolbarTintColor] : [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0];
    self.tintColor = tintColor;

UIColor *backgroundColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController toolBarBackgroundColor] : [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0];
    self.backgroundColor = backgroundColor;
    %orig;
    [pool drain];
}


-(void)setButtonItems:(id)items{
    //if(!shouldLoadHookGroup(@"UIToolbarHooks")){ %orig; return;}
    for(UIBarButtonItem *item in items){
        if([item image]){
           UIColor *imageTintColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

            if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
               imageTintColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
            }
            imageTintColor = (gduiController && dynamicInterfaceEnabled) ? [gduiController toolbarButtonImageColor:TRUE] : imageTintColor;            

            [item setImage:[[item image] tintedImageUsingColor:imageTintColor]];
           
        }
    }
    %orig;
}
%end

%end


%group UITabBarHooks
%hook UITabBarButton


- (id)initWithImage:(UIImage*)image selectedImage:(UIImage*)selected label:(id)arg3 withInsets:(struct UIEdgeInsets)arg4{
    //if(!shouldLoadHookGroup(@"UITabBarHooks")) return %orig;
  UIColor *tintColorSelected = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    UIColor *tintColorNormal = [UIColor colorWithRed:100/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0];
    UIColor *tintColorDisabled = [UIColor colorWithRed:160/255.0 green:160.0/255.0 blue:160.0/255.0 alpha:1.0];
    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColorSelected = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }

    tintColorSelected = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:TRUE] : tintColorSelected;
    tintColorNormal = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:FALSE] : tintColorNormal;
    tintColorDisabled = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColorDisabled] : tintColorDisabled;

  if(selected) selected = [selected tintedImageUsingColor:tintColorSelected alpha:1.0];
  if(image) image = [image tintedImageUsingColor:tintColorNormal alpha:1.0];
  return %orig(image,selected,arg3,arg4);
}

+ (id)_defaultLabelColor{
      //if(!shouldLoadHookGroup(@"UITabBarHooks")) return %orig;
  return [UIColor colorWithRed:100.0/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0];
}



%end


@interface UITabBarItem (Private)
@property(retain, nonatomic) UIImage *unselectedImage;
@property(retain, nonatomic) UIImage *selectedImage;
@end




%hook UITabBarItem

%new
-(void)tintBackgroundImages{
 // NSLog(@"GD7UIDEBUG: UITabBarItem - tintBackgroundImages called");
   

UIColor *tintColorSelected = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];

    UIColor *tintColorNormal = [UIColor colorWithRed:100/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0];
    UIColor *tintColorDisabled = [UIColor colorWithRed:160/255.0 green:160.0/255.0 blue:160.0/255.0 alpha:1.0];
    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColorSelected = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }

    tintColorSelected = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:TRUE] : tintColorSelected;
    tintColorNormal = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColor:FALSE] : tintColorNormal;
    tintColorDisabled = (gduiController && dynamicInterfaceEnabled) ? [gduiController barButtonItemTintColorDisabled] : tintColorDisabled;


          NSDictionary *selectedStateDict = @{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColorSelected,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               };

  
     NSDictionary *normalStateDict = @{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColorNormal,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               };
      NSDictionary *disabledStateDict = @{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColorDisabled,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               };
 
  [self setTitleTextAttributes:selectedStateDict forState:UIControlStateSelected];
  [self setTitleTextAttributes:disabledStateDict forState:UIControlStateDisabled];
  [self setTitleTextAttributes:normalStateDict forState:UIControlStateNormal];

if(self.image){
 // NSLog(@"HAS TABBAR IMAGE DAMMIT");
  self.image = [self.image tintedImageUsingColor:tintColorSelected alpha:1.0];
}


}

- (id)initWithCoder:(id)arg1{
      //if(!shouldLoadHookGroup(@"UITabBarHooks")) return %orig;
    self = %orig;
  if(self){
    //NSLog(@"initWithCoder CALLED BLOODY HELL");
    [self tintBackgroundImages];
  }
  return self;
}

- (id)initWithTabBarSystemItem:(int)arg1 tag:(int)arg2{
      //if(!shouldLoadHookGroup(@"UITabBarHooks")) return %orig;
      self = %orig;
  if(self){
    //NSLog(@"initWithTabBarSystemItem CALLED BLOODY HELLL");
 [self tintBackgroundImages];

  }
  return self;
}

- (id)initWithTitle:(id)arg1 image:(UIImage*)arg2 tag:(int)arg3{
      //if(!shouldLoadHookGroup(@"UITabBarHooks")) return %orig;
        self = %orig;
  if(self){
   // NSLog(@"initWithTitle CALLED BLOODY HELL");
   [self tintBackgroundImages];
 
     //arg2 = [arg2 tintedImageUsingColor:[UIColor blackColor] alpha:1.0];
  }
  return self;
}

-(id)init{
      //if(!shouldLoadHookGroup(@"UITabBarHooks")) return %orig;
  self = %orig;
  if(self){
   // NSLog(@"INIT CALLED BLOODY HELL");

 [self tintBackgroundImages];
  }
  return self;
}

%end


%end


%group UISegmentedControlHooks

%hook UISegmentedControl


- (void)_backgroundColorUpdated {
      //if(!shouldLoadHookGroup(@"UISegmentedControlHooks")){ %orig; return;}
  NSLog(@"UISegmentedControl _backgroundColorUpdated");
    if ([self titleTextAttributesForState:UIControlStateSelected]) { //if i customize a new style, no need to update this.
        return;
    }
//    NSDictionary *selectedAttributes = @{UITextAttributeTextColor: self.stackedBackgroundColor};
    UIColor *tintColor = self.tintColor;
    if ([self.tintColor isEqual:[UIColor whiteColor]] || [self.tintColor isEqual:[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f]] || [self.tintColor isEqual:[UIColor colorWithWhite:1.0f alpha:1.0f]]) {
        tintColor = [UIColor blackColor];
    }
    NSDictionary *selectedAttributes = @{UITextAttributeTextColor: tintColor};//if tintColor is white, then set selectedColor to darkTextColor

    [self setTitleTextAttributes:selectedAttributes forState:UIControlStateSelected];
}

%new
-(void)gdUIPatch{

   if ([self titleTextAttributesForState:UIControlStateSelected] && [self titleTextAttributesForState:UIControlStateNormal]) { //if i customize a new style, no need to update this.
        return;
    }


  /*
UIImage *normalImage = [self dividerImageForLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
normalImage = [normalImage tintedImageUsingColor:[UIColor greenColor] alpha:1.0];
[self setDividerImage:normalImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
 */
    UIColor *tintColorSelected = [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0];

    UIColor *tintColorNormal = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];
    UIColor *tintColorDisabled = [UIColor colorWithRed:160/255.0 green:160.0/255.0 blue:160.0/255.0 alpha:1.0];
    if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
       tintColorNormal = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
    }

    tintColorSelected = (gduiController && dynamicInterfaceEnabled) ? [gduiController uisegmentControlLabelTintColor:TRUE] : tintColorSelected;
    tintColorNormal = (gduiController && dynamicInterfaceEnabled) ? [gduiController uisegmentControlLabelTintColor:FALSE] : tintColorNormal;
    tintColorDisabled = (gduiController && dynamicInterfaceEnabled) ? [gduiController uisegmentControlLabelTintColorDisabled] : tintColorDisabled;

      NSDictionary *normal = @{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColorNormal,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               };

        [self setTitleTextAttributes:normal forState:UIControlStateNormal];

              NSDictionary *selected = @{
                               UITextAttributeTextShadowColor: [UIColor clearColor],
                               UITextAttributeTextColor:tintColorSelected,
                               UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetZero],
                               };

        [self setTitleTextAttributes:selected forState:UIControlStateSelected];


       UIImage *backgroundImageNormal = [self backgroundImageForState:UIControlStateNormal barMetrics:[self barStyle]];
       UIImage *backgroundImageSelected = [self backgroundImageForState:UIControlStateSelected barMetrics:[self barStyle]];

       if(!backgroundImageNormal){
          [self _setBackgroundImage:[UIImage imageWithColor:tintColorSelected] forState:UIControlStateNormal barMetrics:[self barStyle]];
       }
       else{
        [self setBackgroundImage:[backgroundImageNormal tintedImageUsingColor:tintColorSelected alpha:1.0] forState:UIControlStateNormal barMetrics:[self barStyle]];
      }
       
      if(!backgroundImageSelected){
        [self _setBackgroundImage:[UIImage imageWithColor:tintColorNormal] forState:UIControlStateSelected barMetrics:[self barStyle]];
      }else{
        [self setBackgroundImage:[backgroundImageSelected tintedImageUsingColor:tintColorNormal alpha:1.0] forState:UIControlStateNormal barMetrics:[self barStyle]];
      }


      UIImage *dividerImageNormal = [self dividerImageForLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:[self barStyle]];
    
      if(!dividerImageNormal){
        [self _setDividerImage:[UIImage imageWithColor:tintColorSelected] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:[self barStyle]];
      } 
      else{
        [self setDividerImage:[dividerImageNormal tintedImageUsingColor:tintColorNormal alpha:1.0] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:[self barStyle]]; 
      }
 
}

-(void)layoutSubviews{
       //if(!shouldLoadHookGroup(@"UISegmentedControlHooks")){ %orig; return;}
  %orig;
  [self gdUIPatch];
  //self.tintColor = [UIColor redColor];
 // [self _tintColorUpdated];
}

%end


%hook UISegment

-(void)setTintColor:(UIColor*)color{
       //if(!shouldLoadHookGroup(@"UISegmentedControlHooks")){ %orig; return;}
if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
    color = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
}
else{
   color = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];
}
%orig;
}

-(void)_updateTextColors{
       //if(!shouldLoadHookGroup(@"UISegmentedControlHooks")){ %orig; return;}
   %orig;
   
  for (UIView *subview in [self subviews]) {
    if ([subview isKindOfClass:[UILabel class]] || [subview isMemberOfClass:[UILabel class]] || [subview isMemberOfClass:[objc_getClass("UISegmentLabel") class]]) {
        UILabel *label=(UILabel *)subview;
        label.shadowColor = [UIColor clearColor];
        if(!self.selected){
        if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
            label.textColor = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
        }
        else{
            label.textColor = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];
        }
    }
    else{
       label.textColor = [UIColor colorWithRed:240/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];
    }
    }
}  

}


-(id)initWithInfo:(id)info style:(int)style size:(int)size barStyle:(int)style4 tintColor:(UIColor*)color position:(unsigned)position isDisclosure:(BOOL)disclosure autosizeText:(BOOL)text{
     //if(!shouldLoadHookGroup(@"UISegmentedControlHooks")) return %orig;
self = %orig;
if(self){
if([[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobiletimer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-MediaPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod-AudioPlayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"Music"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobileipod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilemusicplayer"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"iPod"] || [[[UIApplication sharedApplication] displayIdentifier] isEqualToString:@"com.apple.mobilecal"]){
    color = [UIColor colorWithRed:255.0/255.0 green:48.0/255.0 blue:83.0/255.0 alpha:1.0];
}
else{
   color = [UIColor colorWithRed:42.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:1.0];
}

}
return self;
}

%end

%end


static void loadPrefs() {
  NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.greyd00r.gd7ui.plist"];
  NSLog(@"GD7UIDEBUGY: loadPrefs - called");

  debug = [settings objectForKey:@"debug"] ? [[settings objectForKey:@"debug"] boolValue] : NO;
  if(!(objc_getClass("SpringBoard") == NULL)) iconAnimations = [settings objectForKey:@"iconAnimations"] ? [[settings objectForKey:@"iconAnimations"] boolValue] : NO;
   if(!(objc_getClass("SpringBoard") == NULL)) replaceLinen = [settings objectForKey:@"replaceLinen"] ? [[settings objectForKey:@"replaceLinen"] boolValue] : TRUE;
   if(!(objc_getClass("SpringBoard") == NULL)) blurDock = [settings objectForKey:@"blurDock"] ? [[settings objectForKey:@"blurDock"] boolValue] : TRUE;
   if(!(objc_getClass("SpringBoard") == NULL)) resizeIcons = [settings objectForKey:@"resizeIcons"] ? [[settings objectForKey:@"resizeIcons"] boolValue] : TRUE;
   if(!(objc_getClass("SpringBoard") == NULL)) iconResizeType = [settings objectForKey:@"iconResizeType"] ? [[settings objectForKey:@"iconResizeType"] intValue] : 1;
   if(!(objc_getClass("SpringBoard") == NULL)) iconScaleSize = [settings objectForKey:@"iconScaleSize"] ? [[settings objectForKey:@"iconScaleSize"] floatValue] : 1.1;
   if(!(objc_getClass("SpringBoard") == NULL)) iconResizeAddition = [settings objectForKey:@"iconResizeAddition"] ? [[settings objectForKey:@"iconResizeAddition"] floatValue] : 0;
   if(!(objc_getClass("SpringBoard") == NULL)) allowIconDenyResize = [settings objectForKey:@"allowIconDenyResize"] ? [[settings objectForKey:@"allowIconDenyResize"] boolValue] : FALSE;
   if(!(objc_getClass("SpringBoard") == NULL)){
    iconDenyResizeList = ([settings objectForKey:@"iconDenyResizeList"] && allowIconDenyResize) ? [[settings objectForKey:@"iconDenyResizeList"] copy] : nil;
   } 


   themeOverrideDict = [settings objectForKey:@"themeOverrideList"] ? [[settings objectForKey:@"themeOverrideList"] copy] : nil;

   dynamicInterfaceEnabled = [settings objectForKey:@"dynamicInterfaceEnabled"] ? [[settings objectForKey:@"dynamicInterfaceEnabled"] boolValue] : FALSE;
  if([[NSFileManager defaultManager] fileExistsAtPath:lsPrefsPath]){
NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:lsPrefsPath];
iOSLSEnabled = [prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : FALSE;

[prefs release];
}
  [settings release];
}
 
%group fallbackHookGroup
%hook SBAwayView 
-(id)initWithFrame:(CGRect)frame{
  self = %orig;
  if(self){
  if(!isSlothAlive()){ //The best I can do I guess. bad when it starts to have white backgrounds for popups if it's via file changes though. probably not I guess because I'll do my magic blur code on them anyway so why edit the image?
    alertIfNeeded();
  }
  }
  return self;
}
%end


%end


#define UI7SwitchWidthDefault 51.0f
#define UI7SwitchHeightDefault 31.0f
#define UI7SwitchSizeDefault CGSizeMake(UI7SwitchWidthDefault, UI7SwitchHeightDefault)

%group UISwitchHooks
%hook UISwitch

-(id)init{
  return %orig;
  return [[SevenSwitch alloc] init];
}

-(id)initWithFrame:(CGRect)frame{
  return %orig;
  return [[SevenSwitch alloc] initWithFrame:frame];
}

%end

%end


%ctor{

if(!gduiController && !interfaceLoaded && dynamicInterfaceEnabled){
  REDLog(@"GD7UIDEBUG: Loading gduiController");
  gduiController = [[GDUIController alloc] init];
  REDLog(@"GD7UIDEBUG: Loaded gduiController - now attempting to load interface");
  [gduiController loadInterface];
  REDLog(@"GD7UIDEBUG: gduiController - Loaded interface.");
}




NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
loadPrefs();
  if(!(objc_getClass("SpringBoard") == NULL)) CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.greyd00r.gd7ui.prefsChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
  if(isSlothAlive()){ //The best I can do I guess. bad when it starts to have white backgrounds for popups if it's via file changes though. probably not I guess because I'll do my magic blur code on them anyway so why edit the image?
    %init(hookGroup);

      //if(objc_getClass("SpringBoard") == NULL){
        NSLog(@"Checking what should be loaded");
        if(shouldLoadHookGroup(@"UISegmentedControlHooks")){
          %init(UISegmentedControlHooks);
        } 
        if(shouldLoadHookGroup(@"UINavigationBarHooks")){
          %init(UINavigationBarHooks);
        }
        if(shouldLoadHookGroup(@"UIBarHooks")){
          %init(UIBarHooks);
        }
        if(shouldLoadHookGroup(@"UIToolbarHooks")){
          %init(UIToolbarHooks);
        }
        if(shouldLoadHookGroup(@"UITabBarHooks")){
          %init(UITabBarHooks);
        }
        if(shouldLoadHookGroup(@"UIPSTableHooks")){
          %init(UIPSTableHooks);
        }
        if(shouldLoadHookGroup(@"UIAlertViewHooks")){
          %init(UIAlertViewHooks);
        }
        if(!shouldLoadHookGroup(@"UISwitchHooks")){
          if(false) %init(UISwitchHooks); //FIXME: uncomment this when the old UI tweak is no longer needed
        }
      //}

  


      

     
  }
  else{
    %init(fallbackHookGroup);
  }



/*
else{
NSMutableDictionary *prefs = [[NSMutableDictionary alloc] init];
[prefs setObject:@"Example 1" forKey:@"lockscreenName"];
[prefs setObject:[NSNumber numberWithBool:TRUE] forKey:@"enabled"];


[prefs writeToFile:lsPrefsPath atomically:YES];
[prefs release];
}
*/

[pool drain];
}