module lib.gl.gles2;


public import lib.gl.types;
public import lib.gl.funcs :
glFlush, glGetRenderbufferParameteriv, glClearColor, glStencilMaskSeparate, glGetVertexAttribPointerv, 
glLinkProgram, glBindTexture, glGetUniformiv, glFramebufferRenderbuffer, glGetString, 
glDetachShader, glLineWidth, glUniform2fv, glCompileShader, glDeleteTextures, 
glStencilOpSeparate, glStencilFuncSeparate, glVertexAttrib4f, glUniform2f, glDepthRangef, 
glUniform4iv, glGetTexParameteriv, glClearStencil, glSampleCoverage, glGenTextures, 
glDepthFunc, glCompressedTexSubImage2D, glUniform1f, glGetVertexAttribfv, glGetTexParameterfv, 
glCreateShader, glIsBuffer, glUniform1i, glGenRenderbuffers, glCopyTexSubImage2D, 
glCompressedTexImage2D, glDisable, glUniform2i, glBlendFuncSeparate, glGetProgramiv, 
glColorMask, glHint, glBlendEquation, glGetUniformLocation, glBindFramebuffer, 
glCullFace, glUniform4fv, glDeleteProgram, glRenderbufferStorage, glAttachShader, 
glUniform3i, glCheckFramebufferStatus, glShaderBinary, glCopyTexImage2D, glUniform3f, 
glBindAttribLocation, glDrawElements, glUniform2iv, glBufferSubData, glUniform1iv, 
glGetBufferParameteriv, glGenerateMipmap, glGetShaderiv, glVertexAttrib3f, glGetActiveAttrib, 
glBlendColor, glGetShaderPrecisionFormat, glGetUniformfv, glDisableVertexAttribArray, glShaderSource, 
glBindRenderbuffer, glDeleteRenderbuffers, glDeleteFramebuffers, glDrawArrays, glIsProgram, 
glTexSubImage2D, glVertexAttrib1fv, glClear, glVertexAttrib4fv, glReleaseShaderCompiler, 
glUniform4i, glActiveTexture, glEnableVertexAttribArray, glBindBuffer, glIsEnabled, 
glStencilOp, glReadPixels, glUniform4f, glFramebufferTexture2D, glGetFramebufferAttachmentParameteriv, 
glUniform3fv, glBufferData, glGetError, glGetVertexAttribiv, glTexParameteriv, 
glVertexAttrib3fv, glGetFloatv, glUniform3iv, glVertexAttrib2fv, glGenFramebuffers, 
glStencilFunc, glGetIntegerv, glGetAttachedShaders, glIsRenderbuffer, glIsShader, 
glUniformMatrix2fv, glUseProgram, glTexImage2D, glGetProgramInfoLog, glStencilMask, 
glGetShaderInfoLog, glIsTexture, glUniform1fv, glGetShaderSource, glVertexAttribPointer, 
glTexParameterfv, glUniformMatrix3fv, glEnable, glBlendEquationSeparate, glGenBuffers, 
glFinish, glGetAttribLocation, glDeleteShader, glBlendFunc, glCreateProgram, 
glIsFramebuffer, glViewport, glVertexAttrib2f, glVertexAttrib1f, glDepthMask, 
glUniformMatrix4fv, glGetActiveUniform, glTexParameterf, glTexParameteri, glFrontFace, 
glClearDepthf, glDeleteBuffers, glScissor, glGetBooleanv, glPixelStorei, 
glValidateProgram, glPolygonOffset;

public import lib.gl.enums :
GL_INFO_LOG_LENGTH, GL_LINE_STRIP, GL_UNSIGNED_SHORT_5_6_5, GL_VERTEX_ATTRIB_ARRAY_SIZE, GL_TEXTURE_CUBE_MAP, 
GL_VERTEX_SHADER, GL_DITHER, GL_FLOAT_VEC2, GL_FLOAT_VEC3, GL_FLOAT_VEC4, 
GL_FLOAT, GL_POINTS, GL_BUFFER_SIZE, GL_RENDERBUFFER_BLUE_SIZE, GL_FASTEST, 
GL_DEPTH_COMPONENT16, GL_POLYGON_OFFSET_UNITS, GL_TEXTURE23, GL_TEXTURE22, GL_TEXTURE21, 
GL_TEXTURE20, GL_TEXTURE27, GL_TEXTURE26, GL_TEXTURE25, GL_TEXTURE24, 
GL_TEXTURE29, GL_TEXTURE28, GL_ELEMENT_ARRAY_BUFFER_BINDING, GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 
GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, GL_TEXTURE8, GL_TEXTURE9, GL_LINE_LOOP, GL_TEXTURE4, 
GL_TEXTURE5, GL_TEXTURE6, GL_TEXTURE7, GL_TEXTURE0, GL_LINEAR_MIPMAP_LINEAR, 
GL_TEXTURE2, GL_TEXTURE3, GL_TEXTURE_CUBE_MAP_POSITIVE_Y, GL_TEXTURE_CUBE_MAP_POSITIVE_X, GL_BLEND_EQUATION, 
GL_BYTE, GL_BOOL_VEC3, GL_BOOL_VEC2, GL_DYNAMIC_DRAW, GL_GEQUAL, 
GL_MAX_VARYING_VECTORS, GL_ONE, GL_LINE_WIDTH, GL_COLOR_CLEAR_VALUE, GL_LEQUAL, 
GL_TRIANGLE_STRIP, GL_FUNC_ADD, GL_SHADER_SOURCE_LENGTH, GL_DEPTH_ATTACHMENT, GL_CURRENT_VERTEX_ATTRIB, 
GL_ARRAY_BUFFER_BINDING, GL_TEXTURE_2D, GL_UNSIGNED_SHORT_5_5_5_1, GL_OUT_OF_MEMORY, GL_STENCIL_FUNC, 
GL_VENDOR, GL_IMPLEMENTATION_COLOR_READ_TYPE, GL_ALIASED_LINE_WIDTH_RANGE, GL_DECR, GL_BACK, 
GL_INT, GL_POLYGON_OFFSET_FILL, GL_STREAM_DRAW, GL_FRONT_AND_BACK, GL_CURRENT_PROGRAM, 
GL_FRAMEBUFFER, GL_MEDIUM_FLOAT, GL_MAX_TEXTURE_SIZE, GL_STENCIL_TEST, GL_BUFFER_USAGE, 
GL_STENCIL_CLEAR_VALUE, GL_GREEN_BITS, GL_ONE_MINUS_CONSTANT_COLOR, GL_LUMINANCE_ALPHA, GL_SHADING_LANGUAGE_VERSION, 
GL_COLOR_ATTACHMENT0, GL_INVERT, GL_STENCIL_BACK_FAIL, GL_POLYGON_OFFSET_FACTOR, GL_FRAGMENT_SHADER, 
GL_TRIANGLE_FAN, GL_UNSIGNED_SHORT_4_4_4_4, GL_NO_ERROR, GL_STENCIL_BACK_WRITEMASK, GL_VIEWPORT, 
GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME, GL_BLEND_SRC_ALPHA, GL_INVALID_FRAMEBUFFER_OPERATION, GL_TRIANGLES, GL_RENDERBUFFER, 
GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT, GL_KEEP, GL_DELETE_STATUS, GL_SRC_COLOR, GL_PACK_ALIGNMENT, 
GL_RENDERER, GL_SAMPLE_BUFFERS, GL_SAMPLER_CUBE, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, GL_EXTENSIONS, 
GL_STENCIL_BACK_FUNC, GL_ACTIVE_TEXTURE, GL_RGBA4, GL_ONE_MINUS_DST_ALPHA, GL_DEPTH_BUFFER_BIT, 
GL_STENCIL_BACK_PASS_DEPTH_FAIL, GL_VERTEX_ATTRIB_ARRAY_POINTER, GL_INT_VEC4, GL_INT_VEC3, GL_ALIASED_POINT_SIZE_RANGE, 
GL_STENCIL_FAIL, GL_CCW, GL_MAX_VERTEX_ATTRIBS, GL_DEPTH_TEST, GL_FRAMEBUFFER_UNSUPPORTED, 
GL_INVALID_ENUM, GL_ACTIVE_UNIFORM_MAX_LENGTH, GL_LINEAR, GL_FUNC_SUBTRACT, GL_LESS, 
GL_MAX_CUBE_MAP_TEXTURE_SIZE, GL_RGB565, GL_IMPLEMENTATION_COLOR_READ_FORMAT, GL_RENDERBUFFER_WIDTH, GL_INT_VEC2, 
GL_HIGH_FLOAT, GL_DEPTH_RANGE, GL_GREATER, GL_CLAMP_TO_EDGE, GL_NEAREST, 
GL_VERTEX_ATTRIB_ARRAY_ENABLED, GL_MAX_TEXTURE_IMAGE_UNITS, GL_FLOAT_MAT2, GL_FLOAT_MAT3, GL_FRONT_FACE, 
GL_REPLACE, GL_RENDERBUFFER_GREEN_SIZE, GL_STENCIL_INDEX8, GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT, GL_FRAMEBUFFER_COMPLETE, 
GL_TEXTURE30, GL_TEXTURE31, GL_SRC_ALPHA_SATURATE, GL_RENDERBUFFER_STENCIL_SIZE, GL_REPEAT, 
GL_DEPTH_CLEAR_VALUE, GL_RENDERBUFFER_BINDING, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE, GL_STENCIL_REF, GL_VALIDATE_STATUS, 
GL_BLEND, GL_MIRRORED_REPEAT, GL_STENCIL_BUFFER_BIT, GL_UNSIGNED_SHORT, GL_ONE_MINUS_DST_COLOR, 
GL_ONE_MINUS_SRC_COLOR, GL_TEXTURE, GL_BLEND_EQUATION_ALPHA, GL_ACTIVE_ATTRIBUTES, GL_MAX_RENDERBUFFER_SIZE, 
GL_STENCIL_PASS_DEPTH_PASS, GL_INCR_WRAP, GL_RENDERBUFFER_ALPHA_SIZE, GL_COLOR_BUFFER_BIT, GL_DONT_CARE, 
GL_ACTIVE_UNIFORMS, GL_DECR_WRAP, GL_MAX_VERTEX_UNIFORM_VECTORS, GL_TEXTURE_BINDING_CUBE_MAP, GL_ATTACHED_SHADERS, 
GL_INVALID_VALUE, GL_SAMPLE_COVERAGE_INVERT, GL_NUM_COMPRESSED_TEXTURE_FORMATS, GL_LINES, GL_TEXTURE18, 
GL_TEXTURE19, GL_TEXTURE16, GL_TEXTURE17, GL_TEXTURE14, GL_TEXTURE_MAG_FILTER, 
GL_TEXTURE12, GL_TEXTURE13, GL_TEXTURE10, GL_TEXTURE1, GL_BLEND_EQUATION_RGB, 
GL_LINK_STATUS, GL_BLEND_DST_RGB, GL_BLEND_DST_ALPHA, GL_BLEND_COLOR, GL_ALPHA_BITS, 
GL_BOOL_VEC4, GL_VERTEX_ATTRIB_ARRAY_NORMALIZED, GL_RGB5_A1, GL_ONE_MINUS_CONSTANT_ALPHA, GL_NEAREST_MIPMAP_LINEAR, 
GL_TEXTURE_CUBE_MAP_POSITIVE_Z, GL_SHADER_BINARY_FORMATS, GL_CONSTANT_COLOR, GL_TEXTURE15, GL_VERTEX_ATTRIB_ARRAY_TYPE, 
GL_SAMPLER_2D, GL_LINEAR_MIPMAP_NEAREST, GL_STENCIL_WRITEMASK, GL_ARRAY_BUFFER, GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE, 
GL_VERSION, GL_ZERO, GL_ELEMENT_ARRAY_BUFFER, GL_BLEND_SRC_RGB, GL_FALSE, 
GL_ONE_MINUS_SRC_ALPHA, GL_CONSTANT_ALPHA, GL_SRC_ALPHA, GL_FIXED, GL_NUM_SHADER_BINARY_FORMATS, 
GL_NEAREST_MIPMAP_NEAREST, GL_NOTEQUAL, GL_INCR, GL_CULL_FACE, GL_SAMPLE_ALPHA_TO_COVERAGE, 
GL_STENCIL_BITS, GL_SAMPLE_COVERAGE_VALUE, GL_RENDERBUFFER_RED_SIZE, GL_STENCIL_PASS_DEPTH_FAIL, GL_MAX_VIEWPORT_DIMS, 
GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS, GL_MEDIUM_INT, GL_GENERATE_MIPMAP_HINT, GL_STENCIL_VALUE_MASK, GL_INVALID_OPERATION, 
GL_LOW_INT, GL_NONE, GL_STENCIL_BACK_PASS_DEPTH_PASS, GL_FUNC_REVERSE_SUBTRACT, GL_COMPILE_STATUS, 
GL_RENDERBUFFER_DEPTH_SIZE, GL_TEXTURE11, GL_SHADER_COMPILER, GL_STENCIL_ATTACHMENT, GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS, 
GL_FRONT, GL_SCISSOR_BOX, GL_DEPTH_WRITEMASK, GL_SUBPIXEL_BITS, GL_SHORT, 
GL_CULL_FACE_MODE, GL_MAX_FRAGMENT_UNIFORM_VECTORS, GL_CW, GL_UNSIGNED_BYTE, GL_NICEST, 
GL_BOOL, GL_FRAMEBUFFER_BINDING, GL_TEXTURE_BINDING_2D, GL_COMPRESSED_TEXTURE_FORMATS, GL_HIGH_INT, 
GL_ALPHA, GL_STATIC_DRAW, GL_NEVER, GL_COLOR_WRITEMASK, GL_DST_COLOR, 
GL_UNSIGNED_INT, GL_DEPTH_FUNC, GL_ALWAYS, GL_TEXTURE_WRAP_S, GL_TEXTURE_WRAP_T, 
GL_DST_ALPHA, GL_STENCIL_BACK_VALUE_MASK, GL_LUMINANCE, GL_DEPTH_BITS, GL_DEPTH_COMPONENT, 
GL_SCISSOR_TEST, GL_SHADER_TYPE, GL_TRUE, GL_TEXTURE_MIN_FILTER, GL_FLOAT_MAT4, 
GL_BLUE_BITS, GL_RGBA, GL_VERTEX_ATTRIB_ARRAY_STRIDE, GL_RGB, GL_EQUAL, 
GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL, GL_RENDERBUFFER_HEIGHT, GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, GL_LOW_FLOAT, GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, 
GL_SAMPLE_COVERAGE, GL_RENDERBUFFER_INTERNAL_FORMAT, GL_RED_BITS, GL_STENCIL_BACK_REF, GL_UNPACK_ALIGNMENT, 
GL_SAMPLES;

