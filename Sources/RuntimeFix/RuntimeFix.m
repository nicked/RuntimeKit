
#import "RuntimeFix.h"
@import ObjectiveC.runtime;

Class class_getMetaclass(Class c) {
    return object_getClass(c);
}

