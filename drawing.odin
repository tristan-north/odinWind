package main

Painter :: struct {
	clip: 			Rect, // The rectangle the element should draw into.
	bits:			[]u32, // The bitmap itself. bits[y * painter->width + x] gives the RGB value of pixel (x, y).
	width, height: 	int // The width and height of the bitmap.
}


draw_block :: proc(painter: ^Painter, rect: Rect, color: u32) {
	// Intersect the rectangle we want to fill with the clip, i.e. the rectangle we're allowed to draw into.
	rect_clipped := rect_intersection(painter.clip, rect)

	// For every pixel inside the rectangle...
	for y in rect_clipped.t..<rect_clipped.b {
		for x in rect_clipped.l..<rect_clipped.r {
			// Set the pixel to the given color.
			painter.bits[y * painter.width + x] = color
		}
	}
}

