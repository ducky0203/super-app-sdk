#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SuperAppDataChangedEvent;
extern NSString *const SuperAppBridgeEvent;
extern NSString *const SuperAppRoleKey;

@interface SuperAppDataStore : NSObject

+ (instancetype)shared;

- (void)setObject:(NSString *)value forKey:(NSString *)key;
- (nullable NSString *)objectForKey:(NSString *)key;
- (BOOL)removeObjectForKey:(NSString *)key;
- (NSDictionary<NSString *, NSString *> *)allObjects;
- (void)clear;

- (void)setRole:(NSString *)role;
- (nullable NSString *)role;

- (void)mergeDictionary:(NSDictionary<NSString *, NSString *> *)dict;
- (void)emitBridgeEventWithName:(NSString *)eventName payloadJson:(nullable NSString *)payloadJson;

@end

NS_ASSUME_NONNULL_END
