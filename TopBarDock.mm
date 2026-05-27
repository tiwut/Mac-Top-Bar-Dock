#import <Cocoa/Cocoa.h>
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>
#include <iostream>

@interface FlippedView : NSView
@end
@implementation FlippedView
- (BOOL)isFlipped {
  return YES;
}
@end

@interface AppItemObj : NSObject
@property(copy) NSString *name;
@property(copy) NSString *path;
@property(assign) BOOL isFolder;
@end
@implementation AppItemObj
@end

@interface GlassOverlayView : NSView
@end

@implementation GlassOverlayView

- (instancetype)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.wantsLayer = YES;
  }
  return self;
}

- (void)drawRect:(NSRect)dirtyRect {
  NSRect bounds = self.bounds;

  [NSGraphicsContext saveGraphicsState];

  NSBezierPath *glossPath = [NSBezierPath bezierPath];
  [glossPath moveToPoint:NSMakePoint(0, bounds.size.height)];
  [glossPath lineToPoint:NSMakePoint(bounds.size.width, bounds.size.height)];
  [glossPath
      lineToPoint:NSMakePoint(bounds.size.width, bounds.size.height - 120)];
  [glossPath lineToPoint:NSMakePoint(0, bounds.size.height - 240)];
  [glossPath closePath];

  NSGradient *glossGradient = [[NSGradient alloc]
      initWithStartingColor:[NSColor colorWithWhite:1.0 alpha:0.07]
                endingColor:[NSColor colorWithWhite:1.0 alpha:0.0]];
  [glossGradient drawInBezierPath:glossPath angle:-45.0];

  NSBezierPath *borderPath =
      [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 0.5, 0.5)
                                      xRadius:24.0
                                      yRadius:24.0];
  [borderPath setLineWidth:1.0];
  [[NSColor colorWithWhite:1.0 alpha:0.18] setStroke];
  [borderPath stroke];

  NSBezierPath *topHighlightPath = [NSBezierPath bezierPath];
  CGFloat r = 24.0;
  [topHighlightPath moveToPoint:NSMakePoint(0, bounds.size.height - r)];
  [topHighlightPath
      appendBezierPathWithArcWithCenter:NSMakePoint(r, bounds.size.height - r)
                                 radius:r
                             startAngle:180.0
                               endAngle:90.0
                              clockwise:YES];
  [topHighlightPath
      lineToPoint:NSMakePoint(bounds.size.width - r, bounds.size.height)];
  [topHighlightPath
      appendBezierPathWithArcWithCenter:NSMakePoint(bounds.size.width - r,
                                                    bounds.size.height - r)
                                 radius:r
                             startAngle:90.0
                               endAngle:0.0
                              clockwise:YES];

  [topHighlightPath setLineWidth:1.5];
  [[NSColor colorWithWhite:1.0 alpha:0.35] setStroke];
  [topHighlightPath stroke];

  [NSGraphicsContext restoreGraphicsState];
}

@end

@interface ItemButton : NSButton {
  NSTrackingArea *_trackingArea;
  BOOL _isHovered;
  BOOL _isPressed;
}
@property(strong) AppItemObj *item;
@property(assign) NSInteger windowLevelIndex;
@property(assign, nonatomic) CGFloat hoverScale;
@end

@implementation ItemButton

+ (id)defaultAnimationForKey:(NSAnimatablePropertyKey)key {
  if ([key isEqualToString:@"hoverScale"]) {
    return [CABasicAnimation animation];
  }
  return [super defaultAnimationForKey:key];
}

- (instancetype)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _hoverScale = 1.0;
    self.wantsLayer = YES;
  }
  return self;
}

- (void)setHoverScale:(CGFloat)hoverScale {
  _hoverScale = hoverScale;
  [self setNeedsDisplay:YES];
}

- (void)updateTrackingAreas {
  [super updateTrackingAreas];
  if (_trackingArea != nil) {
    [self removeTrackingArea:_trackingArea];
  }

  NSTrackingAreaOptions options =
      NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways;
  _trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                               options:options
                                                 owner:self
                                              userInfo:nil];
  [self addTrackingArea:_trackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
  _isHovered = YES;
  [[self animator] setHoverScale:1.51];
}

- (void)mouseExited:(NSEvent *)event {
  _isHovered = NO;
  [[self animator] setHoverScale:1.0];
}

- (void)mouseDown:(NSEvent *)event {
  _isPressed = YES;
  [[self animator] setHoverScale:3.02];
  [super mouseDown:event];
  _isPressed = NO;
  [[self animator] setHoverScale:_isHovered ? 1.12 : 1.0];
}

- (void)mouseUp:(NSEvent *)event {
  [super mouseUp:event];
  _isPressed = NO;
  [[self animator] setHoverScale:_isHovered ? 1.12 : 1.0];
}

- (void)drawRect:(NSRect)dirtyRect {
  NSRect bounds = self.bounds;

  if (_isHovered || _isPressed) {
    [NSGraphicsContext saveGraphicsState];

    NSRect pillRect = NSInsetRect(bounds, 1.0, 1.0);
    NSBezierPath *pillPath = [NSBezierPath bezierPathWithRoundedRect:pillRect
                                                             xRadius:14.0
                                                             yRadius:14.0];

    NSColor *fillColor;
    NSColor *borderColor;

    BOOL isDark = YES;
    if (@available(macOS 10.14, *)) {
      isDark = [[self.effectiveAppearance name]
          containsString:NSAppearanceNameDarkAqua];
    }

    if (_isPressed) {
      fillColor = isDark ? [NSColor colorWithWhite:1.0 alpha:0.18]
                         : [NSColor colorWithWhite:0.0 alpha:0.14];
      borderColor = isDark ? [NSColor colorWithWhite:1.0 alpha:0.25]
                           : [NSColor colorWithWhite:0.0 alpha:0.18];
    } else {
      fillColor = isDark ? [NSColor colorWithWhite:1.0 alpha:0.10]
                         : [NSColor colorWithWhite:0.0 alpha:0.05];
      borderColor = isDark ? [NSColor colorWithWhite:1.0 alpha:0.18]
                           : [NSColor colorWithWhite:0.0 alpha:0.10];
    }

    [fillColor setFill];
    [pillPath fill];

    [borderColor setStroke];
    [pillPath setLineWidth:1.0];
    [pillPath stroke];

    [NSGraphicsContext restoreGraphicsState];
  }

  if (self.image) {
    NSRect imageRect = bounds;
    if (self.hoverScale != 1.0) {
      CGFloat targetSize = bounds.size.width * self.hoverScale;
      CGFloat diff = targetSize - bounds.size.width;
      imageRect = NSMakeRect(-diff / 2, -diff / 2, targetSize, targetSize);
    }
    [self.image drawInRect:NSInsetRect(imageRect, 6.0, 6.0)
                  fromRect:NSZeroRect
                 operation:NSCompositingOperationSourceOver
                  fraction:1.0
            respectFlipped:YES
                     hints:nil];
  }
}

@end

@interface CustomPanel : NSPanel
@end
@implementation CustomPanel
- (BOOL)canBecomeKeyWindow {
  return YES;
}
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong) NSStatusItem *statusItem;
@property(strong) NSMutableArray<NSWindow *> *activeWindows;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  self.activeWindows = [NSMutableArray array];

  self.statusItem = [[NSStatusBar systemStatusBar]
      statusItemWithLength:NSVariableStatusItemLength];

  if (@available(macOS 11.0, *)) {
    self.statusItem.button.image =
        [NSImage imageWithSystemSymbolName:@"square.grid.3x3.fill"
                  accessibilityDescription:nil];
  } else {
    self.statusItem.button.title = @"▣";
  }

  self.statusItem.button.action = @selector(toggleApp:);
  self.statusItem.button.target = self;

  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(closeAllWindows)
             name:NSApplicationDidResignActiveNotification
           object:NSApp];
}

- (void)closeAllWindows {
  NSArray<NSWindow *> *windowsToClose = [self.activeWindows copy];
  [self.activeWindows removeAllObjects];

  [NSAnimationContext
      runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.51;
        context.timingFunction = [CAMediaTimingFunction
            functionWithName:kCAMediaTimingFunctionEaseIn];
        for (NSWindow *w in windowsToClose) {
          [[w animator] setAlphaValue:0.0];
        }
      }
      completionHandler:^{
        for (NSWindow *w in windowsToClose) {
          [w orderOut:nil];
        }
      }];
}

- (void)toggleApp:(id)sender {
  if (self.activeWindows.count > 0) {
    [self closeAllWindows];
  } else {
    NSString *targetPath =
        [NSHomeDirectory() stringByAppendingPathComponent:@"DockDesktop"];

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:targetPath]) {
      [fm createDirectoryAtPath:targetPath
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
    }

    [self openFolder:targetPath
             atLevel:0
         parentFrame:self.statusItem.button.window.frame];

    [NSApp activateIgnoringOtherApps:YES];
  }
}

- (void)openFolder:(NSString *)folderPath
           atLevel:(NSInteger)level
       parentFrame:(NSRect)parentFrame {
  while (self.activeWindows.count > level) {
    NSWindow *w = [self.activeWindows lastObject];
    [w orderOut:nil];
    [self.activeWindows removeLastObject];
  }

  CGFloat windowSize = 500.0;
  NSRect screenRect = [[NSScreen mainScreen] visibleFrame];
  CGFloat x = 0, y = 0;

  CGFloat startX = 0, startY = 0;

  if (level == 0) {
    x = NSMidX(parentFrame) - (windowSize / 2.0);
    y = NSMinY(parentFrame) - windowSize - 10.0;

    startX = x;
    startY = y + 25.0;
  } else {
    x = NSMaxX(parentFrame) + 12.0;
    y = NSMaxY(parentFrame) - windowSize;

    if (x + windowSize > NSMaxX(screenRect)) {
      x = NSMinX(parentFrame) - windowSize - 12.0;
      startX = x + 25.0;
    } else {
      startX = x - 25.0;
    }
    startY = y;
  }

  if (x + windowSize > NSMaxX(screenRect))
    x = NSMaxX(screenRect) - windowSize - 10.0;
  if (x < NSMinX(screenRect))
    x = NSMinX(screenRect) + 10.0;
  if (y < NSMinY(screenRect))
    y = NSMinY(screenRect) + 10.0;

  if (startX + windowSize > NSMaxX(screenRect))
    startX = NSMaxX(screenRect) - windowSize - 10.0;
  if (startX < NSMinX(screenRect))
    startX = NSMinX(screenRect) + 10.0;
  if (startY < NSMinY(screenRect))
    startY = NSMinY(screenRect) + 10.0;

  CustomPanel *window = [[CustomPanel alloc]
      initWithContentRect:NSMakeRect(startX, startY, windowSize, windowSize)
                styleMask:NSWindowStyleMaskBorderless |
                          NSWindowStyleMaskNonactivatingPanel
                  backing:NSBackingStoreBuffered
                    defer:NO];
  [window setOpaque:NO];
  [window setBackgroundColor:[NSColor clearColor]];
  [window setLevel:NSFloatingWindowLevel];
  [window setHasShadow:YES];
  [window setAlphaValue:0.0];

  NSVisualEffectView *blurView = [[NSVisualEffectView alloc]
      initWithFrame:NSMakeRect(0, 0, windowSize, windowSize)];
  blurView.material = NSVisualEffectMaterialPopover;
  blurView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
  blurView.state = NSVisualEffectStateActive;
  blurView.wantsLayer = YES;
  blurView.layer.cornerRadius = 24.0;
  blurView.layer.masksToBounds = YES;

  GlassOverlayView *glassOverlay = [[GlassOverlayView alloc]
      initWithFrame:NSMakeRect(0, 0, windowSize, windowSize)];
  glassOverlay.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  [blurView addSubview:glassOverlay];

  NSFileManager *fm = [NSFileManager defaultManager];
  NSURL *baseURL = [NSURL fileURLWithPath:folderPath];
  NSArray *keys = @[ NSURLIsDirectoryKey, NSURLIsPackageKey ];
  NSArray *contents =
      [fm contentsOfDirectoryAtURL:baseURL
          includingPropertiesForKeys:keys
                             options:NSDirectoryEnumerationSkipsHiddenFiles
                               error:nil];

  NSMutableArray<AppItemObj *> *items = [NSMutableArray array];
  for (NSURL *url in contents) {
    NSNumber *isDir, *isPkg;
    [url getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil];
    [url getResourceValue:&isPkg forKey:NSURLIsPackageKey error:nil];

    AppItemObj *item = [[AppItemObj alloc] init];
    item.name = [url lastPathComponent];
    item.path = [url path];
    item.isFolder = ([isDir boolValue] && ![isPkg boolValue]);
    [items addObject:item];
  }

  [items sortUsingComparator:^NSComparisonResult(AppItemObj *obj1,
                                                 AppItemObj *obj2) {
    return [obj1.name localizedCaseInsensitiveCompare:obj2.name];
  }];

  CGFloat btnSize = 64.0;
  CGFloat spacingX = 30.0;
  CGFloat spacingY = 30.0;
  int cols = 5;
  int rows = ceil((float)items.count / cols);
  if (rows == 0)
    rows = 1;

  CGFloat docHeight = (rows * btnSize) + ((rows + 1) * spacingY);
  if (docHeight < windowSize)
    docHeight = windowSize;

  FlippedView *docView = [[FlippedView alloc]
      initWithFrame:NSMakeRect(0, 0, windowSize, docHeight)];

  if (items.count == 0) {
    NSTextField *emptyLabel = [[NSTextField alloc]
        initWithFrame:NSMakeRect(0, windowSize / 2 - 20, windowSize, 40)];
    [emptyLabel setStringValue:@"Folder is Empty"];
    [emptyLabel setBezeled:NO];
    [emptyLabel setDrawsBackground:NO];
    [emptyLabel setEditable:NO];
    [emptyLabel setSelectable:NO];
    [emptyLabel setAlignment:NSTextAlignmentCenter];
    [emptyLabel setFont:[NSFont systemFontOfSize:16.0
                                          weight:NSFontWeightMedium]];
    [emptyLabel setTextColor:[NSColor secondaryLabelColor]];
    [docView addSubview:emptyLabel];
  }

  for (int i = 0; i < items.count; i++) {
    int r = i / cols;
    int c = i % cols;

    CGFloat bx = spacingX + c * (btnSize + spacingX);
    CGFloat by = spacingY + r * (btnSize + spacingY);

    ItemButton *btn =
        [[ItemButton alloc] initWithFrame:NSMakeRect(bx, by, btnSize, btnSize)];
    btn.item = items[i];
    btn.windowLevelIndex = level;

    [btn setBordered:NO];
    [btn setButtonType:NSButtonTypeMomentaryChange];

    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:items[i].path];
    [icon setSize:NSMakeSize(btnSize, btnSize)];
    [btn setImage:icon];
    [btn setToolTip:items[i].name];

    [btn setTarget:self];
    [btn setAction:@selector(itemClicked:)];
    [docView addSubview:btn];

    NSTextField *label = [[NSTextField alloc]
        initWithFrame:NSMakeRect(bx - 10, by + btnSize + 4, btnSize + 20, 20)];
    [label setStringValue:items[i].name];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setAlignment:NSTextAlignmentCenter];
    [label setFont:[NSFont systemFontOfSize:11.0 weight:NSFontWeightMedium]];
    [label setTextColor:[NSColor labelColor]];
    [[label cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [docView addSubview:label];
  }

  NSScrollView *scrollView = [[NSScrollView alloc]
      initWithFrame:NSMakeRect(0, 0, windowSize, windowSize)];
  [scrollView setHasVerticalScroller:YES];
  [scrollView setDrawsBackground:NO];
  [scrollView setDocumentView:docView];

  [blurView addSubview:scrollView];
  [window.contentView addSubview:blurView];

  [self.activeWindows addObject:window];
  [window makeKeyAndOrderFront:nil];

  [NSAnimationContext
      runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.51;
        context.timingFunction = [CAMediaTimingFunction
            functionWithName:kCAMediaTimingFunctionEaseOut];
        [[window animator] setFrame:NSMakeRect(x, y, windowSize, windowSize)
                            display:YES];
        [[window animator] setAlphaValue:1.0];
      }
      completionHandler:nil];
}

- (void)itemClicked:(ItemButton *)sender {
  if (sender.item.isFolder) {
    [self openFolder:sender.item.path
             atLevel:(sender.windowLevelIndex + 1)
         parentFrame:sender.window.frame];
  } else {
    NSURL *url = [NSURL fileURLWithPath:sender.item.path];
    [[NSWorkspace sharedWorkspace] openURL:url];
    [self closeAllWindows];
  }
}

@end

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];
    AppDelegate *delegate = [[AppDelegate alloc] init];
    [app setDelegate:delegate];
    [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [app run];
  }
  return 0;
}