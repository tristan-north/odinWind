package main

import "core:fmt"
import "core:runtime"
import "vendor:glfw"
import gl "vendor:OpenGL"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 0

error_callback :: proc "c" (errcode: i32, desc: cstring) {
	context = runtime.default_context()
	fmt.println(desc, errcode)
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_Q && action == glfw.PRESS {
		glfw.SetWindowShouldClose(window, glfw.TRUE)
	}
}

main :: proc() {
	glfw.SetErrorCallback(error_callback)

	if glfw.Init() == 0 do panic("EXIT_FAILURE")
	defer glfw.Terminate()

	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)

	window := glfw.CreateWindow(640, 480, "Simple example", nil, nil)
	if window == nil do panic("EXIT_FAILURE")
	defer glfw.DestroyWindow(window)

	// glfw.SwapInterval(1) // Enable Vsync
	
	glfw.SetKeyCallback(window, key_callback)

	glfw.MakeContextCurrent(window)
	
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address) 
	
	for !glfw.WindowShouldClose(window) {
		glfw.WaitEvents()

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		
		glfw.SwapBuffers(window)
	}
}