package main

import "core:fmt"
printf :: fmt.printf
import "core:runtime"
import "core:strings"
import "vendor:glfw"
import gl "vendor:OpenGL"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 0

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
	
	global.window.bounds = Rect{l=0, t=0, r=int(width), b=int(height)}
	global.window.clip = global.window.bounds
	widget_message(global.window, .Layout, 0, nil)
	
	draw()
}

draw :: proc() {
	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.BindVertexArray(global.vao)
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
	glfw.SwapBuffers(global.window.window_handle)
}

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
	
    program := create_shader_program()
    gl.UseProgram(program);

    global.vao = setup_vao();

	setup_UI()

	for !glfw.WindowShouldClose(window.window_handle) {
		glfw.WaitEvents()

		draw()
	}
}

setup_vao :: proc() -> u32 {
    vertices := [?][3]f32{ [3]f32{ -0.5, -0.5, 0.0 }, [3]f32{ -0.5, 0.5, 0.0 }, [3]f32{ 0.5, 0.5, 0.0 }, 
						  [3]f32{ 0.5, 0.5, 0 },     [3]f32{ 0.5, -0.5, 0 },   [3]f32{ -0.5, -0.5, 0 } };

    vao: u32
    gl.GenVertexArrays(1, &vao)
    gl.BindVertexArray(vao)

    vbo: u32
    gl.GenBuffers(1, &vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of((vertices)), &vertices, gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    return vao
}

create_shader_program :: proc() -> u32 {
    vertex_shader_source := `
        #version 330 core
        layout (location = 0) in vec3 aPos;
        void main()
        {
        	gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
        }`
    
    frag_shader_source := `
        #version 330 core
        out vec4 FragColor;
        
        void main()
        {
            FragColor = vec4(0.3f, 0.3f, 0.3f, 1.0f);
        }`

	shader_program, success := gl.load_shaders_source(vertex_shader_source, frag_shader_source)
	
    return shader_program;
}


///////////////////////////////////////////////
// UI Testing
///////////////////////////////////////////////
widgetB: ^Widget

central_widget_message :: proc(widget: ^Widget, message: Message, di: int, dp: rawptr) {
	bounds := widget.bounds

	if message == .Paint {
		draw_block((^Painter)(dp), bounds, 0xFF77FF)
	} else if message == .Layout {
		printf("layout A with bounds (%v->%v;%v->%v)\n", bounds.l, bounds.r, bounds.t, bounds.b)
		widget_move(widgetB, Rect(bounds.l + 20, bounds.r - 20, bounds.t + 20, bounds.b - 20), false);
	}

	return 0;
}
setup_UI :: proc() {
	// UI Testing
	central_widget := widget_create(Widget, global.window, 0, nil)
	widget2 := widget_create(central_widget, 0)
}
