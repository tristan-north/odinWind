package main

import "core:fmt"
printf :: fmt.printf
import "core:runtime"
import "core:strings"
import "vendor:glfw"
import gl "vendor:OpenGL"

// https://nakst.gitlab.io/tutorial/ui-part-1.html

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 3

Global :: struct {
	window: ^Window,
	vao: u32,
}
global: Global

error_callback :: proc "c" (errcode: i32, desc: cstring) {
	context = runtime.default_context()
	fmt.println(desc, errcode)
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_Q && action == glfw.PRESS {
		glfw.SetWindowShouldClose(window, glfw.TRUE)
	}
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width: i32, height: i32) {
	context = runtime.default_context()
	
	gl.Viewport(0, 0, width, height)
	
	global.window.width = int(width)
	global.window.height = int(height)
	global.window.bounds = Rect{l=0, t=0, r=int(width), b=int(height)}
	global.window.clip = global.window.bounds
	widget_message(global.window, .Layout, 0, nil)
	_update()
}

/*
draw :: proc() {
	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.BindVertexArray(global.vao)
	
	// Left, top, right, bot
	bounds := [4]f32{0, 0.5, 0.9, 0}
	gl.Uniform4fv(0, 1, &bounds[0])	
	
	color := [4]f32{1, 0, 0, 1}
	gl.Uniform4fv(1, 1, &color[0])	
	
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
	glfw.SwapBuffers(global.window.window_handle)
}
*/

main :: proc() {
	glfw.SetErrorCallback(error_callback)

	if glfw.Init() == 0 do panic("EXIT_FAILURE")
	defer glfw.Terminate()

	// ver := gl.GetString(gl.VERSION)
	// printf("GL Version: %v\n", ver)
	window := window_create()
	global.window = window
	defer glfw.DestroyWindow(global.window.window_handle)

	// glfw.SwapInterval(1) // Enable Vsync
	
	glfw.SetKeyCallback(window.window_handle, key_callback)
	glfw.SetFramebufferSizeCallback(window.window_handle, framebuffer_size_callback);

	glfw.MakeContextCurrent(window.window_handle)
	
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address) 
	
	gl.ClearColor(0.1, 0.1, 0.1, 1.0)
	
    program := create_quad_shader_program()
    gl.UseProgram(program);

    global.vao = setup_quad_vao();

	setup_UI()

	for !glfw.WindowShouldClose(window.window_handle) {
		glfw.WaitEvents()

		// draw()
	}
}

setup_quad_vao :: proc() -> u32 {
    // vert_indices:= [?][2]f32{ [2]f32{ -0.5, -0.5, 0.0 }, [2]f32{ -0.5, 0.5, 0.0 }, [2]f32{ 0.5, 0.5, 0.0 }, 
				// 		  [2]f32{ 0.5, 0.5, 0 },     [2]f32{ 0.5, -0.5, 0 },   [2]f32{ -0.5, -0.5, 0 } };

	vert_indices := [?]f32 {0, 0,
							1, 0,
							1, 1,
							1, 1,
							0, 1,
							0, 0}

    vao: u32
    gl.GenVertexArrays(1, &vao)
    gl.BindVertexArray(vao)

    vbo: u32
    gl.GenBuffers(1, &vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of((vert_indices)), &vert_indices, gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 2 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    return vao
}

create_quad_shader_program :: proc() -> u32 {
    vertex_shader_source := `
        #version 430 core
        layout (location = 0) in vec2 vert_index;
        layout (location = 0) uniform vec4 bounds;
        void main()
        {
			float x = mix(bounds[0], bounds[1], vert_index.x);
		    float y = mix(bounds[2], bounds[3], vert_index.y);
		    gl_Position = vec4(x, -y, 0.0, 1.0);
        }`
    
    frag_shader_source := `
        #version 430 core
		layout (location = 1) uniform vec4 color;
        out vec4 FragColor;
        
        void main()
        {
            FragColor = color;
        }`

	shader_program, success := gl.load_shaders_source(vertex_shader_source, frag_shader_source)

	if !success {
		printf("Shader failed to be created.\n")
	} 
	
    return shader_program;
}


///////////////////////////////////////////////
// UI Testing
///////////////////////////////////////////////
widgetB, widgetC, widgetD: ^Widget

central_widget_message :: proc(widget: ^Widget, message: Message, di: int, dp: rawptr) -> int {
	bounds := widget.bounds

	switch message {
	case .Paint:
		draw_block((^Painter)(dp), bounds, Color{1, 119/255.0, 1, 1})
	case .Layout:
		widget_move(widgetB, Rect{bounds.l + 20, bounds.r - 20, bounds.t + 20, bounds.b - 20})
	case .User: printf("User message\n")
	}

	return 0
}

widgetB_message :: proc(widget: ^Widget, message: Message, di: int, dp: rawptr) -> int {
	bounds := widget.bounds

	switch message {
	case .Paint:
		draw_block((^Painter)(dp), bounds, Color{221/255.0, 221/255.0, 224/255.0, 1})
	case .Layout:
		widget_move(widgetC, Rect{bounds.l - 40, bounds.l + 40, bounds.t + 40, bounds.b - 40})
		widget_move(widgetD, Rect{bounds.r - 40, bounds.r + 40, bounds.t + 40, bounds.b - 40})
	case .User: printf("User message\n")
	}

	return 0
}

widgetC_message :: proc(widget: ^Widget, message: Message, di: int, dp: rawptr) -> int {
	bounds := widget.bounds

	switch message {
	case .Paint:
		draw_block((^Painter)(dp), bounds, Color{51/255.0, 119/255.0, 1, 1})
	case .Layout:
	case .User: printf("User message\n")
	}

	return 0
}

widgetD_message :: proc(widget: ^Widget, message: Message, di: int, dp: rawptr) -> int {
	bounds := widget.bounds

	switch message {
	case .Paint:
		draw_block((^Painter)(dp), bounds, Color{51/255.0, 204/255.0, 51/255.0, 1})
	case .Layout:
	case .User: printf("User message\n")
	}

	return 0
}

setup_UI :: proc() {
	central_widget := widget_create(Widget, global.window, 0, central_widget_message)
	widgetB = widget_create(Widget, central_widget, 0, widgetB_message)
	widgetC = widget_create(Widget, widgetB, 0, widgetC_message)
	widgetD = widget_create(Widget, widgetB, 0, widgetD_message)
	
	widget_message(global.window, .Layout, 0, nil) // Do inital window layouting
	_update()
}
