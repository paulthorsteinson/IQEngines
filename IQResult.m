//
//  IQResult.m
//  GenApiSig
//
//  Created by Paul Thorsteinson (paul@bnid.ca) & Michael J.Sikorsky (mj@robotsandpencils.com) on 10-07-05.
//  Copyright 2010 Big Nerds In Disguise & Robots and Pencils Inc. All rights reserved.
//

#import "IQResult.h"


@implementation IQResult
@synthesize labels;
@synthesize signature;
@synthesize color;
@synthesize sku;
@synthesize upc;
@synthesize url;
@synthesize isbn;

- (id)initWithSignature:(NSString *)sig{
		
	if (self = [super init]) {
		self.labels = @"";
		self.signature = sig;
		self.color = @"";
		self.sku = @"";
		self.upc = @"";
		self.url = @"";
		self.isbn = @"";
	}
	
	return self;
}

- (NSString *)description {
	NSMutableString *tmp = [NSMutableString stringWithString:@""];
	[tmp appendFormat:@"Signature: %@\r\n", self.signature];
	[tmp appendFormat:@"Labels: %@\r\n", self.labels];
	[tmp appendFormat:@"color: %@\r\n", self.color];
	[tmp appendFormat:@"sku: %@\r\n", self.sku];
	[tmp appendFormat:@"upc: %@\r\n", self.upc];
	[tmp appendFormat:@"url: %@\r\n", self.url];
	[tmp appendFormat:@"isbn: %@", self.isbn];
	
	return tmp;
	
}



- (void)dealloc{
	[labels release];
	[signature release];
	[color release];
	[sku release];
	[upc release];
	[url release];
	[isbn release];
	[super dealloc];
}

@end
