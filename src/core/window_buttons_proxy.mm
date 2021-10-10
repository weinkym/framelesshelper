// Copyright (c) 2021 Microsoft, Inc.
// Use of this source code is governed by the MIT license that can be
// found in the LICENSE file.

#include "window_buttons_proxy.h"

@implementation ButtonsAreaHoverView : NSView

- (id)initWithProxy:(WindowButtonsProxy*)proxy {
  if ((self = [super init])) {
    proxy_ = proxy;
  }
  return self;
}

// Ignore all mouse events.
- (NSView*)hitTest:(NSPoint)aPoint {
  return nil;
}

- (void)updateTrackingAreas {
  [proxy_ updateTrackingAreas];
}

@end

@implementation WindowButtonsProxy

- (id)initWithWindow:(NSWindow*)window {
  window_ = window;
  show_on_hover_ = NO;
  mouse_inside_ = NO;

  // Remember the default margin.
  margin_ = default_margin_ = [self getCurrentMargin];

  return self;
}

- (void)dealloc {
  if (hover_view_)
    [hover_view_ removeFromSuperview];
  [super dealloc];
}

- (void)setVisible:(BOOL)visible {
  NSView* titleBarContainer = [self titleBarContainer];
  if (!titleBarContainer)
    return;
  [titleBarContainer setHidden:!visible];
}

- (BOOL)isVisible {
  NSView* titleBarContainer = [self titleBarContainer];
  if (!titleBarContainer)
    return YES;
  return ![titleBarContainer isHidden];
}

- (void)setShowOnHover:(BOOL)yes {
  NSView* titleBarContainer = [self titleBarContainer];
  if (!titleBarContainer)
    return;
  show_on_hover_ = yes;
  // Put a transparent view above the window buttons so we can track mouse
  // events when mouse enter/leave the window buttons.
  if (show_on_hover_) {
    auto old_ptr = hover_view_;
    hover_view_ = [[ButtonsAreaHoverView alloc] initWithProxy:self];
    [old_ptr release];
    [hover_view_ setFrame:[self getButtonsBounds]];
    [titleBarContainer addSubview:hover_view_];
  } else {
    [hover_view_ removeFromSuperview];
    [hover_view_ release];
    hover_view_ = nullptr;
  }
  [self updateButtonsVisibility];
}

- (void)setMargin:(const QPoint&)margin {
  if (!margin.isNull())
    margin_ = margin;
  else
    margin_ = default_margin_;
  [self redraw];
}

- (NSRect)getButtonsContainerBounds {
  return NSInsetRect([self getButtonsBounds], -margin_.x(), -margin_.y());
}

- (void)redraw {
  NSView* titleBarContainer = [self titleBarContainer];
  if (!titleBarContainer)
    return;

  NSView* left = [self leftButton];
  NSView* middle = [self middleButton];
  NSView* right = [self rightButton];

  float button_width = NSWidth(left.frame);
  float button_height = NSHeight(left.frame);
  float padding = NSMinX(middle.frame) - NSMaxX(left.frame);
  float start;
  if (false /*base::i18n::IsRTL()*/)
    start =
        NSWidth(window_.frame) - 3 * button_width - 2 * padding - margin_.x();
  else
    start = margin_.x();

  NSRect cbounds = titleBarContainer.frame;
  cbounds.size.height = button_height + 2 * margin_.y();
  cbounds.origin.y = NSHeight(window_.frame) - NSHeight(cbounds);
  [titleBarContainer setFrame:cbounds];

  [left setFrameOrigin:NSMakePoint(start, margin_.y())];
  start += button_width + padding;
  [middle setFrameOrigin:NSMakePoint(start, margin_.y())];
  start += button_width + padding;
  [right setFrameOrigin:NSMakePoint(start, margin_.y())];

  if (hover_view_)
    [hover_view_ setFrame:[self getButtonsBounds]];
}

- (void)updateTrackingAreas {
  if (tracking_area_)
    [hover_view_ removeTrackingArea:tracking_area_];
  auto old_ptr = tracking_area_;
  tracking_area_ = [[NSTrackingArea alloc]
      initWithRect:NSZeroRect
           options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways |
                   NSTrackingInVisibleRect
             owner:self
          userInfo:nil];
  [old_ptr release];
  [hover_view_ addTrackingArea:tracking_area_];
}

- (void)mouseEntered:(NSEvent*)event {
  mouse_inside_ = YES;
  [self updateButtonsVisibility];
}

- (void)mouseExited:(NSEvent*)event {
  mouse_inside_ = NO;
  [self updateButtonsVisibility];
}

- (void)updateButtonsVisibility {
  NSArray* buttons = @[
    [window_ standardWindowButton:NSWindowCloseButton],
    [window_ standardWindowButton:NSWindowMiniaturizeButton],
    [window_ standardWindowButton:NSWindowZoomButton],
  ];
  // Show buttons when mouse hovers above them.
  BOOL hidden = show_on_hover_ && !mouse_inside_;
  // Always show buttons under fullscreen.
  if ([window_ styleMask] & NSWindowStyleMaskFullScreen)
    hidden = NO;
  for (NSView* button in buttons) {
    [button setHidden:hidden];
    [button setNeedsDisplay:YES];
  }
}

// Return the bounds of all 3 buttons.
- (NSRect)getButtonsBounds {
  NSView* left = [self leftButton];
  NSView* right = [self rightButton];
  return NSMakeRect(NSMinX(left.frame), NSMinY(left.frame),
                    NSMaxX(right.frame) - NSMinX(left.frame),
                    NSHeight(left.frame));
}

// Compute margin from position of current buttons.
- (QPoint)getCurrentMargin {
  QPoint result;
  NSView* titleBarContainer = [self titleBarContainer];
  if (!titleBarContainer)
    return result;

  NSView* left = [self leftButton];
  NSView* right = [self rightButton];

  result.setX((NSHeight(titleBarContainer.frame) - NSHeight(left.frame)) / 2);

  if (false /*base::i18n::IsRTL()*/)
    result.setX(NSWidth(window_.frame) - NSMaxX(right.frame));
  else
    result.setX(NSMinX(left.frame));
  return result;
}

// Receive the titlebar container, which might be nil if the window does not
// have the NSWindowStyleMaskTitled style.
- (NSView*)titleBarContainer {
  NSView* left = [self leftButton];
  if (!left.superview)
    return nil;
  return left.superview.superview;
}

// Receive the window buttons, note that the buttons might be removed and
// re-added on the fly so we should not cache them.
- (NSButton*)leftButton {
  if (false /*base::i18n::IsRTL()*/)
    return [window_ standardWindowButton:NSWindowZoomButton];
  else
    return [window_ standardWindowButton:NSWindowCloseButton];
}

- (NSButton*)middleButton {
  return [window_ standardWindowButton:NSWindowMiniaturizeButton];
}

- (NSButton*)rightButton {
  if (false /*base::i18n::IsRTL()*/)
    return [window_ standardWindowButton:NSWindowCloseButton];
  else
    return [window_ standardWindowButton:NSWindowZoomButton];
}

@end
