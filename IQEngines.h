//
//  IQEngines.h
//  GenApiSig
//
//  Created by Paul Thorsteinson (paul@bnid.ca) & Michael J.Sikorsky (mj@robotsandpencils.com) on 10-07-05.
//  Copyright 2010 Big Nerds In Disguise & Robots and Pencils Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSON.h"

@class IQResult;

@protocol IQEnginesDelegate

// TODO: change param to proper object
- (void)requestSucceeded:(IQResult *)result;
- (void)requestFailed:(NSString *)errorMessage;
@end



@interface IQEngines : NSObject {
	NSString *key;
	NSString *secret;
	NSMutableArray *pendingRequests;
	id <IQEnginesDelegate> delegate;
	SBJSON *parser;
	int requestCounter;
	int updatePollDelayInSeconds;
}

@property(nonatomic,retain) NSString *key;
@property(nonatomic,retain) NSString *secret;
@property(nonatomic,retain) NSMutableArray *pendingRequests;
@property(nonatomic,assign) id <IQEnginesDelegate> delegate;
@property(nonatomic,retain) SBJSON *parser;
@property(nonatomic) int updatePollDelayInSeconds;
		  
- (id)initWithKey:(NSString *)yourKey andSecret:(NSString *)yourSecret;
- (NSString *)submitImageToIdentify:(UIImage *)image;

@end
