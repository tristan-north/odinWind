package main

import "core:fmt"
import "core:runtime"
import "core:strings"
import "vendor:glfw"
import gl "vendor:OpenGL"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 0

State :: struct {
	window: glfw.WindowHandle,
	vao: u32,
}
state: State

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
	draw()
}

draw :: proc() {
	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.BindVertexArray(state.vao)
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
	glfw.SwapBuffers(state.window)
}

main :: proc() {
	glfw.SetErrorCallback(error_callback)

	if glfw.Init() == 0 do panic("EXIT_FAILURE")
	defer glfw.Terminate()

	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)

	state.window = glfw.CreateWindow(640, 480, "Simple example", nil, nil)
	if state.window == nil do panic("EXIT_FAILURE")
	defer glfw.DestroyWindow(state.window)

	// glfw.SwapInterval(1) // Enable Vsync
	
	glfw.SetKeyCallback(state.window, key_callback)
	glfw.SetFramebufferSizeCallback(state.window, framebuffer_size_callback);

	glfw.MakeContextCurrent(state.window)
	
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address) 
	
	gl.ClearColor(0.1, 0.1, 0.1, 1.0)
	
    program := create_shader_program()
    gl.UseProgram(program);

    state.vao = setup_vao();
	
	for !glfw.WindowShouldClose(state.window) {
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

