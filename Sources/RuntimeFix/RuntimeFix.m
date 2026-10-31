
#import "RuntimeFix.h"
@import ObjectiveC.runtime;

Class class_getMetaclass(Class c) {
    return object_getClass(c);
}


BOOL NSGetSizeAndAlignmentNoThrow(const char *typePtr, NSUInteger *_Nullable sizep, NSUInteger *_Nullable alignp) {
    @try {
        NSGetSizeAndAlignment(typePtr, sizep, alignp);
        return YES;
    } @catch (NSException *exception) {
        return NO;
    }
}


@implementation NSMethodSignature (RuntimeFix)

+ (nullable NSMethodSignature *)signatureWithObjCTypesNoThrow:(const char *)types {
    @try {
        return [self signatureWithObjCTypes:types];
    } @catch (NSException *exception) {
        return nil;
    }
}

@end
