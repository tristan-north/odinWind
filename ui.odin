package main

import "vendor:glfw"

/*TODO:
 - Use bit_set instead of flags u32 on Widget
*/

Rect :: struct { l, r, t, b: int }

Message :: enum {
	User,
	Layout, // To be sent when a widget has had its size or position changed.
	Paint,
}

//////////////////////////////////////
//  Callback functions
//////////////////////////////////////

MessageHandler :: proc(widget: ^Widget, message: Message, di: int, dp: rawptr) -> int

@(private="file")
_window_message :: proc(widget: ^Widget, message: Message, di: int, dp: rawptr) -> int {

	// Window should only have one child widget.
	if message == .Layout && len(widget.children) > 0 {
		// Move the first child to fill the bounds of the window.
		widget_move(widget.children[0], widget.bounds)
	}

	return 0
}

//////////////////////////////////////


Widget :: struct {
	flags: 			u32, // First 16 bits are specific to the type of Widget (button, label, etc.). The higher order 16 bits are common to all Widgets.
	parent: 		^Widget, // The parent Widget.
	children: 		[dynamic]^Widget, // An array of pointers to the child Widgets.
	bounds:			Rect,
	clip:			Rect, // The subrectangle of the widget's bounds that is actually visible and interactable.	
	window: 		glfw.WindowHandle, // The window at the root of the hierarchy.
	message_class:	MessageHandler,
	message_user:	MessageHandler,
	cp:				rawptr,
}

// Create a widget. message_handler is the message_class proc, ie the proc which handles messages which are the same for all instances of the widget. 
widget_create :: proc($T: typeid, parent: ^Widget, flags: u32, message_hander: MessageHandler) -> ^T {
	widget := new(T)
	widget.flags = flags
	widget.message_class = message_hander

	if parent != nil {
		append(&parent.children, widget)
		widget.parent = parent
		widget.window = parent.window
	}

	return widget
}

// Send a message to a widget. Will call the message_user proc of the widget if not null otherwise calls message_class proc. di and dp can be any extra user info. If the message_user proc exists but returns 0, will also call message_class.
widget_message :: proc(widget: ^Widget, message: Message, di: int, dp: rawptr) -> int {
	if widget.message_user != nil {
		result := widget->message_user(message, di, dp)

		if result != 0 {
			return result;
		} else {
			// Keep going!
		}
	}

	if widget.message_class != nil {
		return widget->message_class(message, di, dp);
	} else {
		return 0
	}
}

// Update the widgets bounds and clip and send the Layout message.
widget_move :: proc(widget: ^Widget, bounds: Rect, alwaysLayout := false) {
	oldClip := widget.clip
	widget.clip = rect_intersection(widget.parent.clip, bounds)

	// Send the layout message only if the clip or bounds has changed, or if alwaysLayout is true.
	if !rect_equals(widget.bounds, bounds) || !rect_equals(widget.clip, oldClip)  || alwaysLayout {
		widget.bounds = bounds
		widget_message(widget, .Layout, 0, nil)
	}
}

Window :: struct {
	using widget: Widget,
	window_handle: glfw.WindowHandle,
	width, height: int,
}

window_create :: proc () -> ^Window {
	window := widget_create(Window, nil, 0, _window_message)
	
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)

	window.width = 640
	window.height = 480
	window.window_handle = glfw.CreateWindow(i32(window.width), i32(window.height), "Window Title", nil, nil)
	if window.window_handle == nil do panic("EXIT_FAILURE")

	return window
}


//////////////////////////////////////
//  Helper functions
//////////////////////////////////////

// Returns true if the rectangle is 'valid', which I define to mean it has positive width and height.
rect_vaid :: proc(rect: Rect) -> bool {
	return rect.r > rect.l && rect.b > rect.t
}

// Compute the intersection of the rectangles, i.e. the biggest rectangle that fits into both. If the rectangles don't overlap, an invalid rectangle is returned (as per RectangleValid).
rect_intersection :: proc(a, b: Rect) -> Rect {
	retRect := a
	
	if retRect.l < b.l do retRect.l = b.l
	if retRect.t < b.t do retRect.t = b.t
	if retRect.r > b.r do retRect.r = b.r
	if retRect.b > b.b do retRect.b = b.b
	
	return retRect
}

// Compute the smallest rectangle containing both of the input rectangles.
rect_bounding :: proc(a, b: Rect) -> Rect {
	retRect := a
	
	if retRect.l > b.l do retRect.l = b.l
	if retRect.t > b.t do retRect.t = b.t
	if retRect.r < b.r do retRect.r = b.r
	if retRect.b < b.b do retRect.b = b.b
	
	return retRect
}

// Returns true if all sides are equal.
rect_equals :: proc(a, b: Rect) -> bool {
	return a.l == b.l && a.r == b.r && a.t == b.t && a.b == b.b 
} 

// Returns true if the pixel with its top-left at the given coordinate is contained inside the rectangle.
rect_contains :: proc(rect: Rect, x, y: int) -> bool {
	return rect.l <= x && rect.r > x && rect.t <= y && rect.b > y
}

// ----------- Painting Process Overview -----------
// As events are processed and widgets are flagged as needing to repaint, rather than doing the repainting immediately, which might cause areas to be repainted multiple times in response to one chunk of event processing, an updateRegion is expanded and then at the end of the event processing the _Update function sends Paint messages to all the widgets which need to be repainted. The widgets then handle the paint messages and call functions to color the pixels. 

// Window only ever has one child with the same width and height as the window.


// MyElementMessage() The message handler function for each widget type which handles the new Paint message.

// _ElementPaint() Recurses through child widgets sending them Paint messages

// Rectangle updateRegion; Need to add to Window struct

// ElementRepaint() Called by library user, just sets the updateRegion on Window

// _Update() Gets called at the end of every "frame" (so far just when we get a window resize callback from the OS) and calls _ElementPaint() on the Window with the updateRegion.
