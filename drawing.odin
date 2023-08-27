package main

import gl "vendor:OpenGL"

Painter :: struct {
	clip: 			Rect, // The rectangle the element should draw into.
	width, height: 	int // The width and height of the bitmap.
}

draw_block :: proc(painter: ^Painter, rect: Rect, color: Color) {
	color := color
	// Intersect the rectangle we want to fill with the clip, i.e. the rectangle we're allowed to draw into.
	rect_clipped := rect_intersection(painter.clip, rect)
	rect_NDC: [4]f32
	rect_to_ndc(rect_clipped, &rect_NDC)

	gl.Uniform4fv(0, 1, &rect_NDC[0])	
	gl.Uniform4fv(1, 1, &color[0])	
	
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
}

rect_to_ndc :: proc(rect: Rect, asNDC: ^[4]f32) {
	asNDC[0] = (f32(rect.l) / f32(global.window.width) - 0.5) * 2.0
	asNDC[1] = (f32(rect.r) / f32(global.window.width) - 0.5) * 2.0
	asNDC[2] = (f32(rect.t) / f32(global.window.height) - 0.5) * 2.0
	asNDC[3] = (f32(rect.b) / f32(global.window.height) - 0.5) * 2.0
}

