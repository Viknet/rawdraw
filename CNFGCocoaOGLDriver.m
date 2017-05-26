#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>
#include "CNFGFunctions.h"
#include "CNFGRasterizer.h"

int app_sw=-999, app_sh=-999;

typedef struct
{
    GLfloat x,y;
} Vector2;

typedef struct
{
    GLfloat x,y,z,w;
} Vector4;

typedef struct
{
    GLfloat r,g,b,a;
} Colour;

typedef struct
{
    Vector4 position;
    Colour colour;
} Vertex;


int CompileGLSLShader(const char *vert, const char *frag)
{
    GLint rt;
    GLsizei logLen;
    char log[4096];

    int my_vertex_shader   = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(my_vertex_shader, 1, &vert, NULL);
    glCompileShader(my_vertex_shader);
    glGetShaderiv(my_vertex_shader, GL_COMPILE_STATUS, &rt);
    if (!rt) {
        glGetShaderInfoLog(my_vertex_shader, 4096, &logLen, log);
        printf("vert log (code %d): %s\n", rt, log);
        exit(1);
    }

    int my_fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(my_fragment_shader, 1, &frag, NULL);
    glCompileShader(my_fragment_shader);
    glGetShaderiv(my_fragment_shader, GL_COMPILE_STATUS, &rt);
    if (!rt) {
        glGetShaderInfoLog(my_fragment_shader, 4096, &logLen, log);
        printf("frag log (code %d): %s\n", rt, log);
        exit(1);
    }
    

    int my_program         = glCreateProgram();
    glAttachShader(my_program, my_vertex_shader);
    glAttachShader(my_program, my_fragment_shader);
    glBindFragDataLocation(my_program, 0, "fragColour");

    glLinkProgram(my_program);
    glGetShaderiv(my_program, GL_LINK_STATUS, &rt);
    if (!rt) {
        glGetShaderInfoLog(my_program, 4096, &logLen, log);
        printf("prog log: (code %d) %s\n", rt, log);
        exit(0);
    }

    // Use The Program Object Instead Of Fixed Function OpenGL
    return my_program;
}

// GLuint vertex_buffer, element_buffer;
GLuint shader_program;
GLuint vertexArrayObject;
GLuint vertexBuffer;

// GLint texUnit, position, texCoord;
GLint positionUniform, colourAttribute, positionAttribute;

// static const GLfloat g_vertex_buffer_data[] = { 
//     -1.0f, -1.0f,
//      1.0f, -1.0f,
//     -1.0f,  1.0f,
//      1.0f,  1.0f
// };
// static const GLushort g_element_buffer_data[] = { 0, 1, 2, 3 };

void loadBufferData()
{
    Vertex vertexData[4] = {
        { .position = { .x=-0.5, .y=-0.5, .z=0.0, .w=1.0 }, .colour = { .r=1.0, .g=0.0, .b=0.0, .a=1.0 } },
        { .position = { .x=-0.5, .y= 0.5, .z=0.0, .w=1.0 }, .colour = { .r=0.0, .g=1.0, .b=0.0, .a=1.0 } },
        { .position = { .x= 0.5, .y= 0.5, .z=0.0, .w=1.0 }, .colour = { .r=0.0, .g=0.0, .b=1.0, .a=1.0 } },
        { .position = { .x= 0.5, .y=-0.5, .z=0.0, .w=1.0 }, .colour = { .r=1.0, .g=1.0, .b=1.0, .a=1.0 } }
    };
    
    glGenVertexArrays(1, &vertexArrayObject);
    glBindVertexArray(vertexArrayObject);
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, 4 * sizeof(Vertex), vertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray((GLuint)positionAttribute);
    glEnableVertexAttribArray((GLuint)colourAttribute  );
    glVertexAttribPointer((GLuint)positionAttribute, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, position));
    glVertexAttribPointer((GLuint)colourAttribute  , 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, colour  ));
}

void oglInit()
{
    // glGenBuffers(1, &vertex_buffer);
    // glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
    // glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);

    // glGenBuffers(1, &element_buffer);
    // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, element_buffer);
    // glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(g_element_buffer_data), g_element_buffer_data, GL_STATIC_DRAW);

    // Create the fixed function shader
    const char *vertex_shader="#version 150\n\
        uniform vec2 p;\n\
        in vec4 position;\n\
        in vec4 colour;\n\
        out vec4 colourV;\n\
        void main (void)\n\
        {\n\
            colourV = colour;\n\
            gl_Position = vec4(p, 0.0, 0.0) + position;\n\
        }";
        /*"#version 150\n\
        in vec2 position;\n\
        out vec2 texCoord;\n\
        void main()\n\
        {\n\
            gl_Position = vec4(position, 0.0, 1.0);\n\
            texCoord = position * vec2(0.5) + vec2(0.5);\n\
        }";*/
    
    const char *fragment_shader="#version 150\n\
        in vec4 colourV;\n\
        out vec4 fragColour;\n\
        void main(void)\n\
        {\n\
            fragColour = colourV;\n\
        }";
        /*"#version 150\n\
        uniform sampler2D texUnit;\n\
        in vec2 texCoord;\n\
        out vec4 fragColour;\n\
        void main(void) { \n\
            fragColour = texture(texUnit, texCoord);\n\
        }";*/
    
    shader_program = CompileGLSLShader(vertex_shader, fragment_shader);

    positionUniform = glGetUniformLocation(shader_program, "p");
    colourAttribute = glGetAttribLocation(shader_program, "colour");
    positionAttribute = glGetAttribLocation(shader_program, "position");

    loadBufferData();

    // texUnit = glGetUniformLocation(shader_program, "texUnit");
    // texCoord = glGetAttribLocation(shader_program, "texCoord");
    // position = glGetAttribLocation(shader_program, "position");

    // // 5. Get pointers to uniforms and attributes
    // ogl_compat_texcoord_enabled     = glGetUniformLocation(ogl_compat_shader_program, "hasTex");
    // ogl_compat_texUnit              = glGetUniformLocation(ogl_compat_shader_program, "texUnit");
    // ogl_compat_modelview_projection = glGetUniformLocation(ogl_compat_shader_program, "MVP");
    // ogl_compat_colour_attribute     = glGetAttribLocation (ogl_compat_shader_program, "colour");
    // ogl_compat_texcoord_attribute   = glGetAttribLocation (ogl_compat_shader_program, "texCoord");
    // ogl_compat_position_attribute   = glGetAttribLocation (ogl_compat_shader_program, "position");
}

// GLuint frame_texture;

// static GLuint make_texture(const uint32_t *pixels)
// {
//     GLuint texture;
//     glGenTextures(1, &texture);
//     glBindTexture(GL_TEXTURE_2D, texture);
//     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,     GL_CLAMP_TO_EDGE);
//     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,     GL_CLAMP_TO_EDGE);
//     glTexImage2D(
//         GL_TEXTURE_2D, 0,           /* target, level of detail */
//         GL_RGB8,                    /* internal format */
//         app_sw, app_sh, 0,           /* width, height, border */
//         GL_RGBA, GL_UNSIGNED_INT_8_8_8_8,   /* external format, type */
//         pixels                      /* pixels */
//     );
//     return texture;
// }

void CNFGUpdateScreenWithBitmap( unsigned long * data, int w, int h )
{
    // unsigned char *rgba=data;
    // glUseProgram(shader_program);
    // //--------------------
    // // Draw the scene
    // //--------------------
    // glClearColor(1.0,0.0,0.0,0.0);
    // glClear(GL_COLOR_BUFFER_BIT);

    // frame_texture = make_texture(buffer);

    // glActiveTexture(GL_TEXTURE0);
    // glBindTexture(GL_TEXTURE_2D, frame_texture);
    // glUniform1i(texUnit, 0);

    // glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
    // glVertexAttribPointer(
    //     position,  /* attribute */
    //     2,                                /* size */
    //     GL_FLOAT,                         /* type */
    //     GL_FALSE,                         /* normalized? */
    //     sizeof(GLfloat)*2,                /* stride */
    //     (void*)0                          /* array buffer offset */
    // );
    // glEnableVertexAttribArray(position);

    // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, element_buffer);

    // glDrawElements(
    //     GL_TRIANGLE_STRIP,  /* mode */
    //     4,                  /* count */
    //     GL_UNSIGNED_SHORT,  /* type */
    //     (void*)0            /* element array buffer offset */
    // );

    // glDisableVertexAttribArray(position);
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(shader_program);
    
    GLfloat timeValue = 0.1;
    Vector2 p = { .x = 0.5f * sinf(timeValue), .y = 0.5f * cosf(timeValue) };
    glUniform2fv(positionUniform, 1, (const GLfloat *)&p);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

//window context functions.
id app_oglContext;
id app_menubar, app_appMenuItem, app_appMenu, app_appName, app_quitMenuItem, app_quitTitle, app_quitMenuItem, app_window;
id app_oglView;
NSAutoreleasePool *app_pool;
NSDate *app_currDate; 

static int w, h;
void CNFGGetDimensions( short * x, short * y )
{
    *x = w;
    *y = h;
}

void CNFGSetupFullscreen( const char * WindowName, int screen_no )
{
    
}

void CNFGSetup( const char * WindowName, int sw, int sh )
{
    w = sw;
    h = sh;
    app_sw=sw;
    app_sh=sh;
    // printf("CNFGSetup\n");
        
    //----------------------------------
    // Create a programmatic Cocoa OpenGL window
    // This code is slightly modified from
    // CocoaWithLove's Minimalist Cocoa tutorial
    //----------------------------------
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
    app_window = [[[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, app_sw, app_sh)
        styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable backing:NSBackingStoreBuffered defer:NO]
            autorelease];

    NSString *title = [[[NSString alloc] initWithCString: WindowName encoding: NSUTF8StringEncoding] autorelease];
    [app_window setTitle:title];

    NSOpenGLPixelFormatAttribute pixelFormatAttributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFAColorSize    , 24                           ,
        NSOpenGLPFAAlphaSize    , 8                            ,
        NSOpenGLPFADoubleBuffer ,
        NSOpenGLPFAAccelerated  ,
        NSOpenGLPFANoRecovery   ,
        0
    };

    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes];
    app_oglView = [[[NSOpenGLView alloc] initWithFrame:NSMakeRect(0, 0, sw, sh) pixelFormat: pixelFormat] autorelease];
    app_oglContext = [app_oglView openGLContext];
    [app_oglContext makeCurrentContext];

    [app_window setContentView:app_oglView];
    [app_window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
    [app_window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp finishLaunching];
    [NSApp updateWindows];
    oglInit();

    app_pool = [NSAutoreleasePool new];
    // Set up a 2D projection
    //oglMatrixMode(OGL_PROJECTION);						// Select The Projection Matrix
    //oglLoadIdentity();									// Reset The Projection Matrix
    //oglOrtho(0.0, WIDTH, 0.0, HEIGHT, -10.0, 10.0);
    //oglMatrixMode(OGL_MODELVIEW);							// Select The Modelview Matrix
    //oglLoadIdentity();									// Reset The Modelview Matrix
    //glDisable(GL_DEPTH_TEST);
}

#define XK_Left                          0xff51  /* Move left, left arrow */
#define XK_Up                            0xff52  /* Move up, up arrow */
#define XK_Right                         0xff53  /* Move right, right arrow */
#define XK_Down                          0xff54  /* Move down, down arrow */
#define KEY_UNDEFINED 255
#define KEY_LEFT_MOUSE 0

int app_mouseX=0, app_mouseY=0;
char app_mouseDown[3] = {0,0,0};

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

// void CNFGHandleInput()
// {
// }

void CNFGHandleInput()
{
    // Quit if no open windows left
    if ([[NSApp windows] count] == 0) [NSApp terminate: nil];
    //----------------------
    // Check for mouse motion (NOTE: the mouse move event
    //  has complex behavior after a mouse click.
    //  we can work around this by checking mouse motion explicitly)
    //----------------------
    NSPoint location = [app_window mouseLocationOutsideOfEventStream];
    if ((int)location.x != app_mouseX || (int)location.y != app_mouseY) {
        app_mouseX = (int)location.x;
        app_mouseY = (int)location.y;
        if (app_mouseX >= 0 && app_mouseX < app_sw &&
            app_mouseY >= 0 && app_mouseY < app_sh)
        {
            HandleMotion(app_mouseX, app_mouseY, app_mouseDown[0]||app_mouseDown[1]||app_mouseDown[2]);
        }
    }

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
                    
            case NSEventTypeLeftMouseDown:
                HandleButton(app_mouseX, app_mouseY, KEY_LEFT_MOUSE, 1);
                app_mouseDown[0]=1;
                break;
                    
            case NSEventTypeLeftMouseUp:
                HandleButton(app_mouseX, app_mouseY, KEY_LEFT_MOUSE, 0);
                app_mouseDown[0]=0;
                break;

            default:
                break;
        }
        [NSApp sendEvent:event];
    }
    [app_currDate release];
}

void CNFGSwapBuffers()
{
    CNFGUpdateScreenWithBitmap( (long unsigned int*)buffer, bufferx, buffery );
    [app_oglContext flushBuffer];
}


