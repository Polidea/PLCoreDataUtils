/*
 Copyright (c) 2012, Antoni Kędracki, Polidea
 All rights reserved.
 
 mailto: akedracki@gmail.com
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the Polidea nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY ANTONI KĘDRACKI, POLIDEA ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL ANTONI KĘDRACKI, POLIDEA BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PLContextHolder.h"

@interface PLContextHolder ()

- (void)mergeChangesIntoMainContext:(NSNotification *)notification;

@end

@implementation PLContextHolder {
    NSThread *_contextThread;
    dispatch_queue_t _privateQueue;
    NSManagedObjectContext *_context;
    PLContextHolder *_parentHolder;
}

+ (id)holderAsChild:(PLContextHolder *)parentHolder {
    return [[PLContextHolder alloc] initAsChild:parentHolder];
}

+ (id)holderWithPrivateQueueAsChild:(PLContextHolder *)parentHolder {
    return [[PLContextHolder alloc] initWithPrivateQueueAsChild:parentHolder];
}

+ (id)holderInContext:(NSManagedObjectContext *)context {
    return [[PLContextHolder alloc] initInContext:context];
}

- (id)initAsChild:(PLContextHolder *)parentHolder {
    self = [super init];
    if (self) {
        if (parentHolder == nil) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"a parent holder must have been provided"
                                         userInfo:nil];
        }

        _parentHolder = parentHolder;
    }
    return self;
}

- (id)initWithPrivateQueueAsChild:(PLContextHolder *)parentHolder {
    self = [super init];
    if (self) {
        if (parentHolder == nil) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"a parent holder must have been provided"
                                         userInfo:nil];
        }

        _parentHolder = parentHolder;

        _privateQueue = dispatch_queue_create(NULL, NULL);
        dispatch_sync(_privateQueue, ^{
            [self context];
        });
    }
    return self;
}

- (id)initInContext:(NSManagedObjectContext *)context {
    self = [super init];
    if (self) {
        if (context == nil) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"a _context must have been provided"
                                         userInfo:nil];
        }

        _context = context;
        _contextThread = [NSThread currentThread];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _privateQueue = nil;
}

- (void)mergeChangesIntoMainContext:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil) {
        NSLog(@"PLContextHolder: merge notification is empty");
    }
    [_parentHolder.context performSelector:@selector(mergeChangesFromContextDidSaveNotification:)
                                  onThread:_parentHolder.contextThread
                                withObject:notification
                             waitUntilDone:YES];
}

- (NSThread *)contextThread {
    return _contextThread;
}

- (NSManagedObjectContext *)context {
    if (![self isContextLoaded]) {
        _contextThread = [NSThread currentThread];

        _context = [[NSManagedObjectContext alloc] init];
        [_context setUndoManager:nil];
        [_context setPersistentStoreCoordinator:[_parentHolder.context persistentStoreCoordinator]];
        [_context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(mergeChangesIntoMainContext:)
                   name:NSManagedObjectContextDidSaveNotification
                 object:_context];
    }

    return _context;
}

- (BOOL)isContextLoaded {
    return _context != nil;
}

- (BOOL)hasPrivateQueue {
    return _privateQueue != nil;
}

- (void)performBlock:(void (^)())block {
    if (_privateQueue == nil) {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"performBlock: can only be called on _context holders that have a private queue" userInfo:nil];
    }
    dispatch_async(_privateQueue, block);
}

- (void)performBlockAndWait:(void (^)())block {
    if (_privateQueue == nil) {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"performBlockAndWait: can only be called on _context holders that have a private queue" userInfo:nil];
    }
    dispatch_sync(_privateQueue, block);
}


@end
