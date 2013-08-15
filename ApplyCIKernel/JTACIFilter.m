//
//  JTACIFilter.m
//  ApplyCIKernel
//
//  Created by James Snook on 14/08/2013.
//  Copyright (c) 2013 James Snook. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "JTACIFilter.h"

@implementation JTACIFilter
{
  CIKernel *kernel;
  NSMutableArray *arguments;
}

- (id)initWithCIKernelFile:(NSString *)kernelFile
{
  if ((self = [super init])) {
    arguments = [NSMutableArray array];
    NSError *error = nil;
    NSString *fullName = [kernelFile stringByExpandingTildeInPath];
    NSArray *kernels = [CIKernel kernelsWithString:[NSString stringWithContentsOfFile:fullName
                                                                             encoding:NSUTF8StringEncoding
                                                                                error:&error]];
    if (error) {
      printf ("couldn't read the CIKernel file");
      return nil;
    }
    
    kernel = [kernels objectAtIndex:0];
  }
  
  return self;
}

- (void)addImage:(CIImage *)image
{
  CISampler *sampler = [CISampler samplerWithImage:image];
  [arguments addObject:sampler];
}

- (void)addArgument:(id)arg
{
  [arguments addObject:arg];
}

- (CIImage *)outputImage
{
  //[arguments addObject:kCIApplyOptionDefinition];
  return [self apply:kernel arguments:arguments options:nil];
}

@end
