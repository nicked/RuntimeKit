
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Wraps `object_getClass` but accepts a `Class` parameter instead of `id`.
/// Stops Swift crashing while attempting to release classes like `__NSGenericDeallocHandler`.
Class class_getMetaclass(Class c);


// Wrap some functions in try/catch (Swift can't catch ObjC exceptions)

/// Calls `NSGetSizeAndAlignment`, but returns `NO` instead of raising an exception.
BOOL NSGetSizeAndAlignmentNoThrow(const char *typePtr, NSUInteger *_Nullable sizep, NSUInteger *_Nullable alignp);


@interface NSMethodSignature (RuntimeFix)
/// Calls `+signatureWithObjCTypes:`, but returns `nil` instead of raising an exception.
+ (nullable NSMethodSignature *)signatureWithObjCTypesNoThrow:(const char *)types;
@end

NS_ASSUME_NONNULL_END
