#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#import "SuperAppDataStore.h"

@interface SuperAppBridge : RCTEventEmitter <RCTBridgeModule>
@end

@implementation SuperAppBridge {
  BOOL _observing;
}

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

- (instancetype)init
{
  if (self = [super init]) {
    [self startObserving];
  }
  return self;
}

- (void)dealloc
{
  [self stopObserving];
}

- (void)startObserving
{
  if (_observing) {
    return;
  }
  _observing = YES;
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(onDataChanged:)
                 name:SuperAppDataChangedEvent
               object:nil];
  [center addObserver:self
             selector:@selector(onBridgeEvent:)
                 name:SuperAppBridgeEvent
               object:nil];
}

- (void)stopObserving
{
  if (!_observing) {
    return;
  }
  _observing = NO;
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center removeObserver:self name:SuperAppDataChangedEvent object:nil];
  [center removeObserver:self name:SuperAppBridgeEvent object:nil];
}

- (void)onDataChanged:(NSNotification *)notification
{
  [self sendEventWithName:SuperAppDataChangedEvent body:notification.userInfo];
}

- (void)onBridgeEvent:(NSNotification *)notification
{
  [self sendEventWithName:SuperAppBridgeEvent body:notification.userInfo];
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[ SuperAppDataChangedEvent, SuperAppBridgeEvent ];
}

- (NSDictionary *)constantsToExport
{
  return @{@"ROLE_KEY" : SuperAppRoleKey};
}

RCT_EXPORT_METHOD(setItem : (NSString *)key value : (NSString *)value resolver : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject)
{
  if (key.length == 0) {
    reject(@"INVALID_KEY", @"key must not be empty", nil);
    return;
  }
  [[SuperAppDataStore shared] setObject:value forKey:key];
  resolve(nil);
}

RCT_EXPORT_METHOD(getItem : (NSString *)key resolver : (RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject)
{
  if (key.length == 0) {
    reject(@"INVALID_KEY", @"key must not be empty", nil);
    return;
  }
  resolve([[SuperAppDataStore shared] objectForKey:key]);
}

RCT_EXPORT_METHOD(removeItem : (NSString *)key resolver : (RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject)
{
  resolve(@([[SuperAppDataStore shared] removeObjectForKey:key]));
}

RCT_EXPORT_METHOD(getAllItems : (RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject)
{
  resolve([[SuperAppDataStore shared] allObjects]);
}

RCT_EXPORT_METHOD(clear : (RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject)
{
  [[SuperAppDataStore shared] clear];
  resolve(nil);
}

RCT_EXPORT_METHOD(setRole : (NSString *)role resolver : (RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject)
{
  [[SuperAppDataStore shared] setRole:role];
  resolve(nil);
}

RCT_EXPORT_METHOD(getRole : (RCTPromiseResolveBlock)resolve rejecter : (RCTPromiseRejectBlock)reject)
{
  resolve([[SuperAppDataStore shared] role]);
}

RCT_EXPORT_METHOD(emitEvent : (NSString *)eventName payloadJson : (NSString *)payloadJson resolver : (RCTPromiseResolveBlock)
                      resolve rejecter : (RCTPromiseRejectBlock)reject)
{
  if (eventName.length == 0) {
    reject(@"INVALID_EVENT", @"eventName must not be empty", nil);
    return;
  }
  [[SuperAppDataStore shared] emitBridgeEventWithName:eventName payloadJson:payloadJson];
  resolve(nil);
}

RCT_EXPORT_METHOD(addListener : (NSString *)eventName)
{
}

RCT_EXPORT_METHOD(removeListeners : (double)count)
{
}

@end
