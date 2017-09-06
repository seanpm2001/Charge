// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module power.experiments.brute;

import io = watt.io;

import watt.math;
import watt.io.file;
import watt.algorithm;
import watt.text.format;

import sys = charge.sys;
import ctl = charge.ctl;
import gfx = charge.gfx;
import math = charge.math;
import game = charge.game;

import charge.core;
import charge.gfx.gl;
import charge.sys.memory;

import power.voxel.boxel;
import power.voxel.dag;
import power.experiments.viewer;


class Brute : Viewer
{
public:
	first: DagBuffer;
	second: DagBuffer;
	third: DagBuffer;
	ibo: IndirectBuffer;
	voxelShader: gfx.Shader;

	feedback: GLuint;
	feedbackShader: gfx.Shader;

	query: GLuint;
	fbQuery: GLuint;
	queryInFlight: bool;


	/*!
	 * For ray tracing.
	 * @{
	 */
	octBuffer: GLuint;
	octTexture: GLuint;
	/*!
	 * @}
	 */


public:
	this(g: game.SceneManager)
	{
		super(g);
		distance = 1.0;

		vert := cast(string)read("res/power/shaders/brute/voxel.vert.glsl");
		geom := cast(string)read("res/power/shaders/brute/voxel.geom.glsl");
		frag := cast(string)read("res/power/shaders/brute/voxel.frag.glsl");
		voxelShader = new gfx.Shader("brute-voxel", vert, geom, frag);

		vert = cast(string)read("res/power/shaders/brute/feedback.vert.glsl");
		geom = cast(string)read("res/power/shaders/brute/feedback.geom.glsl");
		frag = cast(string)read("res/power/shaders/brute/feedback.frag.glsl");
		feedbackShader = new gfx.Shader("brute-feedback", vert, geom, frag);

		glGenQueries(1, &query);
		glGenQueries(1, &fbQuery);

		// Setup raytracing code.
		data := read("res/bunny_512x512x512.voxels");

		glGenBuffers(1, &octBuffer);
		glBindBuffer(GL_TEXTURE_BUFFER, octBuffer);
		glBufferData(GL_TEXTURE_BUFFER, cast(GLsizeiptr)data.length, data.ptr, GL_STATIC_DRAW);
		glBindBuffer(GL_TEXTURE_BUFFER, 0);

		glGenTextures(1, &octTexture);
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);
		glTexBuffer(GL_TEXTURE_BUFFER, GL_R32UI, octBuffer);
		glBindTexture(GL_TEXTURE_BUFFER, 0);

		maxFirst : size_t = 1;
		maxSecond : size_t = cast(size_t)(8 * 8 * 8);
		maxThird : size_t = cast(size_t)(64 * 64 * 64);

		first = DagBuffer.make("power/dag/second", cast(GLsizei)maxFirst, maxFirst);
		second = DagBuffer.make("power/dag/second", cast(GLsizei)maxSecond, maxSecond);
		third = DagBuffer.make("power/dag/second", cast(GLsizei)maxThird, maxThird);
		ibo = IndirectBuffer.make("power/ido", 1, cast(GLuint)(8*8*8));
	}


	/*
	 *
	 * Scene methods.
	 *
	 */

	override fn close()
	{
		super.close();

		gfx.destroy(ref voxelShader);
		if (octTexture) { glDeleteTextures(1, &octTexture); octTexture = 0; }
		if (octBuffer) { glDeleteBuffers(1, &octBuffer); octBuffer = 0; }
	}


	/*
	 *
	 * Viewer methods.
	 *
	 */

	override fn renderScene(t: gfx.Target)
	{
		// Clear the screen.
		glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glUseProgram(0);


		view: math.Matrix4x4d;
		view.setToLookFrom(ref camPosition, ref camRotation);

		proj: math.Matrix4x4d;
		t.setMatrixToProjection(ref proj, 45.f, 0.1f, 256.f);

		mvp: math.Matrix4x4f;
		mvp.setToMultiplyAndTranspose(ref proj, ref view);

		shouldEnd: bool;
		if (!queryInFlight) {
			glBeginQuery(GL_TIME_ELAPSED, query);
			shouldEnd = true;
		}

		// Draw the array.
		glCullFace(GL_BACK);
		glEnable(GL_CULL_FACE);
		glBindTexture(GL_TEXTURE_BUFFER, octTexture);

		// Setup shader.
		feedbackShader.bind();

		//
		// First feedback step
		//
		glEnable(GL_RASTERIZER_DISCARD);
		glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, second.buf);

		glBeginQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN, fbQuery);
		glBeginTransformFeedback(GL_POINTS);
		glBindVertexArray(first.vao);
		glDrawArrays(GL_POINTS, 0, 8*8*8);
		glBindVertexArray(0);
		glEndTransformFeedback();
		glEndQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN);

		// Feedback the number of read objects into indirect buffer.
		glBindBuffer(GL_QUERY_BUFFER, ibo.buf);
		glGetQueryObjectuiv(fbQuery, GL_QUERY_RESULT, (cast(GLuint*)null) + 1);
		glBindBuffer(GL_QUERY_BUFFER, 0);

		//
		// Second feedback stage
		//
		glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, third.buf);
		glBeginQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN, fbQuery);
		glBeginTransformFeedback(GL_POINTS);

		glBindVertexArray(second.vao);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, ibo.buf);
		glDrawArraysIndirect(GL_POINTS, null);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, 0);
		glBindVertexArray(0);

		glEndTransformFeedback();
		glEndQuery(GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN);

		glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, 0);
		glDisable(GL_RASTERIZER_DISCARD);

		// Feedback the number of read objects into indirect buffer.
		glBindBuffer(GL_QUERY_BUFFER, ibo.buf);
		glGetQueryObjectuiv(fbQuery, GL_QUERY_RESULT, (cast(GLuint*)null) + 1);
		glBindBuffer(GL_QUERY_BUFFER, 0);

		// Setup shader.
		voxelShader.bind();
		voxelShader.matrix4("matrix", 1, true, ref mvp);
		voxelShader.float3("cameraPos".ptr, 1, camPosition.ptr);

		// Draw voxels
		glEnable(GL_PROGRAM_POINT_SIZE);
		glBindVertexArray(third.vao);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, ibo.buf);
		glDrawArraysIndirect(GL_POINTS, null);
		glBindBuffer(GL_DRAW_INDIRECT_BUFFER, 0);
		glBindVertexArray(0);
		glDisable(GL_PROGRAM_POINT_SIZE);

		glBindTexture(GL_TEXTURE_BUFFER, 0);
		glDisable(GL_CULL_FACE);

		if (shouldEnd) {
			glEndQuery(GL_TIME_ELAPSED);
			queryInFlight = true;
		}

		glUseProgram(0);
		glDisable(GL_DEPTH_TEST);

		// Check for last frames query.
		checkQuery();
	}

	fn checkQuery()
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

		str := "Info:\nElapsed time: %sms";

		text := format(str, timeElapsed / 1_000_000_000.0 * 1_000.0);

		updateText(text);
	}
}

struct IndirectData
{
	count: GLuint;
	instanceCount: GLuint;
	first: GLuint;
	baseInstance: GLuint;
}

/*!
 * Inderect buffer used for drawing.
 */
class IndirectBuffer : sys.Resource
{
public:
	buf: GLuint;
	num: GLsizei;


public:
	~this()
	{
		if (buf) { glDeleteBuffers(1, &buf); buf = 0; }
	}

	global fn make(name: string, num: GLsizei, count: GLuint) IndirectBuffer
	{
		dummy: void*;
		buffer := cast(IndirectBuffer)sys.Resource.alloc(
			typeid(IndirectBuffer), gfx.Buffer.uri, name, 0, out dummy);
		buffer.__ctor(num, count);
		return buffer;
	}


protected:
	this(num: GLsizei, count: GLuint)
	{
		super();
		this.num = num;

		data: IndirectData;
		data.count = count;
		data.instanceCount = 1;

		indirectStride := cast(GLsizei)typeid(IndirectData).size;
		indirectLength := num * indirectStride;

		// First allocate the storage.
		glCreateBuffers(1, &buf);
		glNamedBufferStorage(buf, indirectLength, null, GL_DYNAMIC_STORAGE_BIT);

		// Then fill out the first slot.
		glNamedBufferSubData(buf, 0, indirectStride, cast(void*)&data);

		glCheckError();
	}
}


struct InstanceData
{
	position, offset: u32;
}

/*!
 * VBO used for boxed base voxels.
 */
class DagBuffer : gfx.Buffer
{
public:
	num: GLsizei;

public:
	global fn make(name: string, num: GLsizei, instances: size_t) DagBuffer
	{
		dummy: void*;
		buffer := cast(DagBuffer)sys.Resource.alloc(
			typeid(DagBuffer), uri, name, 0, out dummy);
		buffer.__ctor(num, instances);
		return buffer;
	}

protected:
	this(num: GLsizei, instances: size_t)
	{
		super(0, 0);
		this.num = num;

		// Setup instance buffer and upload the data.
		glGenBuffers(1, &buf);
		glGenVertexArrays(1, &vao);

		// And the darkness bind them.
		glBindVertexArray(vao);

		glBindBuffer(GL_ARRAY_BUFFER, buf);

		instanceStride := cast(GLsizei)typeid(InstanceData).size;
		instancesLength := cast(GLsizei)instances * instanceStride;
		glBindBuffer(GL_ARRAY_BUFFER, buf);
		glBufferData(GL_ARRAY_BUFFER, cast(GLsizeiptr)instancesLength, null, GL_STATIC_DRAW);

		glVertexAttribIPointer(0, 4, GL_UNSIGNED_BYTE, instanceStride, null);
		glVertexAttribIPointer(1, 1, GL_UNSIGNED_INT, instanceStride, cast(void*)4);
		glVertexAttribDivisor(0, 1);
		glVertexAttribDivisor(1, 1);
		glEnableVertexAttribArray(0);
		glEnableVertexAttribArray(1);

		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindVertexArray(0);
	}
}
