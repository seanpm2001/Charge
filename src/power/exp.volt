// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.exp;

import watt.math;
import watt.io.file;
import watt.algorithm;
import watt.text.format;
import io = watt.io;

import charge.ctl;
import charge.sys.memory;
import charge.sys.resource;
import charge.core;
import charge.game;
import charge.gfx;

import math = charge.math;
import power.voxel;


class Exp : GameSimpleScene
{
public:
	CtlInput input;
	VoxelBuffer vbo;
	float rotation;
	GfxFramebuffer fbo;
	GfxDrawBuffer quad;
	GfxShader voxelShader;
	GfxShader aaShader;
	GLuint sampler;

	GfxTexture2D bitmap;
	GfxDrawBuffer textVbo;
	GfxDrawVertexBuilder textBuilder;
	GfxBitmapState textState;

	GLuint query;
	bool queryInFlight;



	/**
	 * For ray tracing.
	 * @{
	 */
	GLuint octBuffer;
	GLuint octTexture;
	/**
	 * @}
	 */

public:
	this(GameSceneManager g)
	{
		super(g, Type.Game);
		input = CtlInput.opCall();
		vb := new VoxelBuilder(3);
		vb.addCube(0.0f, 0.0f, 0.0f, math.Color4b.White);
		vb.addCube(1.0f, 1.0f, 1.0f, math.Color4b.White);
		vb.addCube(2.0f, 2.0f, 2.0f, math.Color4b.White);
		vbo = VoxelBuffer.make("voxels", vb);

		voxelShader = new GfxShader(voxelVertex450, voxelGeometry450,
			voxelFragment450, null, null);
		aaShader = new GfxShader(aaVertex130, aaFragment130,
		                         ["position"], ["color", "depth"]);


		auto b = new GfxDrawVertexBuilder(4);
		b.add(-1.f, -1.f, -1.f, -1.f);
		b.add( 1.f, -1.f,  1.f, -1.f);
		b.add( 1.f,  1.f,  1.f,  1.f);
		b.add(-1.f,  1.f, -1.f,  1.f);
		quad = GfxDrawBuffer.make("power/exp/quad", b);

		glGenSamplers(1, &sampler);
		glSamplerParameteri(sampler, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glSamplerParameteri(sampler, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		bitmap = GfxTexture2D.load(Pool.opCall(), "res/font.png");

		textState.glyphWidth = cast(int)bitmap.width / 16;
		textState.glyphHeight = cast(int)bitmap.height / 16;
		textState.offX = 16;
		textState.offY = 16;

		text := "Info";
		textBuilder = new GfxDrawVertexBuilder(0);
		textBuilder.reset(text.length * 4u);
		gfxBuildVertices(ref textState, textBuilder, cast(ubyte[])text);
		textVbo = GfxDrawBuffer.make("power/exp/text", textBuilder);

		glGenQueries(1, &query);

		// Setup raytracing code.
		data := read("res/bunny_512x512x512.voxels");

		glGenBuffers(1, &octBuffer);
		glBindBuffer(GL_TEXTURE_BUFFER, octBuffer);
		glBufferData(GL_TEXTURE_BUFFER, cast(GLsizeiptr)data.length, data.ptr, GL_STATIC_DRAW);
		glBindBuffer(GL_TEXTURE_BUFFER, 0);

		glGenTextures(1, &octTexture);
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);
		glTexBuffer(GL_TEXTURE_BUFFER, GL_INTENSITY32UI_EXT, octBuffer);
		glBindTexture(GL_TEXTURE_BUFFER, 0);
	}

	override void close()
	{
		if (fbo !is null) { fbo.decRef(); fbo = null; }
		if (vbo !is null) { vbo.decRef(); vbo = null; }
		if (quad !is null) { quad.decRef(); quad = null; }
		if (bitmap !is null) { bitmap.decRef(); bitmap = null; }
		if (textVbo !is null) { textVbo.decRef(); textVbo = null; }
		if (sampler) { glDeleteSamplers(1, &sampler); sampler = 0; }
		if (octTexture) { glDeleteTextures(1, &octTexture); octTexture = 0; }
		if (octBuffer) { glDeleteBuffers(1, &octBuffer); octBuffer = 0; }
		if (voxelShader !is null) {
			voxelShader.breakApart();
			voxelShader = null;
		}
		if (aaShader !is null) {
			aaShader.breakApart();
			aaShader = null;
		}
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override void logic()
	{
		rotation += 0.01f;
	}

	override void render(GfxTarget t)
	{
		// If there is none or if t has a different size.
		setupFramebuffer(t);


		// Use the fbo
		t.unbind();
		fbo.bind();
		renderScene(fbo);
		fbo.unbind();
		t.bind();


		// Clear the screen.
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		aaShader.bind();

		glBindVertexArray(quad.vao);
		fbo.color.bind();
		glBindSampler(0, sampler);

		glDrawArrays(GL_QUADS, 0, quad.num);

		glBindSampler(0, 0);
		fbo.color.unbind();
		glBindVertexArray(0);


		// Draw text
		updateText();
		math.Matrix4x4f mat;
		t.setMatrixToOrtho(ref mat);

		gfxDrawShader.bind();
		gfxDrawShader.matrix4("matrix", 1, true, mat.u.a.ptr);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glBindVertexArray(textVbo.vao);
		bitmap.bind();

		glDrawArrays(GL_QUADS, 0, textVbo.num);

		bitmap.unbind();
		glBindVertexArray(0);
		glBlendFunc(GL_ONE, GL_ZERO);
		glDisable(GL_BLEND);
	}

	override void keyDown(CtlKeyboard, int, dchar, scope const(char)[] m)
	{
		mManager.closeMe(this);
	}

	void setupFramebuffer(GfxTarget t)
	{
		if (fbo !is null &&
		    (t.width * 2) == fbo.width &&
		    (t.height * 2) == fbo.height) {
			return;
		}

		if (fbo !is null) { fbo.decRef(); fbo = null; }
		fbo = GfxFramebuffer.make("power/exp/fbo", t.width * 2, t.height * 2);
	}

	void renderScene(GfxTarget t)
	{
		// Clear the screen.
		glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgram(0);


		rot := math.Quatf.opCall(rotation, 0.f, 0.f);
		vec := rot * math.Vector3f.opCall(0.f, 0.f, -1.0f);
		pos := math.Point3f.opCall(0.5f, 0.5f, 0.5f) - vec;


		math.Matrix4x4f view;
		view.setToLookFrom(ref pos, ref rot);

		math.Matrix4x4f proj;
		t.setMatrixToProjection(ref proj, 45.f, 0.1f, 256.f);
		proj.setToMultiply(ref view);

		// Setup shader.
		voxelShader.bind();
		voxelShader.matrix4("matrix", 1, true, proj.ptr);
		voxelShader.float3("cameraPos".ptr, 1, pos.ptr);

		shouldEnd: bool;
		if (!queryInFlight) {
			glBeginQuery(GL_TIME_ELAPSED, query);
			shouldEnd = true;
		}

		// Draw the array.
		glCullFace(GL_BACK);
		glEnable(GL_CULL_FACE);
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);
		glBegin(GL_POINTS);
		int max = 32;
		foreach (x; 0 .. max) {
			foreach (y; 0 .. max) {
				foreach (z; 0 .. max) {
					glVertex3i(x, y, z);
				}
			}
		}
		glEnd();
		glBindTexture(GL_TEXTURE_BUFFER, 0);
		glDisable(GL_CULL_FACE);

		if (shouldEnd) {
			glEndQuery(GL_TIME_ELAPSED);
			queryInFlight = true;
		}

		glUseProgram(0);
		glDisable(GL_DEPTH_TEST);
	}

	void updateText()
	{
		if (!queryInFlight) {
			return;
		}

		available: GLint;
		glGetQueryObjectiv(query, GL_QUERY_RESULT_AVAILABLE, &available);
		if (!available) {
			return;
		}

		timeElapsed: GLuint64;
		glGetQueryObjectui64v(query, GL_QUERY_RESULT, &timeElapsed);
		queryInFlight = false;

		str := `Info:
Elapsed time: %sms`;

		text := format(str, timeElapsed / 1_000_000_000.0 * 1_000.0);

		textBuilder.reset(text.length * 4u);
		gfxBuildVertices(ref textState, textBuilder, cast(ubyte[])text);
		textVbo.update(textBuilder);
	}
}

enum string voxelVertex450 = `
#version 450 core

layout (location = 0) in vec3 inPosition;

void main(void)
{
	gl_Position = vec4(inPosition, 1.0);
}
`;

enum string voxelGeometry450 = `
#version 450 core

#define POW 5
#define DIVISOR pow(2, float(POW))
#define DIVISOR_INV (1.0/DIVISOR)

layout (points) in;

layout (binding = 0) uniform isamplerBuffer octree;

layout (triangle_strip, max_vertices = 24) out;

layout (location = 0) out vec3 outPosition;
layout (location = 1) out vec3 outMinEdge;
layout (location = 2) out vec3 outMaxEdge;
layout (location = 3) out flat int outOffset;

uniform mat4 matrix;

void emit(vec3 off)
{
	vec3 pos = gl_in[0].gl_Position.xyz;
	pos += off;
	pos *= DIVISOR_INV;
	outPosition = pos;
	gl_Position = matrix * vec4(pos, 1.0);
	EmitVertex();
}

bool findStart(vec3 pos, out int offset)
{
	// Which part of the space the voxel volume occupy.
	vec3 boxMin = vec3(0.0);
	vec3 boxDim = vec3(1.0);

	// Initial node address.
	offset = 0;

	// Jitter
	pos += vec3(0.00001);

	// Subdivid until empty node or found the node for this box.
	for (int i = POW; i > 0; i--) {
		// Get the node.
		uint node = uint(texelFetchBuffer(octree, offset).a);

		// Found empty node, so return false to not emit a box.
		// We could have hit this if we hit a color.
		if ((node & uint(0xC0000000)) != uint(0)) {
			return false;
		}

		boxDim *= 0.5f;
		vec3 s = step(boxMin + boxDim, pos);
		boxMin = boxMin + boxDim * s;
		offset = int((node & uint(0x3FFFFFFF)) + uint(dot(s, vec3(1, 2, 4))));
	}

	return true;
}

void main(void)
{
	vec3 pos = gl_in[0].gl_Position.xyz;
	outMinEdge = pos * DIVISOR_INV;
	outMaxEdge = outMinEdge + vec3(1.0) * DIVISOR_INV;

	if (!findStart(outMinEdge, outOffset)) {
		return;
	}

	emit(vec3(1.0, 1.0, 0.0));
	emit(vec3(0.0, 1.0, 0.0));
	emit(vec3(1.0, 0.0, 0.0));
	emit(vec3(0.0, 0.0, 0.0));
	EndPrimitive();

	emit(vec3(0.0, 0.0, 1.0));
	emit(vec3(0.0, 1.0, 1.0));
	emit(vec3(1.0, 0.0, 1.0));
	emit(vec3(1.0, 1.0, 1.0));
	EndPrimitive();

	emit(vec3(0.0, 0.0, 0.0));
	emit(vec3(0.0, 0.0, 1.0));
	emit(vec3(1.0, 0.0, 0.0));
	emit(vec3(1.0, 0.0, 1.0));
	EndPrimitive();

	emit(vec3(1.0, 1.0, 1.0));
	emit(vec3(0.0, 1.0, 1.0));
	emit(vec3(1.0, 1.0, 0.0));
	emit(vec3(0.0, 1.0, 0.0));
	EndPrimitive();

	emit(vec3(1.0, 1.0, 1.0));
	emit(vec3(1.0, 1.0, 0.0));
	emit(vec3(1.0, 0.0, 1.0));
	emit(vec3(1.0, 0.0, 0.0));
	EndPrimitive();

	emit(vec3(0.0, 0.0, 0.0));
	emit(vec3(0.0, 1.0, 0.0));
	emit(vec3(0.0, 0.0, 1.0));
	emit(vec3(0.0, 1.0, 1.0));
	EndPrimitive();
}
`;

enum string voxelFragment450 = `
#version 450 core
#define MAX_ITERATIONS 500

layout (location = 0) in vec3 inPosition;
layout (location = 1) in vec3 inMinEdge;
layout (location = 2) in vec3 inMaxEdge;
layout (location = 3) in flat int inOffset;
layout (binding = 0) uniform isamplerBuffer octree;
layout (location = 0) out vec4 outColor;

uniform vec3 cameraPos;


vec3 rayAABBTest(vec3 rayOrigin, vec3 rayDir, vec3 aabbMin, vec3 aabbMax)
{
	float tMin, tMax;

	// Project ray through aabb
	vec3 invRayDir = 1.0 / rayDir;
	vec3 t1 = (aabbMin - rayOrigin) * invRayDir;
	vec3 t2 = (aabbMax - rayOrigin) * invRayDir;
	
	vec3 tmin = min(t1, t2);
	vec3 tmax = max(t1, t2);
	
	tMin = max(max(0.0, tmin.x), max(tmin.y, tmin.z));
	tMax = min(min(99999.0, tmax.x), min(tmax.y, tmax.z));
	
	vec3 result;
	result.x = (tMax > tMin) ? 1.0 : 0.0;
	result.y = tMin;
	result.z = tMax;
	return result;
}

bool trace(out vec4 finalColor, vec3 rayDir, vec3 rayOrigin)
{
	//rayOrigin -= vec3(0.0, 0.5, 0.0);

	// Check for ray components being parallel to axes (i.e. values of 0).
	const float epsilon = 0.000001;	// Platform dependent value!
	if (abs(rayDir.x) <= epsilon) rayDir.x = epsilon * sign(rayDir.x);
	if (abs(rayDir.y) <= epsilon) rayDir.y = epsilon * sign(rayDir.y);
	if (abs(rayDir.z) <= epsilon) rayDir.z = epsilon * sign(rayDir.z);

	// Calculate inverse of ray direction once.
	vec3 invRayDir = 1.0 / rayDir;

	// Store maximum extents of voxel volume.
	vec3 minEdge = inMinEdge;
	vec3 maxEdge = inMaxEdge;
	float bias = maxEdge.x / 1000000.0;

	// Only process ray if it intersects voxel volume.
	float tMin, tMax;
	vec3 result = rayAABBTest(rayOrigin, rayDir, minEdge, maxEdge);
	tMin = result.y;
	tMax = result.z;

	float depth = 1.0;

	if (result.x <= 0.0) {
		return false;
	}

	// Force initial ray position to start at the
	// camera origin if it is in the voxel box.
	tMin = max(0.0f, tMin);

	// Loop until ray exits volume.
	int itr = 0;
	while (tMin < tMax && ++itr < MAX_ITERATIONS) {
		vec3 pos = rayOrigin + rayDir * tMin;
		uint node = uint(texelFetchBuffer(octree, inOffset).a);
		// Which part of the space the voxel volume occupy.
		vec3 boxMin = inMinEdge;
		vec3 boxDim = inMaxEdge - inMinEdge;

		// Loop until a leaf or max subdivided node is found.
		while ((node & uint(0xC0000000)) == uint(0)) {
			boxDim *= 0.5f;
			vec3 s = step(boxMin + boxDim, pos);
			boxMin = boxMin + boxDim * s;
			uint offset = (node & uint(0x3FFFFFFF)) + uint(dot(s, vec3(1, 2, 4)));
			node = uint(texelFetchBuffer(octree, int(offset)).a);
		}

		// If final node is a leaf, extract color and exit loop.
		if ((node & uint(0x80000000)) >> uint(31) == uint(1)) {
			uint alpha = (node & uint(0x3F000000)) >> uint(24);
			uint red = (node & uint(0x00FF0000)) >> uint(16);
			uint green = (node & uint(0x0000FF00)) >> uint(8);
			uint blue = (node & uint(0x000000FF));

			alpha = alpha * uint(255) / uint(63);
			alpha /= uint(2);
			finalColor = vec4(red, green, blue, 255) / 255.0;
			return true;

/*
			// Record intersection depth point.
			vec3 t0 = (boxMin - rayOrigin) * invRayDir;
			vec3 t1 = (boxMin + boxDim - rayOrigin) * invRayDir;
			vec3 tIntersection = min(t0, t1);
			vec3 point = rayOrigin + rayDir * tIntersection;
			point = point / (maxEdge - minEdge);
			depth = clamp(point.z, 0.0, 1.0);
			hit = true;
			break;
*/
		}

		// Update ray position to exit current node			
		vec3 t0 = (boxMin - pos) * invRayDir;
		vec3 t1 = (boxMin + boxDim - pos) * invRayDir;
		vec3 tNext = max(t0, t1);
		tMin += min(tNext.x, min(tNext.y, tNext.z)) + bias;
	}

	if (itr == MAX_ITERATIONS) {
		finalColor = vec4(0, 1, 0, 1);
		return false;
	}

	return false;
}

void main(void)
{
	vec3 rayDir = normalize(inPosition - cameraPos);
	vec3 rayOrigin = inPosition;

	if (!trace(outColor, rayDir, rayOrigin)) {
		discard;
	}
}
`;

enum string aaVertex130 = `
#version 130

attribute vec2 position;

varying vec2 uvFS;


void main(void)
{
	uvFS = (position / 2 + 0.5);
	uvFS.y = 1 - uvFS.y;
	gl_Position = vec4(position, 0.0, 1.0);
}
`;

enum string aaFragment130 = `
#version 130

uniform sampler2D color;

varying vec2 uvFS;


void main(void)
{
	// Get color.
	vec4 c = texture(color, uvFS);

	gl_FragColor = vec4(c.xyz, 1.0);
}
`;
