#import <Cocoa/Cocoa.h>
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

@interface ItemButton : NSButton
@property(strong) AppItemObj *item;
@property(assign) NSInteger windowLevelIndex;
@end
@implementation ItemButton
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
  for (NSWindow *w in self.activeWindows) {
    [w orderOut:nil];
  }
  [self.activeWindows removeAllObjects];
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

  if (level == 0) {
    x = NSMidX(parentFrame) - (windowSize / 2.0);
    y = NSMinY(parentFrame) - windowSize - 10.0;
  } else {
    x = NSMaxX(parentFrame) + 12.0;
    y = NSMaxY(parentFrame) - windowSize;

    if (x + windowSize > NSMaxX(screenRect)) {
      x = NSMinX(parentFrame) - windowSize - 12.0;
    }
  }

  if (x + windowSize > NSMaxX(screenRect))
    x = NSMaxX(screenRect) - windowSize - 10.0;
  if (x < NSMinX(screenRect))
    x = NSMinX(screenRect) + 10.0;
  if (y < NSMinY(screenRect))
    y = NSMinY(screenRect) + 10.0;

  CustomPanel *window = [[CustomPanel alloc]
      initWithContentRect:NSMakeRect(x, y, windowSize, windowSize)
                styleMask:NSWindowStyleMaskBorderless |
                          NSWindowStyleMaskNonactivatingPanel
                  backing:NSBackingStoreBuffered
                    defer:NO];
  [window setOpaque:NO];
  [window setBackgroundColor:[NSColor clearColor]];
  [window setLevel:NSFloatingWindowLevel];
  [window setHasShadow:YES];

  NSVisualEffectView *blurView = [[NSVisualEffectView alloc]
      initWithFrame:NSMakeRect(0, 0, windowSize, windowSize)];
  blurView.material = NSVisualEffectMaterialPopover;
  blurView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
  blurView.state = NSVisualEffectStateActive;
  blurView.wantsLayer = YES;
  blurView.layer.cornerRadius = 30.0;
  blurView.layer.masksToBounds = YES;
  blurView.layer.borderWidth = 1.0;
  blurView.layer.borderColor = [NSColor colorWithWhite:0.5 alpha:0.3].CGColor;

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