// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
/**
 * Source file for Shader base class.
 */
module charge.gfx.shader;

import watt.io;
import lib.gl;


class Shader
{
public:
	string name;
	GLuint id;


public:
	this(string name, string vert, string frag, string[] attr, string[] tex)
	{
		this.name = name;
		this.id = makeShaderVF(name, vert, frag, attr, tex);
	}

	this(string name, string vert, string geom, string frag, string[] attr, string[] tex)
	{
		this.name = name;
		this.id = makeShaderVGF(name, vert, geom, frag, attr, tex);
	}

	this(string name, GLuint id)
	{
		this.name = name;
		this.id = id;
	}

	~this()
	{
		if (id != 0) {
			glDeleteProgram(id);
		}
		id = 0;
	}

final:
	void breakApart()
	{
		if (id != 0) {
			glDeleteProgram(id);
		}
		id = 0;
	}

	void bind()
	{
		glUseProgram(id);
	}

	void unbind()
	{
		glUseProgram(0);
	}

	/*
	 * float4
	 */

	void float4(const(char)* name, int count, float *value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform4fv(loc, count, value);
	}

	void float4(const(char)* name, float* value)
	{
		float4(name, 1, value);
	}

	/*
	 * float3
	 */

	void float3(const(char)* name, int count, float* value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform3fv(loc, count, value);
	}

	void float3(const(char)* name, float* value)
	{
		float3(name, 1, value);
	}

	/*
	 * float2
	 */

	void float2(const(char)* name, int count, float* value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform2fv(loc, count, value);
	}

	void float2(const(char)* name, float* value)
	{
		float2(name, 1, value);
	}

	/*
	 * float1
	 */

	void float1(const(char)* name, int count, float* value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform1fv(loc, count, value);
	}

	void float1(const(char)* name, float value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform1f(loc, value);
	}

	/*
	 * int4
	 */

	void int4(const(char)* name, i32* value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform4iv(loc, 1, value);
	}

	/*
	 * int3
	 */

	void int3(const(char)* name, i32* value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform3iv(loc, 1, value);
	}

	/*
	 * int2
	 */

	void int2(const(char)* name, i32* value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform2iv(loc, 1, value);
	}

	/*
	 * int1
	 */

	void int1(const(char)* name, i32 value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform1i(loc, value);
	}

	/*
	 * Matrix
	 */

	void matrix4(const(char)* name, int count, bool transpose, float* value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniformMatrix4fv(loc, count, transpose, value);
	}

	/*
	 * Sampler
	 */

	void sampler(const(char)* name, int value)
	{
		int loc = glGetUniformLocation(id, name);
		glUniform1i(loc, value);
	}
}

GLuint makeShaderVF(string name, string vert, string frag, string[] attr, string[] texs)
{
	// Compile the shaders
	GLuint shader = createAndCompileShaderVF(name, vert, frag);

	// Setup vertex attributes, needs to done before linking.
	for (size_t i; i < attr.length; i++) {
		if (attr[i] is null) {
			continue;
		}

		glBindAttribLocation(shader, cast(uint)i, attr[i].ptr);
	}

	// Linking the Shader Program
	glLinkProgram(shader);

	// Check status and print any debug message.
	if (!printDebug(name, shader, true, "program (vert/frag)")) {
		glDeleteProgram(shader);
		return 0;
	}

	// Setup the texture units.
	glUseProgram(shader);
	for (size_t i; i < texs.length; i++) {
		if (texs[i] is null)
			continue;

		int loc = glGetUniformLocation(shader, texs[i].ptr);
		glUniform1i(loc, cast(int)i);
	}
	glUseProgram(0);

	return shader;
}

GLuint makeShaderVGF(string name, string vert, string geom, string frag, string[] attr, string[] texs)
{
	// Compile the shaders
	GLuint shader = createAndCompileShaderVGF(name, vert, geom, frag);

	// Setup vertex attributes, needs to done before linking.
	for (size_t i; i < attr.length; i++) {
		if (attr[i] is null) {
			continue;
		}

		glBindAttribLocation(shader, cast(uint)i, attr[i].ptr);
	}

	// Linking the Shader Program
	glLinkProgram(shader);

	// Check status and print any debug message.
	if (!printDebug(name, shader, true, "program (vert/geom/frag)")) {
		glDeleteProgram(shader);
		return 0;
	}

	// Setup the texture units.
	glUseProgram(shader);
	for (size_t i; i < texs.length; i++) {
		if (texs[i] is null)
			continue;

		int loc = glGetUniformLocation(shader, texs[i].ptr);
		glUniform1i(loc, cast(int)i);
	}
	glUseProgram(0);

	return shader;
}

static GLuint createAndCompileShaderVF(string name, string vert, string frag)
{
	// Create the handels
	uint vertShader = glCreateShader(GL_VERTEX_SHADER);
	uint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
	uint programShader = glCreateProgram();

	// Attach the shaders to a program handel.
	glAttachShader(programShader, vertShader);
	glAttachShader(programShader, fragShader);

	// Load and compile the Vertex Shader
	compileShader(name, vertShader, vert, "vert");

	// Load and compile the Fragment Shader
	compileShader(name, fragShader, frag, "frag");

	// The shader objects are not needed any more,
	// the programShader is the complete shader to be used.
	glDeleteShader(vertShader);
	glDeleteShader(fragShader);

	return programShader;
}

static GLuint createAndCompileShaderVGF(string name, string vert, string geom, string frag)
{
	// Create the handels
	uint vertShader = glCreateShader(GL_VERTEX_SHADER);
	uint geomShader = glCreateShader(GL_GEOMETRY_SHADER);
	uint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
	uint programShader = glCreateProgram();

	// Attach the shaders to a program handel.
	glAttachShader(programShader, vertShader);
	glAttachShader(programShader, geomShader);
	glAttachShader(programShader, fragShader);

	// Load and compile the Vertex Shader
	compileShader(name, vertShader, vert, "vert");

	// Load and compile the Fragment Shader
	compileShader(name, geomShader, geom, "geom");

	// Load and compile the Fragment Shader
	compileShader(name, fragShader, frag, "frag");

	// The shader objects are not needed any more,
	// the programShader is the complete shader to be used.
	glDeleteShader(vertShader);
	glDeleteShader(geomShader);
	glDeleteShader(fragShader);

	return programShader;
}

void compileShader(string name, GLuint shader, string source, string type)
{
	const(char)* ptr;
	int length;

	ptr = source.ptr;
	length = cast(int)source.length - 1;
	glShaderSource(shader, 1, &ptr, &length);
	glCompileShader(shader);

	// Print any debug message
	printDebug(name, shader, false, type);
}

bool printDebug(string name, GLuint shader, bool program, string type)
{
	// Instead of pointers, realy bothersome.
	GLint status;
	GLint length;

	// Get information about the log on this object.
	if (program) {
		glGetProgramiv(shader, GL_LINK_STATUS, &status);
		glGetProgramiv(shader, GL_INFO_LOG_LENGTH, &length);
	} else {
		glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
	}

	char[] buffer;
	if (length > 2) {
		// Yes length+1 and just length.
		buffer = new char[](length + 1);
		buffer.ptr[length] = 0;

		if (program) {
			glGetProgramInfoLog(shader, length, &length, buffer.ptr);
		} else {
			glGetShaderInfoLog(shader, length, &length, buffer.ptr);
		}
	} else {
		length = 0;
	}

	switch (status) {
	case 1: //GL_TRUE:
		// Only print warnings from the linking stage.
		if (length != 0 && program) {
			writef("%s \"%s\" status ok!\n%s", type, name, buffer);
		} else if (program) {
			writefln("%s \"%s\" status ok!", type, name);
		}

		return true;

	case 0: //GL_FALSE:
		if (length != 0) {
			writef("%s \"%s\" status ok!\n%s", type, name, buffer);
		} else if (program) {
			writefln("%s \"%s\" status ok!", type, name);
		}

		return false;

	default:
		if (length != 0) {
			writef("%s \"%s\" status %s\n%s", type, name, status, buffer);
		} else if (program) {
			writefln("%s \"%s\" status %s", type, name, status);
		}

		return false;
	}
}
