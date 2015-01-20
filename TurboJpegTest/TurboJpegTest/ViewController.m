//
//  ViewController.m
//  TurboJpegTest
//
//  Created by Jeffrey on 15-1-15.
//  Copyright (c) 2015年 Jeffrey. All rights reserved.
//

#import "ViewController.h"
#import "turbojpeg.h"

typedef struct
{
    BOOL isSpecialLoadWidthHeight;
    CGFloat loadWidth;
    CGFloat loadHeight;
} ZLImageLoadOption;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"testimgp"
                                                     ofType:@"jpg"];
    imageView.image = [self turboJpegLoadImage:path];
    [imageView sizeToFit];
    imageView.center = self.view.center;
    [self.view addSubview:imageView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UIImage*)turboJpegLoadImage:(NSString*)imagePath
{
    NSData *data = [NSData dataWithContentsOfFile:imagePath];
    ZLImageLoadOption option;
    option.isSpecialLoadWidthHeight = YES;
    option.loadWidth = 227;
    option.loadHeight = 149;
    CGImageRef img = loadJpegImage((unsigned char*)[data bytes], [data length], option);
    return [UIImage imageWithCGImage:img];
}


static void MyProviderReleaseDataCallback(void *info, const void *data, size_t size)
{
    free((void*)data);
}

static CGImageRef loadJpegImage(unsigned char *jpegBuf,unsigned long jpegSize,ZLImageLoadOption option)
{
    tjhandle handle;
    unsigned char *dstBuf;
    unsigned long dstSize;
    int pitch;
    int pixelFormat;
    int flags;
    int width;
    int height;
    
    handle = tjInitDecompress();
    int jpegSubsamp;
    if (tjDecompressHeader2(handle, jpegBuf, jpegSize, &width, &height, &jpegSubsamp) != 0)
    {
        tjDestroy(handle);
        return NULL;
    }
    
    
    if (option.isSpecialLoadWidthHeight)
    {
        int scaleCount;
        tjscalingfactor* scaleArray =  tjGetScalingFactors(&scaleCount);
        
        for(int i = scaleCount - 1; i >=0; i--)
        {
            int simpleWidth = TJSCALED(width,scaleArray[i]);
            int simpleHeight = TJSCALED(height, scaleArray[i]);
            if(simpleWidth >= option.loadWidth && simpleHeight >= option.loadHeight)
            {
                width = simpleWidth;
                height = simpleHeight;
                break;
            }
        }
    }
    
    
    flags = 0;
    pixelFormat = TJPF_RGB;
    pitch = tjPixelSize[pixelFormat] * width;
    dstSize = pitch * height;
    dstBuf = (unsigned char*)malloc(dstSize);
    
    if(tjDecompress2(handle, jpegBuf, jpegSize, dstBuf, width, pitch, height, pixelFormat, flags) != 0)
    {
        printf("ReadJpegAsRGB() tjDecompress2() failed: %s\n", tjGetErrorStr());
        tjDestroy(handle);
        return NULL;
    }
    tjDestroy(handle);
    
    CGDataProviderRef dataProvider =  CGDataProviderCreateWithData(nil, dstBuf, dstSize, MyProviderReleaseDataCallback);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef image = CGImageCreate(width, height, 8, 24, 3*width, colorSpace, kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault );
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(dataProvider);
    
    return image;
}

@end
