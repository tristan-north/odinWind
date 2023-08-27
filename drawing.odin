package main

import gl "vendor:OpenGL"

Painter :: struct {
	clip: 			Rect, // The rectangle the element should draw into.
	width, height: 	int // The width and height of the bitmap.
}

draw_block :: proc(painter: ^Painter, rect: Rect, color: u32) {
	// Intersect the rectangle we want to fill with the clip, i.e. the rectangle we're allowed to draw into.
	rect_clipped := rect_intersection(painter.clip, rect)

	bounds := [4]f32{-0.5, 0.5, 0.9, 0}
	gl.Uniform4fv(0, 1, &bounds[0])	
	
	asbytes := transmute([4]u8)color
	colorFloat: [4]f32
	colorFloat.r = (cast(f32)asbytes[3]) / 255.0	
	colorFloat.g = (cast(f32)asbytes[2]) / 255.0	
	colorFloat.b = (cast(f32)asbytes[1]) / 255.0	
	colorFloat.a = (cast(f32)asbytes[0]) / 255.0	
	
	gl.Uniform4fv(1, 1, &colorFloat[0])	
	
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
}

rect_to_ndc :: proc(rect: Rect, asNDC: ^[4]f32) {
	asNDC[0] = (f32(rect.l) / f32(global.window.width) - 0.5) * 2.0
	asNDC[1] = (f32(rect.t) / f32(global.window.height) - 0.5) * 2.0
	asNDC[2] = (f32(rect.r) / f32(global.window.width) - 0.5) * 2.0
	asNDC[3] = (f32(rect.b) / f32(global.window.height) - 0.5) * 2.0
}

