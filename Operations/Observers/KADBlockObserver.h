//
//  KADBlockObserver.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 01.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KADOperationObserver.h"

@interface KADBlockObserver : NSObject <KADOperationObserver>
-(instancetype)initWithStartHandler:(void(^)(KADOperation *))startHandler
                     produceHandler:(void(^)(KADOperation *, NSOperation *))produceHandler
                      finishHandler:(void(^)(KADOperation *, NSArray *))finishHandler;

@end
