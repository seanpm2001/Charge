// Copyright © 2011-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/licence.volt (BOOST ver. 1.0).
module charge.gfx.gl;

static import watt.conv;
static import watt.io.std;

public import lib.gl;

void glCheckError(const(char)[] file = __FILE__, int line = __LINE__)
{
	auto err = glGetError();
	if (!err) {
		return;
	}

	string code;
	switch (err) {
	case GL_INVALID_ENUM: code = "GL_INVALID_ENUM"; break;
	case GL_INVALID_OPERATION: code = "GL_INVALID_OPERATION"; break;
	case GL_INVALID_VALUE: code = "GL_INVALID_VALUE"; break;
	default: code = watt.conv.toString(err); break;
	}

	watt.io.std.writefln("%s:%s error: %s", file, line, code);
}

void glCheckFramebufferError(const(char)[] file = __FILE__, int line = __LINE__)
{
	auto status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
	if (status == GL_FRAMEBUFFER_COMPLETE) {
		return;
	}

	string code;
	switch (status) {
	case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
		code = "GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
		code = "GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
		code = "GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER:
		code = "GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER"; break;
	case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER:
		code = "GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER"; break;
	case GL_FRAMEBUFFER_UNSUPPORTED:
		code = "GL_FRAMEBUFFER_UNSUPPORTED"; break;
	case GL_FRAMEBUFFER_COMPLETE:
		code = "GL_FRAMEBUFFER_COMPLETE"; break;
	default:
		code = watt.conv.toString(status); break;
	}

	watt.io.std.writefln("%s:%s error: %s", file, line, code);
}

uint max(uint x, uint y)
{
	return x > y ? x : y;
}

uint log2(uint x)
{
	uint ans = 0 ;
	while (x = x >> 1) {
		ans++;
	}

	return ans;
}
