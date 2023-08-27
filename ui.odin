package main

import "vendor:glfw"

/*TODO:
 - Use bit_set instead of flags u32 on Widget
 - Change it so y values in screen space increase as they go higher to match opengl
*/

Rect :: struct { l, r, t, b: int }

Message :: enum {
	User,
	Layout, // To be sent when a widget has had its size or position changed.
	Paint,
}

Color :: [4]f32

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
		widget_repaint(widget)
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
	window: 		^Window, // The window at the root of the hierarchy.
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


// Marks a widget as needing to be repainted. If region is nil, the region will be the bounds of the widget.
widget_repaint :: proc(widget: ^Widget, region: ^Rect = nil) {
	region := region
	if region == nil {
		// If the region to repaint was not specified, use the whole bounds of the widget.
		region = &widget.bounds
	}

	// Intersect the region to repaint with the widget's clip.
	r := rect_intersection(region^, widget.clip)

	// If the intersection is non-empty...
	if rect_valid(r) {
		// Set the window's updateRegion to be the smallest rectangle containing both
		// the previous value of the updateRegion and the new rectangle we need to repaint.
		if rect_valid(widget.window.update_region) {
			widget.window.update_region = rect_bounding(widget.window.update_region, r)
		} else {
			widget.window.update_region = r;
		}
	}
}

Window :: struct {
	using widget: Widget,
	window_handle: glfw.WindowHandle,
	width, height: int,
	update_region: Rect,
	bits: []u32,
}

window_create :: proc () -> ^Window {
	window := widget_create(Window, nil, 0, _window_message)

	window.window = window // Set the window field on the widget to be the new window
	
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)

	window.width = 640
	window.height = 480
	window.bounds = Rect{l=0, t=0, r=int(window.width), b=int(window.height)}
	window.clip = window.bounds
	window.window_handle = glfw.CreateWindow(i32(window.width), i32(window.height), "Window Title", nil, nil)
	if window.window_handle == nil do panic("EXIT_FAILURE")

	return window
}

// Recusively sends the Paint message to the widget and its children. Called by _update.
@(private="file")
_widget_paint :: proc(widget: ^Widget, painter: ^Painter) {
	// Compute the intersection of where the element is allowed to draw, widget->clip,
	// with the area requested to be drawn, painter->clip.
	clip := rect_intersection(widget.clip, painter.clip)

	// If the above regions do not overlap, return here,
	// and do not recurse into our descendant elements
	// (since their clip rectangles are contained within widget->clip).
	if rect_valid(clip) == false do return 

	// Set the painter's clip and ask the widget to paint itself.
	painter.clip = clip
	widget_message(widget, .Paint, 0, painter)

	// Recurse into each child, restoring the clip each time.
	for child in widget.children {
		painter.clip = clip
		_widget_paint(child, painter)
	}
}

// Sets up a Painter and calls _widget_paint on the window with update_region as the clip rect.
_update :: proc() {
	window := global.window

	// Is there anything marked for repaint?
	if rect_valid(window.update_region) {
		// Setup the painter using the window's buffer.
		painter: Painter
		painter.width = window.width;
		painter.height = window.height;
		painter.clip = rect_intersection(Rect{0, window.width, 0, window.height}, window.update_region)

		// Send Paint messages to everything in the update region.
		_widget_paint(&window.widget, &painter);

		// Tell the platform layer to put the result onto the screen.
		_window_end_paint(window, &painter);

		// Clear the update region, ready for the next input event cycle.
		window.update_region = Rect{0, 0, 0, 0}
	}
}

@(private="file")
_window_end_paint :: proc(window: ^Window, painter: ^Painter) {
	glfw.SwapBuffers(global.window.window_handle)
}


//////////////////////////////////////
//  Helper functions
//////////////////////////////////////

// Returns true if the rectangle is 'valid', which I define to mean it has positive width and height.
rect_valid :: proc(rect: Rect) -> bool {
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


// ElementRepaint() Called by library user, just sets the updateRegion on Window

