

/// Wraps `object_getClass` but accepts a `Class` parameter instead of `id`.
/// Stops Swift crashing while attempting to release classes like `__NSGenericDeallocHandler`.
Class class_getMetaclass(Class c);
