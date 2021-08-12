#import "IProovSDKPlugin.h"
#if __has_include(<iproov_flutter/iproov_flutter-Swift.h>)
#import <iproov_flutter/iproov_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "iproov_flutter-Swift.h"
#endif

@implementation IProovSDKPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftIProovSDKPlugin registerWithRegistrar:registrar];
}
@end
