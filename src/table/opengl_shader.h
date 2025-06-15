/*
 * This file is part of OpenTTD.
 * OpenTTD is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 2.
 * OpenTTD is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with OpenTTD. If not, see <http://www.gnu.org/licenses/>.
 */

/** @file opengl_shader.h OpenGL shader programs. */

/** Vertex shader that positions a sprite on screen. */
static const char *_vertex_shader_sprite_template[] = {
	"VERSION_DIRECTIVE",
	"PRECISION_DIRECTIVE",
	"uniform vec4 sprite;",
	"uniform vec2 screen;",
	"ATTRIBUTE vec2 position, colour_uv;",
	"VARYING vec2 colour_tex_uv;",
	"void main() {",
	"  vec2 size = sprite.zw / screen.xy;",
	"  vec2 offset = ((2.0 * sprite.xy + sprite.zw) / screen.xy - 1.0) * vec2(1.0, -1.0);",
	"  colour_tex_uv = colour_uv;",
	"  gl_Position = vec4(position * size + offset, 0.0, 1.0);",
	"}",
};

/** Fragment shader that reads the fragment colour from a 32bpp texture. */
static const char *_frag_shader_direct_template[] = {
	"VERSION_DIRECTIVE",
	"PRECISION_DIRECTIVE",
	"uniform sampler2D colour_tex;",
	"VARYING vec2 colour_tex_uv;",
	"void main() {",
	"  FRAGCOLOR = TEXTURE_2D(colour_tex, colour_tex_uv);",
	"}",
};

/** Fragment shader that performs a palette lookup to read the colour from an 8bpp texture. */
static const char *_frag_shader_palette_template[] = {
	"VERSION_DIRECTIVE",
	"PRECISION_DIRECTIVE",
	"uniform sampler2D colour_tex;",
	"uniform SAMPLER_PALETTE palette;",
	"VARYING vec2 colour_tex_uv;",
	"void main() {",
	"  float idx = TEXTURE_2D(colour_tex, colour_tex_uv).r;",
	"  FRAGCOLOR = TEXTURE_PALETTE(palette, idx);",
	"}",
};


/** Fragment shader function for remap brightness modulation. */
static const char *_frag_shader_remap_func = \
	"float max3(vec3 v) {"
	"  return max(max(v.x, v.y), v.z);"
	"}"
	""
	"vec3 adj_brightness(vec3 colour, float brightness) {"
	"  vec3 adj = colour * (brightness > 0.0 ? brightness / 0.5 : 1.0);"
	"  vec3 ob_vec = clamp(adj - 1.0, 0.0, 1.0);"
	"  float ob = (ob_vec.r + ob_vec.g + ob_vec.b) / 2.0;"
	""
	"  return clamp(adj + ob * (1.0 - adj), 0.0, 1.0);"
	"}";

/** Fragment shader that performs a palette lookup to read the colour from an 8bpp texture. */
static const char *_frag_shader_rgb_mask_blend_template[] = {
	"VERSION_DIRECTIVE",
	"EXTENSION_DIRECTIVE",
	"PRECISION_DIRECTIVE",
	"uniform sampler2D colour_tex;",
	"uniform SAMPLER_PALETTE palette;",
	"uniform sampler2D remap_tex;",
	"uniform bool rgb;",
	"uniform float zoom;",
	"VARYING vec2 colour_tex_uv;",
	"",
	_frag_shader_remap_func,
	"",
	"void main() {",
	"  float idx = TEXTURE_2D_LOD(remap_tex, colour_tex_uv, zoom).r;",
	"  vec4 remap_col = TEXTURE_PALETTE(palette, idx);",
	"  vec4 rgb_col = TEXTURE_2D_LOD(colour_tex, colour_tex_uv, zoom);",
	"",
	"  FRAGCOLOR_ALPHA = rgb ? rgb_col.a : remap_col.a;",
	"  FRAGCOLOR_RGB = idx > 0.0 ? adj_brightness(remap_col.rgb, max3(rgb_col.rgb)) : rgb_col.rgb;",
	"}",
};

/** Fragment shader that performs a palette lookup to read the colour from a sprite texture. */
static const char *_frag_shader_sprite_blend_template[] = {
	"VERSION_DIRECTIVE",
	"EXTENSION_DIRECTIVE",
	"PRECISION_DIRECTIVE",
	"uniform sampler2D colour_tex;",
	"uniform SAMPLER_PALETTE palette;",
	"uniform sampler2D remap_tex;",
	"uniform SAMPLER_PALETTE pal;",
	"uniform float zoom;",
	"uniform bool rgb;",
	"uniform bool crash;",
	"VARYING vec2 colour_tex_uv;",
	"",
	_frag_shader_remap_func,
	"",
	"void main() {",
	"  float idx = TEXTURE_2D_LOD(remap_tex, colour_tex_uv, zoom).r;",
	"  float r = TEXTURE_PALETTE(pal, idx).r;",
	"  vec4 remap_col = TEXTURE_PALETTE(palette, PALETTE_LOOKUP_VALUE);",
	"  vec4 rgb_col = TEXTURE_2D_LOD(colour_tex, colour_tex_uv, zoom);",
	"",
	"  CRASH_EFFECT",
	"  FRAGCOLOR_ALPHA = rgb && (r > 0.0 || idx == 0.0) ? rgb_col.a : remap_col.a;",
	"  FRAGCOLOR_RGB = idx > 0.0 ? adj_brightness(remap_col.rgb, max3(rgb_col.rgb)) : rgb_col.rgb;",
	"}",
};
