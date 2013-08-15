//
//  JTACIFilter.h
//  ApplyCIKernel
//
//  Created by James Snook on 14/08/2013.
//  Copyright (c) 2013 James Snook. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface JTACIFilter : CIFilter

- (id)initWithCIKernelFile:(NSString *)kernelFile;
- (void)addImage:(CIImage *)image;
- (void)addArgument:(id)arg;

@end
