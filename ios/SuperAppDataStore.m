#import "SuperAppDataStore.h"

NSString *const SuperAppDataChangedEvent = @"SuperAppDataChanged";
NSString *const SuperAppBridgeEvent = @"SuperAppEvent";
NSString *const SuperAppRoleKey = @"__super_app_role__";

@interface SuperAppDataStore ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *data;
@end

@implementation SuperAppDataStore

+ (instancetype)shared
{
  static SuperAppDataStore *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[SuperAppDataStore alloc] init];
  });
  return instance;
}

- (instancetype)init
{
  if (self = [super init]) {
    _data = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)setObject:(NSString *)value forKey:(NSString *)key
{
  @synchronized(self) {
    self.data[key] = value;
  }
  [self postDataChangedWithKey:key value:value];
}

- (NSString *)objectForKey:(NSString *)key
{
  @synchronized(self) {
    return self.data[key];
  }
}

- (BOOL)removeObjectForKey:(NSString *)key
{
  BOOL removed = NO;
  @synchronized(self) {
    removed = self.data[key] != nil;
    [self.data removeObjectForKey:key];
  }
  if (removed) {
    [self postDataChangedWithKey:key value:nil];
  }
  return removed;
}

- (NSDictionary<NSString *, NSString *> *)allObjects
{
  @synchronized(self) {
    return [self.data copy];
  }
}

- (void)clear
{
  @synchronized(self) {
    [self.data removeAllObjects];
  }
  [self postDataChangedWithKey:nil value:nil];
}

- (void)setRole:(NSString *)role
{
  [self setObject:role forKey:SuperAppRoleKey];
}

- (NSString *)role
{
  return [self objectForKey:SuperAppRoleKey];
}

- (void)mergeDictionary:(NSDictionary<NSString *, NSString *> *)dict
{
  @synchronized(self) {
    [self.data addEntriesFromDictionary:dict];
  }
  [self postDataChangedWithKey:nil value:nil];
}

- (void)emitBridgeEventWithName:(NSString *)eventName payloadJson:(NSString *)payloadJson
{
  NSMutableDictionary *body = [NSMutableDictionary dictionary];
  body[@"eventName"] = eventName;
  if (payloadJson != nil) {
    body[@"payload"] = payloadJson;
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:SuperAppBridgeEvent object:nil userInfo:body];
}

- (void)postDataChangedWithKey:(NSString *)key value:(NSString *)value
{
  NSMutableDictionary *body = [NSMutableDictionary dictionary];
  if (key != nil) {
    body[@"key"] = key;
  }
  if (value != nil) {
    body[@"value"] = value;
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:SuperAppDataChangedEvent
                                                      object:nil
                                                    userInfo:body];
}

@end
