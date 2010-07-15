//
//  IQResult.h
//  GenApiSig
//
//  Created by Paul Thorsteinson (paul@bnid.ca) & Michael J.Sikorsky (mj@robotsandpencils.com) on 10-07-05.
//  Copyright 2010 Big Nerds In Disguise & Robots and Pencils Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IQResult : NSObject {
	NSString *labels;
	NSString *signature;
	NSString *color;
	NSString *sku;
	NSString *upc;
	NSString *url;
	NSString *isbn;
}

@property(nonatomic,retain) NSString *labels;
@property(nonatomic,retain) NSString *signature;
@property(nonatomic,retain) NSString *color;
@property(nonatomic,retain) NSString *sku;
@property(nonatomic,retain) NSString *upc;
@property(nonatomic,retain) NSString *url;
@property(nonatomic,retain) NSString *isbn;
- (id)initWithSignature:(NSString *)sig;

@end
