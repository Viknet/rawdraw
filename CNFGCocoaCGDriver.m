//Copyright (c) 2017 <>< David Chapman - Under the MIT/x11 or NewBSD License you choose.
//Copyright (C) 2017 Viknet, MIT/x11 License or NewBSD License you choose.

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

#define RGB2Color(RGB) (RGB&0xFF)/256., ((RGB>>8)&0xFF)/256., ((RGB>>16)&0xFF)/256. 

#include "CNFGFunctions.h"

id app_menubar, app_appMenuItem, app_appMenu, app_appName, app_quitMenuItem, app_quitTitle, app_quitMenuItem, app_window;
id app_imageView;
CGColorSpaceRef colorSpace;
CGContextRef bufferContext;
uint32_t *bufferData;

NSAutoreleasePool *app_pool;
int app_sw=0, app_sh=0;
NSRect frameRect;
int app_mouseX=0, app_mouseY=0;
BOOL inFullscreen = false;

uint32_t CNFGColor( uint32_t RGB )
{
    CNFGLastColor = RGB;
    unsigned char red = RGB & 0xFF;
    unsigned char grn = ( RGB >> 8 ) & 0xFF;
    unsigned char blu = ( RGB >> 16 ) & 0xFF;
    CGContextSetRGBStrokeColor(bufferContext, RGB2Color(RGB), 1.0);
    CGContextSetRGBFillColor(bufferContext, RGB2Color(RGB), 1.0);
    return CNFGLastColor;
}

void CNFGTackPixel( short x, short y )
{
    y = app_sh - y - 1;
    if( x < 0 || y < 0 || x >= app_sw || y >= app_sh ) return;
    bufferData[x + app_sw * y] = CNFGLastColor;
}

// void CNFGTackSegment( short x1, short y1, short x2, short y2 )
// {
//     y1 = app_sh - y1 - 1;
//     y2 = app_sh - y2 - 1;
//     CGContextBeginPath(bufferContext);
//     CGContextMoveToPoint(bufferContext, x1, y1);
//     CGContextAddLineToPoint(bufferContext, x2, y2);
//     CGContextStrokePath(bufferContext);
// }

void CNFGTackSegment( short x1, short y1, short x2, short y2 )
{
    short tx, ty;
    float slope, lp;

    short dx = x2 - x1;
    short dy = y2 - y1;

    if( dx < 0 ) dx = -dx;
    if( dy < 0 ) dy = -dy;

    if( dx > dy )
    {
        short minx = (x1 < x2)?x1:x2;
        short maxx = (x1 < x2)?x2:x1;
        short miny = (x1 < x2)?y1:y2;
        short maxy = (x1 < x2)?y2:y1;
        float thisy = miny;
        slope = (float)(maxy-miny) / (float)(maxx-minx);

        for( tx = minx; tx <= maxx; tx++ )
        {
            ty = thisy;
            if( tx < 0 || ty < 0 || ty >= app_sh ) continue;
            if( tx >= app_sw ) break;
            bufferData[ty * app_sw + tx] = CNFGLastColor;
            thisy += slope;
        }
    }
    else
    {
        short minx = (y1 < y2)?x1:x2;
        short maxx = (y1 < y2)?x2:x1;
        short miny = (y1 < y2)?y1:y2;
        short maxy = (y1 < y2)?y2:y1;
        float thisx = minx;
        slope = (float)(maxx-minx) / (float)(maxy-miny);

        for( ty = miny; ty <= maxy; ty++ )
        {
            tx = thisx;
            if( ty < 0 || tx < 0 || tx >= app_sw ) continue;
            if( ty >= app_sh ) break;
            bufferData[ty * app_sw + tx] = CNFGLastColor;
            thisx += slope;
        }
    }
}

void CNFGTackRectangle( short x1, short y1, short x2, short y2 )
{
    CGContextFillRect(bufferContext, CGRectMake (x1, app_sh - y1 - 1, x2, app_sh - y2 - 1 ));
}

void CNFGTackPoly( RDPoint * points, int verts )
{
    if (verts==0) return;
    CGContextMoveToPoint(bufferContext, points[0].x, app_sh - points[0].y - 1);
    for (int i=1; i<verts; i++){
        CGContextAddLineToPoint(bufferContext, points[i].x, app_sh - points[i].y - 1);
    }
    CGContextFillPath(bufferContext);
}

void CNFGGetDimensions( short * x, short * y )
{
    *x = app_sw;
    *y = app_sh;
}

@interface MyView : NSView
@end
@implementation MyView
- (void)drawRect:(NSRect) r
{
    CGContextRef viewContext = [[NSGraphicsContext currentContext] graphicsPort];
    CGImageRef frameImage = CGBitmapContextCreateImage(bufferContext);
    CGContextDrawImage(viewContext, frameRect, frameImage);
    CGImageRelease(frameImage);
}
@end

CGContextRef createBitmapContext (int pixelsWide,
                            int pixelsHigh)
{
    CGContextRef    context = NULL;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
 
    bitmapBytesPerRow   = (pixelsWide * 4);// 1
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
 
    colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    bufferData = calloc( bitmapByteCount, sizeof(uint8_t) );

    NSLog(@"Bytes: %d", pixelsWide*pixelsHigh);
    NSLog(@"Width: %d Height: %d", pixelsWide, pixelsHigh);


    context = CGBitmapContextCreate (bufferData,// 4
                                    pixelsWide,
                                    pixelsHigh,
                                    8,      // bits per component
                                    bitmapBytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaNoneSkipLast);
    // CGFloat inset = 0.5 / [[UIScreen mainScreen] scale];
    // CGContextSetShouldAntialias(context, NO);
    CGContextSetLineWidth(context, 1.0);

    return context;// 7
}

void initApp(){
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    app_menubar = [[NSMenu new] autorelease];
    app_appMenuItem = [[NSMenuItem new] autorelease];
    [app_menubar addItem:app_appMenuItem];
    [NSApp setMainMenu:app_menubar];
    app_appMenu = [[NSMenu new] autorelease];
    app_appName = [[NSProcessInfo processInfo] processName];
    app_quitTitle = [@"Quit " stringByAppendingString:app_appName];
    app_quitMenuItem = [[[NSMenuItem alloc] initWithTitle:app_quitTitle
        action:@selector(terminate:) keyEquivalent:@"q"] autorelease];
    [app_appMenu addItem:app_quitMenuItem];
    [app_appMenuItem setSubmenu:app_appMenu];
    app_imageView = [MyView new];
}

void CNFGSetupFullscreen( const char * WindowName, int screen_number )
{
    inFullscreen = YES;
    initApp();

    NSDictionary *fullScreenOptions = [[NSDictionary dictionaryWithObjectsAndKeys: 
        [NSNumber numberWithInt: 
            (NSApplicationPresentationAutoHideMenuBar | NSApplicationPresentationAutoHideDock) ],
        NSFullScreenModeApplicationPresentationOptions, nil] retain];
    [app_imageView enterFullScreenMode:[[NSScreen screens] objectAtIndex:screen_number] withOptions:fullScreenOptions];
    CGSize app_imageSize = [app_imageView frame].size;
    app_sw = app_imageSize.width; app_sh = app_imageSize.height;
    frameRect = NSMakeRect(0, 0, app_sw, app_sh);
    bufferContext = createBitmapContext (app_sw, app_sh);
    [NSApp finishLaunching];
    [NSApp updateWindows];
    app_pool = [NSAutoreleasePool new];
}

void CNFGSetup( const char * WindowName, int sw, int sh )
{
    app_sw=sw; app_sh=sh;
    frameRect = NSMakeRect(0, 0, app_sw, app_sh);

    initApp();

    app_window = [[[NSWindow alloc] initWithContentRect:frameRect
        styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable backing:NSBackingStoreBuffered defer:NO]
            autorelease];

    NSString *title = [[[NSString alloc] initWithCString: WindowName encoding: NSUTF8StringEncoding] autorelease];
    [app_window setTitle:title];
    [app_window setContentView:app_imageView];
    [app_window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
    [app_window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    bufferContext = createBitmapContext (app_sw, app_sh);
    [NSApp finishLaunching];
    [NSApp updateWindows];
    app_pool = [NSAutoreleasePool new];
}

#define XK_Left                          0xff51  /* Move left, left arrow */
#define XK_Up                            0xff52  /* Move up, up arrow */
#define XK_Right                         0xff53  /* Move right, right arrow */
#define XK_Down                          0xff54  /* Move down, down arrow */
#define KEY_UNDEFINED 255
#define KEY_LEFT_MOUSE 0

static int keycode(key)
{
    if (key < 256) return key;
    switch(key) {
        case 63232: return XK_Up;
        case 63233: return XK_Down;
        case 63234: return XK_Left;
        case 63235: return XK_Right;
    }
    return KEY_UNDEFINED;
}

void CNFGHandleInput()
{
    // Quit if no open windows left
    if ([[NSApp windows] count] == 0) return;//[NSApp terminate: nil];

    //----------------------
    // Peek at the next event
    //----------------------
    NSDate *app_currDate = [NSDate new];
    // If we have events, handle them!
    NSEvent *event;
    for (;(event = [NSApp
                    nextEventMatchingMask:NSEventMaskAny
                    untilDate:app_currDate
                    inMode:NSDefaultRunLoopMode
                    dequeue:YES]);)
    {
        NSPoint local_point;
        NSEventType type = [event type];
        switch (type)
        {
            case NSEventTypeKeyDown:
                for (int i=0; i<[event.characters length]; i++) {
                    unichar ch = [event.characters characterAtIndex: i];
                    HandleKey(keycode(ch), 1);
                }
                break;
                
            case NSEventTypeKeyUp:
                for (int i=0; i<[event.characters length]; i++) {
                    unichar ch = [event.characters characterAtIndex: i];
                    HandleKey(keycode(ch), 0);
                }
                break;
                    
            case NSEventTypeMouseMoved:
            case NSEventTypeLeftMouseDragged:
            case NSEventTypeRightMouseDragged:
            case NSEventTypeOtherMouseDragged:
                if (inFullscreen){
                    local_point = [NSEvent mouseLocation];
                } else {
                    if ([event window] == nil) break;
                    NSPoint event_location = event.locationInWindow;
                    local_point = [app_imageView convertPoint:event_location fromView:nil];
                }
                app_mouseX = fmax(fmin(local_point.x, app_sw), 0);
                // Y coordinate must be inversed?
                app_mouseY = fmax(fmin(app_sh - local_point.y, app_sh), 0);
                HandleMotion(app_mouseX, app_mouseY, [NSEvent pressedMouseButtons]);
                break;  

            case NSEventTypeLeftMouseDown:
            case NSEventTypeRightMouseDown:
            case NSEventTypeOtherMouseDown:
                // Button number start from 1?
                HandleButton(app_mouseX, app_mouseY, event.buttonNumber+1, 1); 
                break;
                    
            case NSEventTypeLeftMouseUp:
            case NSEventTypeRightMouseUp:
            case NSEventTypeOtherMouseUp:
                HandleButton(app_mouseX, app_mouseY, event.buttonNumber+1, 0);
                break;

            default:
                break;
        }
        [NSApp sendEvent:event];
    }
    [app_currDate release];
}

void CNFGClearFrame()
{
    CGContextSetRGBFillColor(bufferContext, RGB2Color(CNFGBGColor), 1.0);
    CGContextFillRect(bufferContext, CGRectMake (0, 0, app_sw, app_sh ));
}

void CNFGSwapBuffers() 
{
    [app_imageView setNeedsDisplay:YES];
}

void CNFGUpdateScreenWithBitmap( unsigned long * data, int w, int h )
{
    [app_pool release];
    app_pool = [NSAutoreleasePool new];

    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, 4*w*h, NULL);
    CGImageRef bitmap = CGImageCreate(w, h, 8, 32, 4*w, colorSpace, kCGBitmapByteOrder32Little, provider, NULL, false, kCGRenderingIntentDefault);
    CGContextDrawImage(bufferContext, frameRect, bitmap);
    CGImageRelease(bitmap);
    CGDataProviderRelease(provider);
}
