//
//  IQEngines.m
//  
//
//  Created by Paul Thorsteinson (paul@bnid.ca) & Michael J.Sikorsky (mj@robotsandpencils.com) on 10-07-05.
//  Copyright 2010 Big Nerds In Disguise & Robots and Pencils Inc. All rights reserved.
//

#import "IQEngines.h"
#import <CommonCrypto/CommonHMAC.h>
#import "ASIFormDataRequest.h"
#import "IQResult.h"
#import "UIImage+Resize.h"


// to be safe we will aim to scale a few pixels under 640, the max limit for the API	
#define kMaxPixels 636.0

// list methods that you don't want to be visible (pseudo private)
@interface IQEngines()

- (NSString *)hmacSha1:(NSString *)data;
- (NSString *)stringWithHexBytes:(NSData *)encryptedData;
- (NSString *)getUTCFormatedDate;
- (UIImage *)sizedImageToSpecs:(UIImage *)image;
- (void)doAsyncCheckRequest;
- (void)processResults:(NSArray *)results;
- (NSString *)stringValueOrBlank:(id)value;
- (IQResult *)findRequestBySignature:(NSString *)signature;
@end


@implementation IQEngines
@synthesize key, secret, pendingRequests, delegate, parser,updatePollDelayInSeconds;

#pragma mark Lifecycle

- (id)initWithKey:(NSString *)yourKey andSecret:(NSString *)yourSecret
{
	if (self == [super init]) {
		self.key = yourKey;
		self.secret = yourSecret;
		self.pendingRequests = [[NSMutableArray alloc] init];
		self.parser = [[SBJSON alloc] init];
		requestCounter = 0;
		updatePollDelayInSeconds = 3;
	}
	
	return self;
}

- (void)dealloc
{
	[key release];
	[secret release];
	[pendingRequests release];
	[parser release];
	[super dealloc];
}

#pragma mark Image Submission and polling

- (NSString *)submitImageToIdentify:(UIImage *)image
{	
	requestCounter++;
	
	// first lets make sure this bad boy is sized within limits
	UIImage *resizedImage = [self sizedImageToSpecs:image];
	
	NSString *utcTimestampString = [self getUTCFormatedDate];
	NSString *imgName = [NSString stringWithFormat:@"image#%d.jpg", requestCounter];
	// note parameters must be ordered alphabetically
	NSString *joinedParams = [NSString stringWithFormat:@"api_key%@img%@json1time_stamp%@", self.key, imgName, utcTimestampString];
	
	//NSLog(@"Params list %@", joinedParams);
	
	NSString *apiSig = [[self hmacSha1:joinedParams] lowercaseString]; 
	NSURL *url = [NSURL URLWithString:@"http://api.iqengines.com/v1.2/query/"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	request.timeOutSeconds = 90;
	[request setPostValue:self.key forKey:@"api_key"];
	[request setPostValue:apiSig forKey:@"api_sig"];
	
	NSData *imgData = UIImageJPEGRepresentation(resizedImage, 0);	
	[request setPostValue:imgData forKey:@"img"];
	[request setData:imgData withFileName:imgName andContentType:@"image/jpeg" forKey:@"img"];
	
	
	[request setPostValue:@"1" forKey:@"json"];
	[request setPostValue:utcTimestampString forKey:@"time_stamp"];	
	request.delegate = self;
	
	IQResult *newRequest = [[IQResult alloc] initWithSignature:apiSig];
	[pendingRequests addObject:newRequest];
	[newRequest release];
	[request startAsynchronous];
	
	NSLog(@"submitting image request: %@", apiSig);
	
	return apiSig;
	
}

// ensures image is < 640px in height and width, resizes proportionatly if needed
- (UIImage *)sizedImageToSpecs:(UIImage *)image
{	
	
	int width = image.size.width;
	int height = image.size.height;
	
	// it is already within limits so return what was passed in
	if (width < 640 && height < 640 ) {
		return image; 
	}
	
	// at least one size is over the limit, resize based on largest side
	double adjustFactor;
	if (width < height) {
		//its height is bigger, bring it under limit
		adjustFactor = (double)  kMaxPixels / height;
	}else {
		//its width is bigger, bring it under limits
		adjustFactor = (double)  kMaxPixels / width;
	}
	
	// maintain aspect
	CGSize newSize; 
	newSize.height = height * adjustFactor;
	newSize.width = width * adjustFactor;
	
	//NSLog(@"Original w: %f   h: %f   (new) w: %f   h: %f", width, height, newSize.width, newSize.height);
	
	return [image resizedImage:newSize interpolationQuality:kCGInterpolationHigh];
}

- (void)doAsyncCheckRequest
{
	// update
	NSURL *url = [NSURL URLWithString:@"http://api.iqengines.com/v1.2/update/"];
	NSString *utcTimestampString = [self getUTCFormatedDate];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	request.timeOutSeconds = 90;
	NSString *joinedParams = [NSString stringWithFormat:@"api_key%@json1time_stamp%@", self.key, utcTimestampString];
	NSString *apiSig = [self hmacSha1:joinedParams];
	[request setPostValue:self.key forKey:@"api_key"];
	[request setPostValue:apiSig forKey:@"api_sig"];	
	[request setPostValue:@"1" forKey:@"json"];
	[request setPostValue:utcTimestampString forKey:@"time_stamp"];	
	request.delegate = self;
	NSLog(@"Checking on image requests, %d pending", [pendingRequests count]);
	[request startAsynchronous];
	
}

#pragma mark ASIHTTPRequest delegate methods

- (void)requestFinished:(ASIHTTPRequest *)request{
	// Use when fetching text data
	NSString *responseString = [request responseString];
	NSLog(@"Response %@", responseString);	
	
	NSDictionary *rootLevel = [parser objectWithString:responseString];
	NSDictionary *dataLevel = [rootLevel objectForKey:@"data"];
	NSNumber *errorNo = [dataLevel objectForKey:@"error"];
		
	
	if ([errorNo intValue] != 0) {
		NSString *message = [dataLevel objectForKey:@"comment"];
		// at this point we will abort any image id attempts since we dont know which failed
		[pendingRequests removeAllObjects];
		if (delegate != nil) {
			[delegate iQRequestFailed:message];
		}
		
		return;
	}
	
	[self processResults:[dataLevel objectForKey:@"results"]];

	
	if ([pendingRequests count] > 0) {
		[self performSelector:@selector(doAsyncCheckRequest) withObject:nil afterDelay:updatePollDelayInSeconds];
	}
		
}

- (void)requestFailed:(ASIHTTPRequest *)request{
	NSError *error = [request error];
	if ([error code] == 2) {
		[request startAsynchronous];
	}
	NSLog(@"failed: %@", [error description]);
}

- (void)processResults:(NSArray *)results{
	
	if (results == nil) {
		return;
	}
	
	for (NSDictionary *dict in results) {
		NSString *sig = [dict objectForKey:@"qid"];
		NSDictionary *properties = [dict objectForKey:@"qid_data"];
		IQResult *result = [self findRequestBySignature:sig];
		if (result != nil) {
			result.color = [self stringValueOrBlank:[properties objectForKey:@"color"]];
			result.isbn = [self stringValueOrBlank:[properties objectForKey:@"isbn"]];
			result.labels = [self stringValueOrBlank:[properties objectForKey:@"labels"]];
			result.sku = [self stringValueOrBlank:[properties objectForKey:@"sku"]];
			result.upc = [self stringValueOrBlank:[properties objectForKey:@"upc"]];
			result.url = [self stringValueOrBlank:[properties objectForKey:@"url"]];
			[pendingRequests removeObject:result];
			[delegate requestSucceeded:result];			
		}		
	}
	
}

- (IQResult *)findRequestBySignature:(NSString *)signature{
	
	NSArray *matches = [pendingRequests filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"signature = %@",signature]];
	
	if ([matches count] == 1) {
		return (IQResult *) [matches objectAtIndex:0];
	}else {
		return nil;
	}

}


- (NSString *)stringValueOrBlank:(id)value{

	if(value == nil){
		return @"";
	}else {
		return (NSString *)value;
	}

}

- (NSString *)hmacSha1:(NSString *)data
{
	
	const char *cKey  = [self.secret cStringUsingEncoding:NSASCIIStringEncoding];
	const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
	
	unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
	
	CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
	
	NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
										  length:sizeof(cHMAC)];
	
	NSString *hash =  [self stringWithHexBytes:HMAC];
	
	[HMAC release];
	
	return hash;
}

- (NSString *) stringWithHexBytes:(NSData *)encryptedData 
{
	NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([encryptedData length] * 2)];
	const unsigned char *dataBuffer = [encryptedData bytes];
	int i;
	for (i = 0; i < [encryptedData length]; ++i) {
		[stringBuffer appendFormat:@"%02X", (unsigned long)dataBuffer[i]];
	}
	
	return [stringBuffer lowercaseString];
}

- (NSString *)getUTCFormatedDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
	[dateFormatter release];
    return dateString;
}
							   
							   

@end
