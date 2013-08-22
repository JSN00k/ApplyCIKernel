//
//  main.m
//  ApplyCIKernel
//
//  Created by James Snook on 14/08/2013.
//  Copyright (c) 2013 James Snook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#import "JTACIFilter.h"

void usage (void)
{
  printf("ApplyCIKernel -- apply a CIKernel.\n ApplyCIKernel [file (kernel) rgbCol colVal1 colVal2 colVal3 colVal4(opt) "
         "DestinationFile"
         "Image file vec# vecVal1... float floatVal]\n The Arguments given must match, and be in the same order as the kernel expects");
}

int scanNumbersIntoArray (CGFloat *result,
                           int location,
                           int argc,
                           const char **argv,
                           int neededNumsCount,
                           int possibleNumsCount)
{
  if (location + neededNumsCount >= argc)
    return 0;
  
  int scanned;
  for (int i = 0; i < neededNumsCount; ++i) {
    scanned = sscanf (argv[location + i], "%lf", result + i);
    if (!scanned || scanned == EOF)
      return 0;
    
  }

  int extras = possibleNumsCount - neededNumsCount;
  result += neededNumsCount;
  location += neededNumsCount;
  for (int i = 0; i < extras; ++i) {
    if (location + extras >= argc)
      return neededNumsCount + extras;
    
    scanned = sscanf (argv[location + extras], "%lf", result + i);
    
    if (!scanned || scanned == EOF)
      return neededNumsCount + extras;
  }

  return neededNumsCount + possibleNumsCount;
}

int main(int argc, const char * argv[])
{
  /* The least we need is the name of the program and a CIKernel file. */
  if (argc < 2) {
    usage ();
    return -1;
  }
  
  CGContextRef ctx;
  NSGraphicsContext *nsCtx = nil;
  uint32_t *data = nil;
  CGSize imageSize;
  
  NSString *fileString = [NSString stringWithUTF8String:argv[1]];
  JTACIFilter *filter = [[JTACIFilter alloc] initWithCIKernelFile:fileString];

  
  int i = 2;
  while (i < argc - 1) {
    NSString *valueType = [NSString stringWithUTF8String:argv[i]];
    ++i;
    
    if ([valueType isEqualToString:@"Image"]) {
      if (i >= argc) {
        usage();
        return -1;
      }
      
      NSString *stringFileName = [NSString stringWithUTF8String:argv[i]];
      ++i;
      NSImage *image = [[NSImage alloc] initByReferencingFile:[stringFileName stringByStandardizingPath]];
      
      if (!nsCtx) {
        NSImageRep *rep = [[image representations] objectAtIndex:0];
        
        imageSize = CGSizeMake ([rep pixelsWide], [rep pixelsHigh]);
        data = malloc (imageSize.width * imageSize.height * sizeof (uint32_t));
        CGColorSpaceRef rgbSpace = CGColorSpaceCreateDeviceRGB ();
        ctx = CGBitmapContextCreate (data,
                                     imageSize.width,
                                     imageSize.height,
                                     8,
                                     imageSize.width * 4,
                                     rgbSpace,
                                     kCGImageAlphaPremultipliedLast);
        CFRelease (rgbSpace);
        nsCtx = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO];
      }
      
      CIImage *ciimage = [CIImage imageWithCGImage:[image CGImageForProposedRect:NULL
                                                                         context:nsCtx
                                                                           hints:nil]];
      [filter addImage:ciimage];
    } else if ([valueType isEqualToString:@"rgbCol"]) {
      CGFloat rgbVals[4];
      int scanned = scanNumbersIntoArray (rgbVals,
                                          i,
                                          argc,
                                          argv,
                                          3,
                                          4);
      CIColor *col;
      if (scanned < 3) {
        usage ();
        return -1;
      } else if (scanned < 4) {
        i += 3;
        col = [CIColor colorWithRed:rgbVals[0] green:rgbVals[1] blue:rgbVals[2]];
      } else {
        i += 4;
        col = [CIColor colorWithRed:rgbVals[0] green:rgbVals[1]
                               blue:rgbVals[2] alpha:rgbVals[3]];
      }
      
      [filter addArgument:col];
    } else if ([valueType isEqualToString:@"float"] || [valueType isEqualToString:@"vec1"]) {
      CGFloat result;
      if (!scanNumbersIntoArray (&result,
                                 i,
                                 argc,
                                 argv,
                                 1,
                                 0)) {
        ++i;
        usage ();
        return -1;
      }
      
      [filter addArgument:[CIVector vectorWithX:result]];
    i += 1;
  } else if ([valueType isEqualToString:@"vec2"]) {
    CGFloat result[2];
    if (!scanNumbersIntoArray (result,
                               i,
                               argc,
                               argv,
                               2,
                               0)) {
      i += 2;
      usage ();
      return -1;
    }
    
    [filter addArgument:[CIVector vectorWithX:result[0] Y:result[1]]];
  } else if ([valueType isEqualToString:@"vec3"]) {
    CGFloat result[3];
    if (!scanNumbersIntoArray (result,
                               i,
                               argc,
                               argv,
                               3,
                               0)) {
      i += 3;
      usage ();
      return -1;
    }
    
    [filter addArgument:[CIVector vectorWithX:result[0] Y:result[1] Z:result[2]]];
  } else if ([valueType isEqualToString:@"vec4"]) {
    CGFloat result[4];
    if (!scanNumbersIntoArray (result,
                               i,
                               argc,
                               argv,
                               4,
                               0)) {
      i += 4;
      usage ();
      return -1;
    }
    
    [filter addArgument:[CIVector vectorWithX:result[0] Y:result[1] Z:result[2] W:result[3]]];
  } else {
    usage ();
    return -1;
  }
  }
  
  if (!ctx) {
    /* Make a random guess as to the size, this should be improved by letting 
       the user specify, but I can't be bothered. */
    imageSize = CGSizeMake (1024, 1024);
    data = calloc (imageSize.width * imageSize.height, sizeof (uint32_t));
    CGColorSpaceRef rgbSpace = CGColorSpaceCreateDeviceRGB ();
    ctx = CGBitmapContextCreate (data,
                                 imageSize.width,
                                 imageSize.height,
                                 8,
                                 imageSize.width * 4,
                                 rgbSpace,
                                 kCGImageAlphaPremultipliedFirst);
    CFRelease (rgbSpace);
  }
  
  CIContext *ciCtx = [CIContext contextWithCGContext:ctx options:nil];
  CIImage *outputImage = [filter valueForKey:kCIOutputImageKey];
  CGImageRef result = [ciCtx createCGImage:outputImage
                                  fromRect:CGRectMake (0.0, 0.0,
                                                       imageSize.width,
                                                       imageSize.height)];
  free (data);
  
  NSURL *destination = [NSURL fileURLWithPath:[[NSString stringWithUTF8String:argv[i]] stringByStandardizingPath]];
  if (!destination) {
    usage ();
    return -1;
  }
  
  CGImageDestinationRef imageDest = CGImageDestinationCreateWithURL ((__bridge CFURLRef)destination,
                                                                     kUTTypePNG,
                                                                     1,
                                                                     nil);
  CGImageDestinationAddImage (imageDest, result, nil);
  CGImageDestinationFinalize (imageDest);
  CFRelease (imageDest);
  CFRelease (result);
  CFRelease (ctx);
  
  return 0;
}

