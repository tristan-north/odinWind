package main

import gl "vendor:OpenGL"

Painter :: struct {
	clip: 			Rect, // The rectangle the element should draw into.
	width, height: 	int // The width and height of the bitmap.
}

draw_block :: proc(painter: ^Painter, rect: Rect, color: u32) {
	color := color
	
	// Intersect the rectangle we want to fill with the clip, i.e. the rectangle we're allowed to draw into.
	rect_clipped := rect_intersection(painter.clip, rect)

	bounds := [4]f32{0, 0.5, 0.9, 0}
	gl.Uniform4fv(0, 1, &bounds[0])	
	
	r := transmute(^u8)&color
	rFloat := f32(r^)
	
	colorFloat := [4]f32{rFloat, 0, 0, 1}
	gl.Uniform4fv(1, 1, &colorFloat[0])	
	
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
	// printf("Painting rect: %v\n", rect)

	// For every pixel inside the rectangle...
	// for y in rect_clipped.t..<rect_clipped.b {
	// 	for x in rect_clipped.l..<rect_clipped.r {
	// 		// Set the pixel to the given color.
	// 		painter.bits[y * painter.width + x] = color
	// 	}
	// }
}

// Doing currently
// Need to actually do the drawing with the UI library and draw_block, then get the color conversion from u32 to [4]f32 working.
