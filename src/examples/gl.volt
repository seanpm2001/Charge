// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module examples.gl;

import charge.ctl;
import charge.core;
import charge.game;
import charge.gfx;
import charge.math.matrix;
import charge.sys.resource;


class Game : GameSceneManagerApp
{
public:
	this(string[] args)
	{
		// First init core.
		auto opts = new CoreOptions();
		super(opts);

		auto s = new Scene(this, opts.width, opts.height);
		push(s);
	}
}


class Scene : GameSimpleScene
{
public:
	CtlInput input;
	GfxTexture tex;
	GfxDrawBuffer buf;
	uint width;
	uint height;

public:
	this(Game g, uint width, uint height)
	{
		super(g, Type.Game);
		this.width = width;
		this.height = height;

		input = CtlInput.opCall();

		checkVersion();

		tex = GfxTexture2D.load(Pool.opCall(), "res/logo.png");

		initBuffers();
	}


	/*
	 *
	 * Our own methods and helpers..
	 *
	 */

	void checkVersion()
	{
		// For texture functions.
		if (!GL_ARB_ES3_compatibility &&
		    !GL_ARB_texture_storage &&
		    //!GL_ES_VERSION_3_0 &&
		    !GL_VERSION_4_2) {
			throw new Exception("OpenGL features missing");
		}

		// For shaders.
		if (!GL_ARB_ES2_compatibility &&
		    !GL_ES_VERSION_2_0 &&
		    !GL_VERSION_4_5) {
			throw new Exception("Need OpenGL ES 2.0, GL_ARB_ES2_compatibility or OpenGL 4.5");
		}
	}

	void initBuffers()
	{
		uint texWidth = tex.width;
		uint texHeight = tex.height;
		while (texWidth > width || texHeight > height) {
			texWidth /= 2;
			texHeight /= 2;
		}

		uint x = width / 2 - texWidth / 2;
		uint y = height / 2 - texHeight / 2;

		float fX = cast(float)x;
		float fY = cast(float)y;
		float fXW = cast(float)(x + texWidth);
		float fYH = cast(float)(y + texHeight);

		auto b = new GfxDrawVertexBuilder(4);
		b.add(fX,  fY,  0.0f, 0.0f);
		b.add(fXW, fY,  1.0f, 0.0f);
		b.add(fXW, fYH, 1.0f, 1.0f);
		b.add(fX,  fYH, 0.0f, 1.0f);
		buf = GfxDrawBuffer.make("example/gl/buffer", b);
		b.close();
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override void close()
	{
		if (tex !is null) { tex.decRef(); tex = null; }
		if (buf !is null) { buf.decRef(); buf = null; }
	}

	override void render(GfxTarget t)
	{
		Matrix4x4f mat;
		t.setMatrixToOrtho(ref mat);
		gfxDrawShader.bind();
		gfxDrawShader.matrix4("matrix", 1, true, mat.u.a.ptr);

		// Clear the screen.
		glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glBindVertexArray(buf.vao);
		tex.bind();

		// Draw the triangle.
		glDrawArrays(GL_QUADS, 0, 4);

		tex.unbind();
		glBindVertexArray(0);
		glBlendFunc(GL_ONE, GL_ZERO);
		glDisable(GL_BLEND);
	}

	override void keyDown(CtlKeyboard, int, dchar, scope const(char)[] m)
	{
		mManager.closeMe(this);
	}
}

enum string vertexShader450 = `
#version 450 core

layout (location = 0) in vec2 inPosition;
layout (location = 1) in vec2 inUv;
layout (location = 2) in vec4 inColor;

layout (location = 0) out vec2 outUv;
layout (location = 1) out vec4 outColor;

uniform mat4 matrix;

void main(void)
{
	outUv = inUv;
	outColor = inColor;
	gl_Position = matrix * vec4(inPosition, 0.0, 1.0);
}
`;

enum string fragmentShader450 = `
#version 450 core

layout (location = 0) out vec4 outColor;

layout (location = 0) in vec2 inUv;
layout (location = 1) in vec4 inColor;

layout (binding = 0) uniform sampler2D tex;

void main(void)
{
	outColor = texture(tex, inUv) * inColor;
}
`;

enum string vertexShaderES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

attribute vec2 position;
attribute vec2 uv;
attribute vec4 color;

uniform mat4 matrix;

varying vec2 uvFs;
varying vec4 colorFs;

void main(void)
{
	uvFs = uv;
	colorFs = color;
	gl_Position = matrix * vec4(position, 0.0, 1.0);
}
`;

enum string fragmentShaderES = `
#version 100
#ifdef GL_ES
precision mediump float;
#endif

varying vec2 tx;
uniform sampler2D tex;

varying vec2 uvFs;
varying vec4 colorFs;

void main(void)
{
	vec4 t = texture2D(tex, uvFs);
	gl_FragColor = t * colorFs;
}
`;
