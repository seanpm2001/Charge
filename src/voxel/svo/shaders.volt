// Copyright © 2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/license.volt (BOOST ver. 1.0).
module voxel.svo.shaders;

import io = watt.io;

import watt.text.string;
import watt.text.format;

import gfx = charge.gfx;
import math = charge.math;

import charge.gfx.gl;

import voxel.svo.util;
import voxel.svo.design;
import voxel.svo.shaders;
import voxel.svo.pipeline;


/*!
 * The state that is passed to each step when we are running the pipeline.
 */
struct StepState
{
	matrix: math.Matrix4x4f;
	planes: math.Planef[4];
	camPosition: math.Point3f; frame: u32;
	pointScale: f32;

	// State for helpers not shaders.
	buffers: GLuint[BufferNum];
	atomicBuffer: GLuint;
	commandBuffer: GLuint;
}

private global voxelShaderStoreStore: ShaderStore[const(u32)[]];

fn getStore(ref c: Create) ShaderStore
{
	key := [cast(u32)c.isAMD];
	s := key in voxelShaderStoreStore;
	if (s !is null) {
		return *s;
	}

	store := new ShaderStore(c.isAMD);
	voxelShaderStoreStore[key] = store;
	return store;
}

/*!
 * Helper class to build a rendering pipeline.
 */
class StepsBuilder
{
public:
	s: ShaderStore;
	endLevelOfBuf: u32[BufferNum];
	tracker: BufferTracker;


public:
	this(s: ShaderStore)
	{
		this.s = s;
		tracker.setup(BufferNum);
		assert(this.s !is null);
	}

	fn makeInit(out dst: u32) InitStep
	{
		// Setup the pipeline steps.
		dst = tracker.get(); // Produce
		endLevelOfBuf[dst] = 0;
		return new InitStep(dst);
	}

	fn makeList1(src: u32, powerLevels: u32, out dst: u32) ListStep
	{
		powerStart := endLevelOfBuf[src];

		// Track used buffers and level they produce.
		dst = tracker.get(); // Produce
		tracker.free(src);   // Consume
		endLevelOfBuf[dst] = powerStart + powerLevels;
		return new ListStep(s, src, dst, 0, powerStart, powerLevels, 0.0f);
	}

	fn makeListDouble(src: u32, out dst: u32) ListDoubleStep
	{
		powerLevels := 2u;
		powerStart := endLevelOfBuf[src];

		// Track used buffers and level they produce.
		dst = tracker.get(); // Produce
		tracker.free(src);   // Consume
		endLevelOfBuf[dst] = powerStart + powerLevels;
		return new ListDoubleStep(s, src, dst, 0, powerStart);
	}

	fn makeList2(src: u32, powerLevels: u32, distance: f32,
	             out dst1: u32, out dst2: u32) ListStep
	{
		powerStart := endLevelOfBuf[src];

		// Track used buffers and level they produce.
		dst1 = tracker.get(); // Produce
		dst2 = tracker.get(); // Produce
		tracker.free(src);    // Consume
		endLevelOfBuf[dst1] = powerStart + powerLevels;
		endLevelOfBuf[dst2] = powerStart + powerLevels;
		return new ListStep(s, src, dst1, dst2, powerStart, powerLevels, distance);
	}

	fn makeCubes(src: u32) CubeStep
	{
		powerStart := endLevelOfBuf[src];
		tracker.free(src); // Consume
		return new CubeStep(s, src, powerStart);
	}

	fn makePoints(src: u32) PointsStep
	{
		powerStart := endLevelOfBuf[src];
		tracker.free(src); // Consume
		return new PointsStep(s, src, powerStart);
	}

	fn makeRayDouble(src: u32) RayDoubleStep
	{
		powerStart := endLevelOfBuf[src];
		tracker.free(src); // Consume
		return new RayDoubleStep(s, src, powerStart);
	}
}

/*!
 * Base class for all steps in a rendering pipeline.
 */
abstract class Step
{
public:
	name: string;


public:
	abstract fn run(ref state: StepState);
}

/*!
 * First step of any rendering pipeline.
 */
class InitStep : Step
{
public:
	dst: u32;


public:
	this(dst: u32)
	{
		this.name = "init";
		this.dst = dst;
	}

	override fn run(ref state: StepState)
	{
		frame := state.frame;
		one := 1;
		offset := cast(GLintptr)(dst * 4);

		// Make sure memory is all in place.
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);

		glClearNamedBufferData(state.commandBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
		glClearNamedBufferData(state.atomicBuffer, GL_R32UI, GL_RED, GL_UNSIGNED_INT, null);
		glNamedBufferSubData(state.atomicBuffer, offset, 4, cast(void*)&one);
		glNamedBufferSubData(state.buffers[dst], 0, 16, cast(void*)[0, 0, frame, 0].ptr);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
	}
}

class ListStep : Step
{
public:
	dispatchShader: gfx.Shader;
	listShader: gfx.Shader;


public:
	this(s: ShaderStore, src: u32, dst1: u32, dst2: u32,
	     powerStart: u32, powerLevels: u32, distance: f32)
	{
		this.name = "list";

		dispatchShader = s.makeComputeDispatchShader(src, BufferCommandId);
		listShader = s.makeListShader(src, dst1, dst2, powerStart, powerLevels, distance);
	}

	override fn run(ref state: StepState)
	{
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		listShader.bind();
		listShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		listShader.matrix4("uMatrix", 1, false, ref state.matrix);
		listShader.float4("uPlanes".ptr, 4, &state.planes[0].a);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glDispatchComputeIndirect(0);
	}
}

class ListDoubleStep : Step
{
public:
	dispatchShader: gfx.Shader;
	listShader: gfx.Shader;


public:
	this(s: ShaderStore, src: u32, dst1: u32, dst2: u32, powerStart: u32)
	{
		this.name = "double";

		dispatchShader = s.makeComputeDispatchShader(src, BufferCommandId);
		listShader = s.makeListDoubleShader(src, dst1, dst2, powerStart);
	}

	override fn run(ref state: StepState)
	{
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);
//		// Test code
//		glCopyBufferSubData(
//			GL_ATOMIC_COUNTER_BUFFER,
//			GL_DISPATCH_INDIRECT_BUFFER,
//			src * 4, 0, 4);
//		glClearBufferSubData(GL_ATOMIC_COUNTER_BUFFER, GL_R32UI, src * 4, 4, GL_UNSIGNED_INT, GL_RED, null);

		listShader.bind();
		listShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		listShader.matrix4("uMatrix", 1, false, ref state.matrix);
		listShader.float4("uPlanes".ptr, 4, &state.planes[0].a);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glDispatchComputeIndirect(0);
	}
}

class CubeStep : Step
{
public:
	dispatchShader: gfx.Shader;
	drawShader: gfx.Shader;


public:
	this(s: ShaderStore, src: u32, powerStart: u32)
	{
		this.name = "cubes";

		dispatchShader = s.makeElementsDispatchShader(src, BufferCommandId);
		drawShader = s.makeCubesShader(src, powerStart);
	}

	override fn run(ref state: StepState)
	{
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		drawShader.bind();
		drawShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		drawShader.matrix4("uMatrix", 1, false, ref state.matrix);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glDrawElementsIndirect(GL_TRIANGLE_STRIP, GL_UNSIGNED_INT, null);
	}
}

class RayStep : Step
{
public:
	dispatchShader: gfx.Shader;
	drawShader: gfx.Shader;


public:
	this(s: ShaderStore, src: u32, powerStart: u32, powerLevels: u32)
	{
		this.name = "ray";

		dispatchShader = s.makeElementsDispatchShader(src, BufferCommandId);
		drawShader = s.makeRayShader(src, powerStart, powerLevels);
	}

	override fn run(ref state: StepState)
	{
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		drawShader.bind();
		drawShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		drawShader.matrix4("uMatrix", 1, false, ref state.matrix);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glDrawElementsIndirect(GL_TRIANGLE_STRIP, GL_UNSIGNED_INT, null);
	}
}

class RayDoubleStep : Step
{
public:
	dispatchShader: gfx.Shader;
	drawShader: gfx.Shader;


public:
	this(s: ShaderStore, src: u32, powerStart: u32)
	{
		this.name = "raydouble";

		dispatchShader = s.makeElementsDispatchShader(src, BufferCommandId);
		drawShader = s.makeRayDoubleShader(src, powerStart);
	}

	override fn run(ref state: StepState)
	{
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		drawShader.bind();
		drawShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		drawShader.matrix4("uMatrix", 1, false, ref state.matrix);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glDrawElementsIndirect(GL_TRIANGLE_STRIP, GL_UNSIGNED_INT, null);
	}
}

class PointsStep : Step
{
public:
	dispatchShader: gfx.Shader;
	drawShader: gfx.Shader;


public:
	this(s: ShaderStore, src: u32, powerStart: u32)
	{
		this.name = "points";

		dispatchShader = s.makeArrayDispatchShader(src, BufferCommandId);
		drawShader = s.makePointsShader(src, powerStart);
	}

	override fn run(ref state: StepState)
	{
		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT);
		dispatchShader.bind();
		glDispatchCompute(1u, 1u, 1u);

		drawShader.bind();
		drawShader.float3("uCameraPos".ptr, state.camPosition.ptr);
		drawShader.matrix4("uMatrix", 1, false, ref state.matrix);
		drawShader.float1("uPointScale".ptr, state.pointScale);

		glMemoryBarrier(GL_ALL_BARRIER_BITS);
//		glMemoryBarrier(GL_ATOMIC_COUNTER_BARRIER_BIT |
//		                GL_SHADER_STORAGE_BARRIER_BIT |
//		                GL_COMMAND_BARRIER_BIT);
		glEnable(GL_PROGRAM_POINT_SIZE);
		glDrawArraysIndirect(GL_POINTS, null);
		glDisable(GL_PROGRAM_POINT_SIZE);
	}
}

/*!
 * Cache shaders so they can be resude between different passes and models.
 */
class ShaderStore
{
protected:
	mShaderStore: gfx.Shader[string];
	mIsAMD: bool;


public:
	this(isAMD: bool)
	{
		this.mIsAMD = isAMD;

		makeComputeDispatchShader(0, BufferCommandId);
		makeComputeDispatchShader(1, BufferCommandId);
		makeComputeDispatchShader(2, BufferCommandId);
		makeComputeDispatchShader(3, BufferCommandId);
		makeElementsDispatchShader(0, BufferCommandId);
		makeArrayDispatchShader(0, BufferCommandId);
	}

	fn makeComputeDispatchShader(src: u32, dst: u32) gfx.Shader
	{
		name := format("svo.dispatch-comp (src: %s, dst: %s)", src, dst);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)import("voxel/indirect-dispatch.comp.glsl");
		comp = replaceCommon(comp);
		comp = replace(comp, "%INDIRECT_SRC%", format("%s", src));
		comp = replace(comp, "%INDIRECT_DST%", format("%s", dst));

		s := new gfx.Shader(name, comp);
		mShaderStore[name] = s;
		return s;
	}

	fn makeElementsDispatchShader(src: u32, dst: u32) gfx.Shader
	{
		name := format("svo.dispatch-elements (src: %s, dst: %s)", src, dst);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)import("voxel/indirect-elements.comp.glsl");
		comp = replaceCommon(comp);
		comp = replace(comp, "%INDIRECT_SRC%", format("%s", src));
		comp = replace(comp, "%INDIRECT_DST%", format("%s", dst));

		s := new gfx.Shader(name, comp);
		mShaderStore[name] = s;
		return s;
	}

	fn makeArrayDispatchShader(src: u32, dst: u32) gfx.Shader
	{
		name := format("svo.dispatch-array (src: %s, dst: %s)", src, dst);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)import("voxel/indirect-array.comp.glsl");
		comp = replaceCommon(comp);
		comp = replace(comp, "%INDIRECT_SRC%", format("%s", src));
		comp = replace(comp, "%INDIRECT_DST%", format("%s", dst));

		s := new gfx.Shader(name, comp);
		mShaderStore[name] = s;
		return s;
	}

	fn makeListShader(src: u32, dst1: u32, dst2: u32,
	                  powerStart: u32, powerLevels: u32, dist: f32) gfx.Shader
	{
		name := format("svo.walk (src: %s, dst1: %s, dst2: %s, powerStart: %s, powerLevels: %s, dist: %s)",
			src, dst1, dst2, powerStart, powerLevels, dist);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)import("voxel/walk-generic.comp.glsl");
		comp = replaceCommon(comp);
		comp = replace(comp, "%VOXEL_SRC%", format("%s", src));
		comp = replace(comp, "%VOXEL_DST1%", format("%s", dst1));
		comp = replace(comp, "%VOXEL_DST2%", format("%s", dst2));
		comp = replace(comp, "%POWER_START%", format("%s", powerStart));
		comp = replace(comp, "%POWER_LEVELS%", format("%s", powerLevels));
		comp = replace(comp, "%POWER_DISTANCE%", format("%s", dist));
		if (dist > 0.0001) {
			comp = replace(comp, "#undef LIST_DO_TAG", "#define LIST_DO_TAG");
		}
		s := new gfx.Shader(name, comp);
		mShaderStore[name] = s;
		return s;
	}

	fn makeListDoubleShader(src: u32, dst1: u32, dst2: u32, powerStart: u32) gfx.Shader
	{
		name := format("svo.walk-double (src: %s, dst1: %s, dst2: %s, powerStart: %s)",
			src, dst1, dst2, powerStart);
		if (s := name in mShaderStore) {
			return *s;
		}

		comp := cast(string)import("voxel/walk-double.comp.glsl");
		comp = replaceCommon(comp);
		comp = replace(comp, "%VOXEL_SRC%", format("%s", src));
		comp = replace(comp, "%VOXEL_DST1%", format("%s", dst1));
		comp = replace(comp, "%VOXEL_DST2%", format("%s", dst2));
		comp = replace(comp, "%POWER_START%", format("%s", powerStart));
		s := new gfx.Shader(name, comp);
		mShaderStore[name] = s;
		return s;
	}

	fn makeCubesShader(src: u32, powerStart: u32) gfx.Shader
	{
		name := format("svo.cube (src: %s, start: %s)",
			src, powerStart);
		if (s := name in mShaderStore) {
			return *s;
		}

		vert := cast(string)import("voxel/cube.vert.glsl");
		vert = replaceCommon(vert);
		vert = replace(vert, "%VOXEL_SRC%", format("%s", src));
		vert = replace(vert, "%POWER_START%", format("%s", powerStart));
		vert = replace(vert, "%POWER_LEVELS%", "0");
		frag := cast(string)import("voxel/cube-ray.frag.glsl");
		frag = replaceCommon(frag);
		frag = replace(frag, "%VOXEL_SRC%", format("%s", src));
		frag = replace(frag, "%POWER_START%", format("%s", powerStart));
		frag = replace(frag, "%POWER_LEVELS%", "0");

		s := new gfx.Shader(name, vert, null, frag);
		mShaderStore[name] = s;
		return s;
	}

	fn makeRayShader(src: u32, powerStart: u32, powerLevels: u32) gfx.Shader
	{
		name := format("svo.cube-ray (src: %s, start: %s, levels: %s)",
			src, powerStart, powerLevels);
		if (s := name in mShaderStore) {
			return *s;
		}

		vert := cast(string)import("voxel/cube.vert.glsl");
		vert = replaceCommon(vert);
		vert = replace(vert, "%VOXEL_SRC%", format("%s", src));
		vert = replace(vert, "%POWER_START%", format("%s", powerStart));
		vert = replace(vert, "%POWER_LEVELS%", format("%s", powerLevels));
		frag := cast(string)import("voxel/cube-ray.frag.glsl");
		frag = replaceCommon(frag);
		frag = replace(frag, "%VOXEL_SRC%", format("%s", src));
		frag = replace(frag, "%POWER_START%", format("%s", powerStart));
		frag = replace(frag, "%POWER_LEVELS%", format("%s", powerLevels));

		s := new gfx.Shader(name, vert, null, frag);
		mShaderStore[name] = s;
		return s;
	}

	fn makeRayDoubleShader(src: u32, powerStart: u32) gfx.Shader
	{
		name := format("svo.cube-ray-double (src: %s, start: %s)",
			src, powerStart);
		if (s := name in mShaderStore) {
			return *s;
		}

		vert := cast(string)import("voxel/cube.vert.glsl");
		vert = replaceCommon(vert);
		vert = replace(vert, "%VOXEL_SRC%", format("%s", src));
		vert = replace(vert, "%POWER_START%", format("%s", powerStart));

		frag := cast(string)import("voxel/cube-ray-double.frag.glsl");
		frag = replaceCommon(frag);
		frag = replace(frag, "%VOXEL_SRC%", format("%s", src));
		frag = replace(frag, "%POWER_START%", format("%s", powerStart));

		s := new gfx.Shader(name, vert, null, frag);
		mShaderStore[name] = s;
		return s;
	}

	fn makePointsShader(src: u32, powerStart: u32) gfx.Shader
	{
		name := format("svo.points (src: %s, start: %s)",
			src, powerStart);
		if (s := name in mShaderStore) {
			return *s;
		}

		vert := cast(string)import("voxel/points.vert.glsl");
		vert = replaceCommon(vert);
		vert = replace(vert, "%VOXEL_SRC%", format("%s", src));
		vert = replace(vert, "%POWER_START%", format("%s", powerStart));
		frag := cast(string)import("voxel/points.frag.glsl");
		frag = replaceCommon(frag);
		frag = replace(frag, "%VOXEL_SRC%", format("%s", src));
		frag = replace(frag, "%POWER_START%", format("%s", powerStart));

		s := new gfx.Shader(name, vert, null, frag);
		mShaderStore[name] = s;
		return s;
	}

	fn makeQuadsShader(src: u32, powerStart: u32) gfx.Shader
	{
		name := format("svo.quads (src: %s, start: %s)",
			src, powerStart);
		if (s := name in mShaderStore) {
			return *s;
		}

		vert := cast(string)import("voxel/cube.vert.glsl");
		vert = replaceCommon(vert);
		vert = replace(vert, "%VOXEL_SRC%", format("%s", src));
		vert = replace(vert, "%POWER_START%", format("%s", powerStart));
		frag := cast(string)import("voxel/cube-normal.frag.glsl");
		frag = replaceCommon(frag);
		frag = replace(frag, "%VOXEL_SRC%", format("%s", src));
		frag = replace(frag, "%POWER_START%", format("%s", powerStart));

		s := new gfx.Shader(name, vert, null, frag);
		mShaderStore[name] = s;
		return s;
	}

private:
	fn replaceCommon(str: string) string
	{
		str = replace(str, "%RENDERER_AMD%", mIsAMD ? "1" : "0");
		str = replace(str, "%X_SHIFT%", format("%s", XShift));
		str = replace(str, "%Y_SHIFT%", format("%s", YShift));
		str = replace(str, "%Z_SHIFT%", format("%s", ZShift));
		return str;
	}
}
