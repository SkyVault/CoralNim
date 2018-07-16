
# Partial port of stb truetype. Based on revision c9ead07188b342350530e92e14542222c3ad9abe (14/05/16)

import math
import algorithm

proc STBTT_malloc(size: int, userdata: pointer): pointer {.exportc.} = alloc(size)
proc STBTT_free(data: pointer, userdata: pointer) {.exportc.} =
    if not data.isNil: dealloc(data)

{.emit: """

#define STB_TRUETYPE_IMPLEMENTATION

// stb_truetype.h - v1.08 - public domain
// authored from 2009-2015 by Sean Barrett / RAD Game Tools
//
//   This library processes TrueType files:
//        parse files
//        extract glyph metrics
//        extract glyph shapes
//        render glyphs to one-channel bitmaps with antialiasing (box filter)
//
//   Todo:
//        non-MS cmaps
//        crashproof on bad data
//        hinting? (no longer patented)
//        cleartype-style AA?
//        optimize: use simple memory allocator for intermediates
//        optimize: build edge-list directly from curves
//        optimize: rasterize directly from curves?
//
// ADDITIONAL CONTRIBUTORS
//
//   Mikko Mononen: compound shape support, more cmap formats
//   Tor Andersson: kerning, subpixel rendering
//
//   Misc other:
//       Ryan Gordon
//       Simon Glass
//
//   Bug/warning reports/fixes:
//       "Zer" on mollyrocket (with fix)
//       Cass Everitt
//       stoiko (Haemimont Games)
//       Brian Hook
//       Walter van Niftrik
//       David Gow
//       David Given
//       Ivan-Assen Ivanov
//       Anthony Pesch
//       Johan Duparc
//       Hou Qiming
//       Fabian "ryg" Giesen
//       Martins Mozeiko
//       Cap Petschulat
//       Omar Cornut
//       github:aloucks
//       Peter LaValle
//       Sergey Popov
//       Giumo X. Clanjor
//       Higor Euripedes
//       Thomas Fields
//       Derek Vinyard
//
//   Misc other:
//       Ryan Gordon
//
// VERSION HISTORY
//
//   1.11 (2016-04-02) fix unused-variable warning
//   1.10 (2016-04-02) user-defined fabs(); rare memory leak; remove duplicate typedef
//   1.09 (2016-01-16) warning fix; avoid crash on outofmem; use allocation userdata properly
//   1.08 (2015-09-13) document stbtt_Rasterize(); fixes for vertical & horizontal edges
//   1.07 (2015-08-01) allow PackFontRanges to accept arrays of sparse codepoints;
//                     variant PackFontRanges to pack and render in separate phases;
//                     fix stbtt_GetFontOFfsetForIndex (never worked for non-0 input?);
//                     fixed an assert() bug in the new rasterizer
//                     replace assert() with STBTT_assert() in new rasterizer
//   1.06 (2015-07-14) performance improvements (~35% faster on x86 and x64 on test machine)
//                     also more precise AA rasterizer, except if shapes overlap
//                     remove need for STBTT_sort
//   1.05 (2015-04-15) fix misplaced definitions for STBTT_STATIC
//   1.04 (2015-04-15) typo in example
//   1.03 (2015-04-12) STBTT_STATIC, fix memory leak in new packing, various fixes
//
//   Full history can be found at the end of this file.
//
// LICENSE
//
//   This software is dual-licensed to the public domain and under the following
//   license: you are granted a perpetual, irrevocable license to copy, modify,
//   publish, and distribute this file as you see fit.
//
// USAGE
//
//   Include this file in whatever places neeed to refer to it. In ONE C/C++
//   file, write:
//      #define STB_TRUETYPE_IMPLEMENTATION
//   before the #include of this file. This expands out the actual
//   implementation into that C/C++ file.
//
//   To make the implementation private to the file that generates the implementation,
//      #define STBTT_STATIC
//
//   Simple 3D API (don't ship this, but it's fine for tools and quick start)
//           stbtt_BakeFontBitmap()               -- bake a font to a bitmap for use as texture
//           stbtt_GetBakedQuad()                 -- compute quad to draw for a given char
//
//   Improved 3D API (more shippable):
//           #include "stb_rect_pack.h"           -- optional, but you really want it
//           stbtt_PackBegin()
//           stbtt_PackSetOversample()            -- for improved quality on small fonts
//           stbtt_PackFontRanges()               -- pack and renders
//           stbtt_PackEnd()
//           stbtt_GetPackedQuad()
//
//   "Load" a font file from a memory buffer (you have to keep the buffer loaded)
//           stbtt_InitFont()
//           stbtt_GetFontOffsetForIndex()        -- use for TTC font collections
//
//   Render a unicode codepoint to a bitmap
//           stbtt_GetCodepointBitmap()           -- allocates and returns a bitmap
//           stbtt_MakeCodepointBitmap()          -- renders into bitmap you provide
//           stbtt_GetCodepointBitmapBox()        -- how big the bitmap must be
//
//   Character advance/positioning
//           stbtt_GetCodepointHMetrics()
//           stbtt_GetFontVMetrics()
//           stbtt_GetCodepointKernAdvance()
//
//   Starting with version 1.06, the rasterizer was replaced with a new,
//   faster and generally-more-precise rasterizer. The new rasterizer more
//   accurately measures pixel coverage for anti-aliasing, except in the case
//   where multiple shapes overlap, in which case it overestimates the AA pixel
//   coverage. Thus, anti-aliasing of intersecting shapes may look wrong. If
//   this turns out to be a problem, you can re-enable the old rasterizer with
//        #define STBTT_RASTERIZER_VERSION 1
//   which will incur about a 15% speed hit.
//
// ADDITIONAL DOCUMENTATION
//
//   Immediately after this block comment are a series of sample programs.
//
//   After the sample programs is the "header file" section. This section
//   includes documentation for each API function.
//
//   Some important concepts to understand to use this library:
//
//      Codepoint
//         Characters are defined by unicode codepoints, e.g. 65 is
//         uppercase A, 231 is lowercase c with a cedilla, 0x7e30 is
//         the hiragana for "ma".
//
//      Glyph
//         A visual character shape (every codepoint is rendered as
//         some glyph)
//
//      Glyph index
//         A font-specific integer ID representing a glyph
//
//      Baseline
//         Glyph shapes are defined relative to a baseline, which is the
//         bottom of uppercase characters. Characters extend both above
//         and below the baseline.
//
//      Current Point
//         As you draw text to the screen, you keep track of a "current point"
//         which is the origin of each character. The current point's vertical
//         position is the baseline. Even "baked fonts" use this model.
//
//      Vertical Font Metrics
//         The vertical qualities of the font, used to vertically position
//         and space the characters. See docs for stbtt_GetFontVMetrics.
//
//      Font Size in Pixels or Points
//         The preferred interface for specifying font sizes in stb_truetype
//         is to specify how tall the font's vertical extent should be in pixels.
//         If that sounds good enough, skip the next paragraph.
//
//         Most font APIs instead use "points", which are a common typographic
//         measurement for describing font size, defined as 72 points per inch.
//         stb_truetype provides a point API for compatibility. However, true
//         "per inch" conventions don't make much sense on computer displays
//         since they different monitors have different number of pixels per
//         inch. For example, Windows traditionally uses a convention that
//         there are 96 pixels per inch, thus making 'inch' measurements have
//         nothing to do with inches, and thus effectively defining a point to
//         be 1.333 pixels. Additionally, the TrueType font data provides
//         an explicit scale factor to scale a given font's glyphs to points,
//         but the author has observed that this scale factor is often wrong
//         for non-commercial fonts, thus making fonts scaled in points
//         according to the TrueType spec incoherently sized in practice.
//
// ADVANCED USAGE
//
//   Quality:
//
//    - Use the functions with Subpixel at the end to allow your characters
//      to have subpixel positioning. Since the font is anti-aliased, not
//      hinted, this is very import for quality. (This is not possible with
//      baked fonts.)
//
//    - Kerning is now supported, and if you're supporting subpixel rendering
//      then kerning is worth using to give your text a polished look.
//
//   Performance:
//
//    - Convert Unicode codepoints to glyph indexes and operate on the glyphs;
//      if you don't do this, stb_truetype is forced to do the conversion on
//      every call.
//
//    - There are a lot of memory allocations. We should modify it to take
//      a temp buffer and allocate from the temp buffer (without freeing),
//      should help performance a lot.
//
// NOTES
//
//   The system uses the raw data found in the .ttf file without changing it
//   and without building auxiliary data structures. This is a bit inefficient
//   on little-endian systems (the data is big-endian), but assuming you're
//   caching the bitmaps or glyph shapes this shouldn't be a big deal.
//
//   It appears to be very hard to programmatically determine what font a
//   given file is in a general way. I provide an API for this, but I don't
//   recommend it.
//
//
// SOURCE STATISTICS (based on v0.6c, 2050 LOC)
//
//   Documentation & header file        520 LOC  \___ 660 LOC documentation
//   Sample code                        140 LOC  /
//   Truetype parsing                   620 LOC  ---- 620 LOC TrueType
//   Software rasterization             240 LOC  \                           .
//   Curve tesselation                  120 LOC   \__ 550 LOC Bitmap creation
//   Bitmap management                  100 LOC   /
//   Baked bitmap interface              70 LOC  /
//   Font name matching & access        150 LOC  ---- 150
//   C runtime library abstraction       60 LOC  ----  60
//
//
// PERFORMANCE MEASUREMENTS FOR 1.06:
//
//                      32-bit     64-bit
//   Previous release:  8.83 s     7.68 s
//   Pool allocations:  7.72 s     6.34 s
//   Inline sort     :  6.54 s     5.65 s
//   New rasterizer  :  5.63 s     5.00 s

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
////
////  SAMPLE PROGRAMS
////
//
//  Incomplete text-in-3d-api example, which draws quads properly aligned to be lossless
//
#if 0
#define STB_TRUETYPE_IMPLEMENTATION  // force following include to generate implementation
#include "stb_truetype.h"
unsigned char ttf_buffer[1<<20];
unsigned char temp_bitmap[512*512];
stbtt_bakedchar cdata[96]; // ASCII 32..126 is 95 glyphs
GLuint ftex;
void my_stbtt_initfont(void)
{
   fread(ttf_buffer, 1, 1<<20, fopen("c:/windows/fonts/times.ttf", "rb"));
   stbtt_BakeFontBitmap(ttf_buffer,0, 32.0, temp_bitmap,512,512, 32,96, cdata); // no guarantee this fits!
   // can free ttf_buffer at this point
   glGenTextures(1, &ftex);
   glBindTexture(GL_TEXTURE_2D, ftex);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, 512,512, 0, GL_ALPHA, GL_UNSIGNED_BYTE, temp_bitmap);
   // can free temp_bitmap at this point
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
}
void my_stbtt_print(float x, float y, char *text)
{
   // assume orthographic projection with units = screen pixels, origin at top left
   glEnable(GL_TEXTURE_2D);
   glBindTexture(GL_TEXTURE_2D, ftex);
   glBegin(GL_QUADS);
   while (*text) {
      if (*text >= 32 && *text < 128) {
         stbtt_aligned_quad q;
         stbtt_GetBakedQuad(cdata, 512,512, *text-32, &x,&y,&q,1);//1=opengl & d3d10+,0=d3d9
         glTexCoord2f(q.s0,q.t1); glVertex2f(q.x0,q.y0);
         glTexCoord2f(q.s1,q.t1); glVertex2f(q.x1,q.y0);
         glTexCoord2f(q.s1,q.t0); glVertex2f(q.x1,q.y1);
         glTexCoord2f(q.s0,q.t0); glVertex2f(q.x0,q.y1);
      }
      ++text;
   }
   glEnd();
}
#endif
//
//
//////////////////////////////////////////////////////////////////////////////
//
// Complete program (this compiles): get a single bitmap, print as ASCII art
//
#if 0
#include <stdio.h>
#define STB_TRUETYPE_IMPLEMENTATION  // force following include to generate implementation
#include "stb_truetype.h"
char ttf_buffer[1<<25];
int main(int argc, char **argv)
{
   stbtt_fontinfo font;
   unsigned char *bitmap;
   int w,h,i,j,c = (argc > 1 ? atoi(argv[1]) : 'a'), s = (argc > 2 ? atoi(argv[2]) : 20);
   fread(ttf_buffer, 1, 1<<25, fopen(argc > 3 ? argv[3] : "c:/windows/fonts/arialbd.ttf", "rb"));
   stbtt_InitFont(&font, ttf_buffer, stbtt_GetFontOffsetForIndex(ttf_buffer,0));
   bitmap = stbtt_GetCodepointBitmap(&font, 0,stbtt_ScaleForPixelHeight(&font, s), c, &w, &h, 0,0);
   for (j=0; j < h; ++j) {
      for (i=0; i < w; ++i)
         putchar(" .:ioVM@"[bitmap[j*w+i]>>5]);
      putchar('\n');
   }
   return 0;
}
#endif
//
// Output:
//
//     .ii.
//    @@@@@@.
//   V@Mio@@o
//   :i.  V@V
//     :oM@@M
//   :@@@MM@M
//   @@o  o@M
//  :@@.  M@M
//   @@@o@@@@
//   :M@@V:@@.
//
//////////////////////////////////////////////////////////////////////////////
//
// Complete program: print "Hello World!" banner, with bugs
//
#if 0
char buffer[24<<20];
unsigned char screen[20][79];
int main(int arg, char **argv)
{
   stbtt_fontinfo font;
   int i,j,ascent,baseline,ch=0;
   float scale, xpos=2; // leave a little padding in case the character extends left
   char *text = "Heljo World!"; // intentionally misspelled to show 'lj' brokenness
   fread(buffer, 1, 1000000, fopen("c:/windows/fonts/arialbd.ttf", "rb"));
   stbtt_InitFont(&font, buffer, 0);
   scale = stbtt_ScaleForPixelHeight(&font, 15);
   stbtt_GetFontVMetrics(&font, &ascent,0,0);
   baseline = (int) (ascent*scale);
   while (text[ch]) {
      int advance,lsb,x0,y0,x1,y1;
      float x_shift = xpos - (float) floor(xpos);
      stbtt_GetCodepointHMetrics(&font, text[ch], &advance, &lsb);
      stbtt_GetCodepointBitmapBoxSubpixel(&font, text[ch], scale,scale,x_shift,0, &x0,&y0,&x1,&y1);
      stbtt_MakeCodepointBitmapSubpixel(&font, &screen[baseline + y0][(int) xpos + x0], x1-x0,y1-y0, 79, scale,scale,x_shift,0, text[ch]);
      // note that this stomps the old data, so where character boxes overlap (e.g. 'lj') it's wrong
      // because this API is really for baking character bitmaps into textures. if you want to render
      // a sequence of characters, you really need to render each bitmap to a temp buffer, then
      // "alpha blend" that into the working buffer
      xpos += (advance * scale);
      if (text[ch+1])
         xpos += scale*stbtt_GetCodepointKernAdvance(&font, text[ch],text[ch+1]);
      ++ch;
   }
   for (j=0; j < 20; ++j) {
      for (i=0; i < 78; ++i)
         putchar(" .:ioVM@"[screen[j][i]>>5]);
      putchar('\n');
   }
   return 0;
}
#endif

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
////
////   INTEGRATION WITH YOUR CODEBASE
////
////   The following sections allow you to supply alternate definitions
////   of C library functions used by stb_truetype.

#ifdef STB_TRUETYPE_IMPLEMENTATION
   // #define your own (u)stbtt_int8/16/32 before including to override this
   #ifndef stbtt_uint8
   typedef unsigned char   stbtt_uint8;
   typedef signed   char   stbtt_int8;
   typedef unsigned short  stbtt_uint16;
   typedef signed   short  stbtt_int16;
   typedef unsigned int    stbtt_uint32;
   typedef signed   int    stbtt_int32;
   #endif

   typedef char stbtt__check_size32[sizeof(stbtt_int32)==4 ? 1 : -1];
   typedef char stbtt__check_size16[sizeof(stbtt_int16)==2 ? 1 : -1];

   // #define your own STBTT_sort() to override this to avoid qsort
   #ifndef STBTT_sort
   #include <stdlib.h>
   #define STBTT_sort(data,num_items,item_size,compare_func)   qsort(data,num_items,item_size,compare_func)
   #endif

   // #define your own STBTT_ifloor/STBTT_iceil() to avoid math.h
   #ifndef STBTT_ifloor
   #include <math.h>
   #define STBTT_ifloor(x)   ((int) floor(x))
   #define STBTT_iceil(x)    ((int) ceil(x))
   #endif

   #ifndef STBTT_sqrt
   #include <math.h>
   #define STBTT_sqrt(x)      sqrt(x)
   #endif

   #ifndef STBTT_fabs
   #include <math.h>
   #define STBTT_fabs(x)      fabs(x)
   #endif

   #ifndef STBTT_assert
   #include <assert.h>
   #define STBTT_assert(x)    assert(x)
   #endif

   #ifndef STBTT_strlen
   #include <string.h>
   #define STBTT_strlen(x)    strlen(x)
   #endif

   #ifndef STBTT_memcpy
   #include <memory.h>
   #define STBTT_memcpy       memcpy
   #define STBTT_memset       memset
   #endif
#endif

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
////
////   INTERFACE
////
////

#ifndef __STB_INCLUDE_STB_TRUETYPE_H__
#define __STB_INCLUDE_STB_TRUETYPE_H__

#ifdef __cplusplus
extern "C" {
#endif

""".}

################################################################################
#
# TEXTURE BAKING API
#
# If you use this API, you only have to call two functions ever.
#

type stbtt_bakedchar* {.exportc.} = object
    x0*, y0*, x1*, y1*: uint16 # coordinates of bbox in bitmap
    xoff*, yoff*, xadvance*: cfloat


proc stbtt_BakeFontBitmap*(data: pointer, offset: cint,        # font location (use offset=0 for plain .ttf)
                                pixel_height: cfloat,          # height of font in pixels
                                pixels: pointer, pw, ph: cint, # bitmap to be filled in
                                first_char, num_chars:cint,    # characters to bake
                                chardata: pointer              # you allocate this, it's num_chars long
                                ): cint {.importc.}

# if return is positive, the first unused row of the bitmap
# if return is negative, returns the negative of the number of characters that fit
# if return is 0, no characters fit and no rows were used
# This uses a very crappy packing.

type stbtt_aligned_quad* {.exportc.} = object
    x0*, y0*, s0*, t0*: cfloat # top-left
    x1*, y1*, s1*, t1*: cfloat # bottom-right


{.emit: """

//////////////////////////////////////////////////////////////////////////////
//
// NEW TEXTURE BAKING API
//
// This provides options for packing multiple fonts into one atlas, not
// perfectly but better than nothing.

typedef struct
{
   unsigned short x0,y0,x1,y1; // coordinates of bbox in bitmap
   float xoff,yoff,xadvance;
   float xoff2,yoff2;
} stbtt_packedchar;

typedef struct stbtt_pack_context stbtt_pack_context;

extern int  stbtt_PackBegin(stbtt_pack_context *spc, unsigned char *pixels, int width, int height, int stride_in_bytes, int padding, void *alloc_context);
// Initializes a packing context stored in the passed-in stbtt_pack_context.
// Future calls using this context will pack characters into the bitmap passed
// in here: a 1-channel bitmap that is weight x height. stride_in_bytes is
// the distance from one row to the next (or 0 to mean they are packed tightly
// together). "padding" is // the amount of padding to leave between each
// character (normally you want '1' for bitmaps you'll use as textures with
// bilinear filtering).
//
// Returns 0 on failure, 1 on success.

extern void stbtt_PackEnd  (stbtt_pack_context *spc);
// Cleans up the packing context and frees all memory.

#define STBTT_POINT_SIZE(x)   (-(x))

extern int  stbtt_PackFontRange(stbtt_pack_context *spc, unsigned char *fontdata, int font_index, float font_size,
                                int first_unicode_char_in_range, int num_chars_in_range, stbtt_packedchar *chardata_for_range);
// Creates character bitmaps from the font_index'th font found in fontdata (use
// font_index=0 if you don't know what that is). It creates num_chars_in_range
// bitmaps for characters with unicode values starting at first_unicode_char_in_range
// and increasing. Data for how to render them is stored in chardata_for_range;
// pass these to stbtt_GetPackedQuad to get back renderable quads.
//
// font_size is the full height of the character from ascender to descender,
// as computed by stbtt_ScaleForPixelHeight. To use a point size as computed
// by stbtt_ScaleForMappingEmToPixels, wrap the point size in STBTT_POINT_SIZE()
// and pass that result as 'font_size':
//       ...,                  20 , ... // font max minus min y is 20 pixels tall
//       ..., STBTT_POINT_SIZE(20), ... // 'M' is 20 pixels tall

typedef struct
{
   float font_size;
   int first_unicode_char_in_range;
   int num_chars_in_range;
   stbtt_packedchar *chardata_for_range; // output
} stbtt_pack_range;

extern int  stbtt_PackFontRanges(stbtt_pack_context *spc, unsigned char *fontdata, int font_index, stbtt_pack_range *ranges, int num_ranges);
// Creates character bitmaps from multiple ranges of characters stored in
// ranges. This will usually create a better-packed bitmap than multiple
// calls to stbtt_PackFontRange.


extern void stbtt_PackSetOversampling(stbtt_pack_context *spc, unsigned int h_oversample, unsigned int v_oversample);
// Oversampling a font increases the quality by allowing higher-quality subpixel
// positioning, and is especially valuable at smaller text sizes.
//
// This function sets the amount of oversampling for all following calls to
// stbtt_PackFontRange(s). The default (no oversampling) is achieved by
// h_oversample=1, v_oversample=1. The total number of pixels required is
// h_oversample*v_oversample larger than the default; for example, 2x2
// oversampling requires 4x the storage of 1x1. For best results, render
// oversampled textures with bilinear filtering. Look at the readme in
// stb/tests/oversample for information about oversampled fonts

extern void stbtt_GetPackedQuad(stbtt_packedchar *chardata, int pw, int ph,  // same data as above
                               int char_index,             // character to display
                               float *xpos, float *ypos,   // pointers to current position in screen pixel space
                               stbtt_aligned_quad *q,      // output: quad to draw
                               int align_to_integer);

// this is an opaque structure that you shouldn't mess with which holds
// all the context needed from PackBegin to PackEnd.
struct stbtt_pack_context {
   void *user_allocator_context;
   void *pack_info;
   int   width;
   int   height;
   int   stride_in_bytes;
   int   padding;
   unsigned int   h_oversample, v_oversample;
   unsigned char *pixels;
   void  *nodes;
};

""".}

################################################################
#
# FONT LOADING
#
#
type font_type* {.unchecked.} = array[999999999, uint8]


# The following structure is defined publically so you can declare one on
# the stack or as a global or etc, but you should treat it as opaque.
type stbtt_fontinfo* {.exportc, byRef.} = object
    userdata: pointer
    data: ptr font_type     # pointer to .ttf file
    fontstart: cint    # offset of start of font

    numGlyphs: cint    # number of glyphs, needed for range checking

    loca,head,glyf,hhea,hmtx,kern: cint # table locations as offset from start of .ttf
    index_map: cint                     # a cmap mapping for our chosen character encoding
    indexToLocFormat: cint              # format needed to map from glyph index to glyph


proc stbtt_InitFont*(info: var stbtt_fontinfo, data: ptr font_type, fontstart: cint): cint {.exportc.}
# Given an offset into the file that defines a font, this function builds
# the necessary cached info for the rest of the system. You must allocate
# the stbtt_fontinfo yourself, and stbtt_InitFont will fill it out. You don't
# need to do anything special to free it, because the contents are pure
# value data with no additional data structures. Returns 0 on failure.


#/////////////////////////////////////////////////////////////////////////////
#
# CHARACTER TO GLYPH-INDEX CONVERSIOn

proc stbtt_FindGlyphIndex*(info: stbtt_fontinfo, unicode_codepoint: cint): cint {.importc.}
# If you're going to perform multiple operations on the same character
# and you want a speed-up, call this function with the character you're
# going to process, then use glyph-based functions instead of the
# codepoint-based functions.


##////////////////////////////////////////////////////////////////////////////
#
# CHARACTER PROPERTIES
#

################################################################################
#
# GLYPH SHAPES (you probably don't need these, but they have to go before
# the bitmaps for C declaration-order reasons)
#

type STBTT_type {.exportc.} = enum
    STBTT_vmove = 1
    STBTT_vline
    STBTT_vcurve

type stbtt_vertex_type = int16

type stbtt_vertex {.exportc.} = object
    x, y, cx, cy: stbtt_vertex_type
    `type`: STBTT_type
    padding: uint8


{.emit: """


extern void stbtt_FreeShape(const stbtt_fontinfo *info, stbtt_vertex *vertices);
// frees the data allocated above

//////////////////////////////////////////////////////////////////////////////
//
// BITMAP RENDERING
//


extern unsigned char *stbtt_GetCodepointBitmap(const stbtt_fontinfo *info, float scale_x, float scale_y, int codepoint, int *width, int *height, int *xoff, int *yoff);
// allocates a large-enough single-channel 8bpp bitmap and renders the
// specified character/glyph at the specified scale into it, with
// antialiasing. 0 is no coverage (transparent), 255 is fully covered (opaque).
// *width & *height are filled out with the width & height of the bitmap,
// which is stored left-to-right, top-to-bottom.
//
// xoff/yoff are the offset it pixel space from the glyph origin to the top-left of the bitmap

extern unsigned char *stbtt_GetCodepointBitmapSubpixel(const stbtt_fontinfo *info, float scale_x, float scale_y, float shift_x, float shift_y, int codepoint, int *width, int *height, int *xoff, int *yoff);
// the same as stbtt_GetCodepoitnBitmap, but you can specify a subpixel
// shift for the character

extern void stbtt_MakeCodepointBitmap(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, int codepoint);
// the same as stbtt_GetCodepointBitmap, but you pass in storage for the bitmap
// in the form of 'output', with row spacing of 'out_stride' bytes. the bitmap
// is clipped to out_w/out_h bytes. Call stbtt_GetCodepointBitmapBox to get the
// width and height and positioning info for it first.

extern void stbtt_MakeCodepointBitmapSubpixel(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, float shift_x, float shift_y, int codepoint);
// same as stbtt_MakeCodepointBitmap, but you can specify a subpixel
// shift for the character

// the following functions are equivalent to the above functions, but operate
// on glyph indices instead of Unicode codepoints (for efficiency)
//extern unsigned char *stbtt_


//Bitmap(const stbtt_fontinfo *info, float scale_x, float scale_y, int glyph, int *width, int *height, int *xoff, int *yoff);
//extern unsigned char *stbtt_GetGlyphBitmapSubpixel(const stbtt_fontinfo *info, float scale_x, float scale_y, float shift_x, float shift_y, int glyph, int *width, int *height, int *xoff, int *yoff);
""".}

proc stbtt_GetGlyphBitmapBox*(info: stbtt_fontinfo, glyph: cint, scale_x, scale_y: cfloat, ix0, iy0, ix1, iy1: var cint) {.importc.}

type stbtt_bitmap {.exportc.} = object
    w,h,stride: cint
    pixels: ptr uint8

{.emit: """
/*
// @TODO: don't expose this structure
typedef struct
{
   int w,h,stride;
   unsigned char *pixels;
} stbtt_bitmap;
*/

//////////////////////////////////////////////////////////////////////////////
//
// Finding the right font...
//
// You should really just solve this offline, keep your own tables
// of what font is what, and don't try to get it out of the .ttf file.
// That's because getting it out of the .ttf file is really hard, because
// the names in the file can appear in many possible encodings, in many
// possible languages, and e.g. if you need a case-insensitive comparison,
// the details of that depend on the encoding & language in a complex way
// (actually underspecified in truetype, but also gigantic).
//
// But you can use the provided functions in two possible ways:
//     stbtt_FindMatchingFont() will use *case-sensitive* comparisons on
//             unicode-encoded names to try to find the font you want;
//             you can run this before calling stbtt_InitFont()
//
//     stbtt_GetFontNameString() lets you get any of the various strings
//             from the file yourself and do your own comparisons on them.
//             You have to have called stbtt_InitFont() first.


extern int stbtt_FindMatchingFont(const unsigned char *fontdata, const char *name, int flags);
// returns the offset (not index) of the font that matches, or -1 if none
//   if you use STBTT_MACSTYLE_DONTCARE, use a font name like "Arial Bold".
//   if you use any other flag, use a font name like "Arial"; this checks
//     the 'macStyle' header field; i don't know if fonts set this consistently
#define STBTT_MACSTYLE_DONTCARE     0
#define STBTT_MACSTYLE_BOLD         1
#define STBTT_MACSTYLE_ITALIC       2
#define STBTT_MACSTYLE_UNDERSCORE   4
#define STBTT_MACSTYLE_NONE         8   // <= not same as 0, this makes us check the bitfield is 0

extern int stbtt_CompareUTF8toUTF16_bigendian(const char *s1, int len1, const char *s2, int len2);
// returns 1/0 whether the first string interpreted as utf8 is identical to
// the second string interpreted as big-endian utf16... useful for strings from next func

extern const char *stbtt_GetFontNameString(const stbtt_fontinfo *font, int *length, int platformID, int encodingID, int languageID, int nameID);
// returns the string (which may be big-endian double byte, e.g. for unicode)
// and puts the length in bytes in *length.
//
// some of the values for the IDs are below; for more see the truetype spec:
//     http://developer.apple.com/textfonts/TTRefMan/RM06/Chap6name.html
//     http://www.microsoft.com/typography/otspec/name.htm

""".}

{.push hints: off.} # Suppress declared but not used warning [XDeclaredButNotUsed]

type PlatformId = enum
    STBTT_PLATFORM_ID_UNICODE   = 0
    STBTT_PLATFORM_ID_MAC       = 1
    STBTT_PLATFORM_ID_ISO       = 2
    STBTT_PLATFORM_ID_MICROSOFT = 3

const # Encoding ID
    # for STBTT_PLATFORM_ID_UNICODE
    STBTT_UNICODE_EID_UNICODE_1_0    = 0
    STBTT_UNICODE_EID_UNICODE_1_1    = 1
    STBTT_UNICODE_EID_ISO_10646      = 2
    STBTT_UNICODE_EID_UNICODE_2_0_BMP= 3
    STBTT_UNICODE_EID_UNICODE_2_0_FULL= 4

    # for STBTT_PLATFORM_ID_MICROSOFT
    STBTT_MS_EID_SYMBOL        = 0
    STBTT_MS_EID_UNICODE_BMP   = 1
    STBTT_MS_EID_SHIFTJIS      = 2
    STBTT_MS_EID_UNICODE_FULL  = 10

    # for STBTT_PLATFORM_ID_MAC; same as Script Manager codes
    STBTT_MAC_EID_ROMAN        = 0
    STBTT_MAC_EID_JAPANESE     = 1
    STBTT_MAC_EID_CHINESE_TRAD = 2
    STBTT_MAC_EID_KOREAN       = 3
    STBTT_MAC_EID_ARABIC       = 4
    STBTT_MAC_EID_HEBREW       = 5
    STBTT_MAC_EID_GREEK        = 6
    STBTT_MAC_EID_RUSSIAN      = 7

{.pop.}


{.emit: """
enum { // languageID for STBTT_PLATFORM_ID_MICROSOFT; same as LCID...
       // problematic because there are e.g. 16 english LCIDs and 16 arabic LCIDs
   STBTT_MS_LANG_ENGLISH     =0x0409,   STBTT_MS_LANG_ITALIAN     =0x0410,
   STBTT_MS_LANG_CHINESE     =0x0804,   STBTT_MS_LANG_JAPANESE    =0x0411,
   STBTT_MS_LANG_DUTCH       =0x0413,   STBTT_MS_LANG_KOREAN      =0x0412,
   STBTT_MS_LANG_FRENCH      =0x040c,   STBTT_MS_LANG_RUSSIAN     =0x0419,
   STBTT_MS_LANG_GERMAN      =0x0407,   STBTT_MS_LANG_SPANISH     =0x0409,
   STBTT_MS_LANG_HEBREW      =0x040d,   STBTT_MS_LANG_SWEDISH     =0x041D
};

enum { // languageID for STBTT_PLATFORM_ID_MAC
   STBTT_MAC_LANG_ENGLISH      =0 ,   STBTT_MAC_LANG_JAPANESE     =11,
   STBTT_MAC_LANG_ARABIC       =12,   STBTT_MAC_LANG_KOREAN       =23,
   STBTT_MAC_LANG_DUTCH        =4 ,   STBTT_MAC_LANG_RUSSIAN      =32,
   STBTT_MAC_LANG_FRENCH       =1 ,   STBTT_MAC_LANG_SPANISH      =6 ,
   STBTT_MAC_LANG_GERMAN       =2 ,   STBTT_MAC_LANG_SWEDISH      =5 ,
   STBTT_MAC_LANG_HEBREW       =10,   STBTT_MAC_LANG_CHINESE_SIMPLIFIED =33,
   STBTT_MAC_LANG_ITALIAN      =3 ,   STBTT_MAC_LANG_CHINESE_TRAD =19
};

#ifdef __cplusplus
}
#endif

#endif // __STB_INCLUDE_STB_TRUETYPE_H__

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
////
////   IMPLEMENTATION
////
////

#ifdef STB_TRUETYPE_IMPLEMENTATION

#ifndef STBTT_MAX_OVERSAMPLE
#define STBTT_MAX_OVERSAMPLE   8
#endif

typedef int stbtt__test_oversample_pow2[(STBTT_MAX_OVERSAMPLE & (STBTT_MAX_OVERSAMPLE-1)) == 0 ? 1 : -1];

//////////////////////////////////////////////////////////////////////////
//
// accessors to parse data from file
//

// on platforms that don't allow misaligned reads, if we want to allow
// truetype fonts that aren't padded to alignment, define ALLOW_UNALIGNED_TRUETYPE

""".}


{.push overflowChecks: off.}

proc ttBYTE(p: font_type): uint8 {.exportc.} = p[0]
proc ttBYTE(p: font_type, idx: int): uint8 = p[idx]
proc ttCHAR(p: font_type): int8 {.exportc.} = cast[int8](p[0])
proc ttCHAR(p: font_type, idx: int): int8 = cast[int8](p[idx])

proc ttUSHORT(p: font_type): uint16 {.exportc.} = (p[0].uint16 * 256) + p[1].uint16
proc ttUSHORT(p: font_type, idx: int): uint16 = (p[idx].uint16 * 256) + p[idx + 1].uint16
proc ttSHORT(p: font_type): int16 {.exportc.} = (p[0].int16 * 256) + p[1].int16
proc ttSHORT(p: font_type, idx: int): int16 = (p[idx].int16 * 256) + p[idx + 1].int16

proc ttULONG(p: font_type): uint32 {.exportc.} = (p[0].uint32 shl 24) + (p[1].uint32 shl 16) + (p[2].uint32 shl 8) + p[3].uint32
proc ttULONG(p: font_type, idx: int): uint32 = (p[idx].uint32 shl 24) + (p[idx + 1].uint32 shl 16) + (p[idx + 2].uint32 shl 8) + p[idx + 3].uint32

proc ttLONG(p: font_type, idx: int): int32 = (p[idx].int32 shl 24) + (p[idx + 1].int32 shl 16) + (p[idx + 2].int32 shl 8) + p[idx + 3].int32

{.pop.}


proc stbtt_tag4(p: openarray[uint8], idx: int, c0, c1, c2, c3: char): bool =
    p[idx].char == c0 and p[idx + 1].char == c1 and p[idx + 2].char == c2 and p[idx + 3].char == c3

proc stbtt_tag(p: openarray[uint8], idx: int, str: cstring): bool =
    stbtt_tag4(p, idx, str[0], str[1], str[2], str[3])

proc stbtt_isfont(font: font_type): bool {.exportc.} =
    stbtt_tag4(font, 0, '1', 0.char, 0.char, 0.char) or stbtt_tag(font, 0, "typ1") or
        stbtt_tag(font, 0, "OTTO") or stbtt_tag4(font, 0, 0.char, 1.char, 0.char, 0.char)

# @OPTIMIZE: binary search
proc stbtt_find_table(data: font_type, fontstart: uint32, tag: cstring): uint32 {.exportc.} =
    let numTables = ttUSHORT(data, fontstart.int + 4).int
    let tabledir = fontstart + 12
    for i in 0 .. numTables:
        let loc = tabledir.int + 16 * i
        if stbtt_tag(data, loc + 0, tag):
            return ttULONG(data, loc + 8)

proc stbtt_GetFontOffsetForIndex(font_collection: font_type, index: cint): cint {.exportc.} =
    # Each .ttf/.ttc file may have more than one font. Each font has a sequential
    # index number starting from 0. Call this function to get the font offset for
    # a given index; it returns -1 if the index is out of range. A regular .ttf
    # file will only define one font and it always be at offset 0, so it will
    # return '0' for index 0, and -1 for all other indices. You can just skip
    # this step if you know it's that kind of font.


    # if it's just a font, there's only one valid index
    if stbtt_isfont(font_collection):
        return if index == 0: 0 else: -1

    #  check if it's a TTC
    if stbtt_tag(font_collection, 0, "ttcf"):
        # version 1?
        if ttULONG(font_collection, 4) == 0x00010000 or ttULONG(font_collection, 4) == 0x00020000:
            let n = ttLONG(font_collection, 8)
            if index >= n:
                return -1
            return ttULONG(font_collection, 12 + index * 14).cint
    return -1


proc stbtt_InitFont*(info: var stbtt_fontinfo, data: ptr font_type, fontstart: cint): cint =
    info.fontstart = fontstart
    let cmap = stbtt_find_table(data[], fontstart.uint32, "cmap")       # required
    info.loca = stbtt_find_table(data[], fontstart.uint32, "loca").cint # required
    info.head = stbtt_find_table(data[], fontstart.uint32, "head").cint # required
    info.glyf = stbtt_find_table(data[], fontstart.uint32, "glyf").cint # required
    info.hhea = stbtt_find_table(data[], fontstart.uint32, "hhea").cint # required
    info.hmtx = stbtt_find_table(data[], fontstart.uint32, "hmtx").cint # required
    info.kern = stbtt_find_table(data[], fontstart.uint32, "kern").cint # not required

    {.emit: "`info`->data = `data`;".}

    if cmap == 0 or info.loca == 0 or info.head == 0 or info.glyf == 0 or info.hhea == 0 or info.hmtx == 0:
      return 0

    let t = stbtt_find_table(data[], fontstart.uint32, "maxp")
    if t == 0:
        info.numGlyphs = 0xffff
    else:
        info.numGlyphs = ttUSHORT(data[], t.int + 4).cint

    # find a cmap encoding table we understand *now* to avoid searching
    # later. (todo: could make this installable)
    # the same regardless of glyph.

    let numTables = ttUSHORT(data[], cmap.int + 2).int
    info.index_map = 0

    for i in 0 .. < numTables:
        let encoding_record = cmap.int + 4 + 8 * i
        # find an encoding we understand:
        case ttUSHORT(data[], encoding_record).PlatformId:
            of STBTT_PLATFORM_ID_MICROSOFT:
                case ttUSHORT(data[], encoding_record + 2):
                    of STBTT_MS_EID_UNICODE_BMP, STBTT_MS_EID_UNICODE_FULL:
                        # MS/Unicode
                        info.index_map = cmap.cint + ttULONG(data[], encoding_record + 4).cint
                    else: discard
            of STBTT_PLATFORM_ID_UNICODE:
                # Mac/iOS has these
                # all the encodingIDs are unicode, so we don't bother to check it
                info.index_map = cmap.cint + ttULONG(data[], encoding_record + 4).cint
            else: discard
    if info.index_map == 0:
        return 0

    info.indexToLocFormat = ttUSHORT(data[], info.head + 50).cint
    return 1

{.emit: """
int N_RAW_NIMCALL stbtt_FindGlyphIndex(stbtt_fontinfo *info, int unicode_codepoint)
{
   stbtt_uint8 *data = info->data;
   stbtt_uint32 index_map = info->index_map;

   stbtt_uint16 format = ttUSHORT(data + index_map + 0);
   if (format == 0) { // apple byte encoding
      stbtt_int32 bytes = ttUSHORT(data + index_map + 2);
      if (unicode_codepoint < bytes-6)
         return ttBYTE(data + index_map + 6 + unicode_codepoint);
      return 0;
   } else if (format == 6) {
      stbtt_uint32 first = ttUSHORT(data + index_map + 6);
      stbtt_uint32 count = ttUSHORT(data + index_map + 8);
      if ((stbtt_uint32) unicode_codepoint >= first && (stbtt_uint32) unicode_codepoint < first+count)
         return ttUSHORT(data + index_map + 10 + (unicode_codepoint - first)*2);
      return 0;
   } else if (format == 2) {
      STBTT_assert(0); // @TODO: high-byte mapping for japanese/chinese/korean
      return 0;
   } else if (format == 4) { // standard mapping for windows fonts: binary search collection of ranges
      stbtt_uint16 segcount = ttUSHORT(data+index_map+6) >> 1;
      stbtt_uint16 searchRange = ttUSHORT(data+index_map+8) >> 1;
      stbtt_uint16 entrySelector = ttUSHORT(data+index_map+10);
      stbtt_uint16 rangeShift = ttUSHORT(data+index_map+12) >> 1;
      stbtt_uint16 item, offset, start, end;

      // do a binary search of the segments
      stbtt_uint32 endCount = index_map + 14;
      stbtt_uint32 search = endCount;

      if (unicode_codepoint > 0xffff)
         return 0;

      // they lie from endCount .. endCount + segCount
      // but searchRange is the nearest power of two, so...
      if (unicode_codepoint >= ttUSHORT(data + search + rangeShift*2))
         search += rangeShift*2;

      // now decrement to bias correctly to find smallest
      search -= 2;
      while (entrySelector) {
         stbtt_uint16 end;
         searchRange >>= 1;
         end = ttUSHORT(data + search + searchRange*2);
         if (unicode_codepoint > end)
            search += searchRange*2;
         --entrySelector;
      }
      search += 2;

      {
         stbtt_uint16 offset, start;
         stbtt_uint16 item = (stbtt_uint16) ((search - endCount) >> 1);

         STBTT_assert(unicode_codepoint <= ttUSHORT(data + endCount + 2*item));
         start = ttUSHORT(data + index_map + 14 + segcount*2 + 2 + 2*item);
         if (unicode_codepoint < start)
            return 0;

         offset = ttUSHORT(data + index_map + 14 + segcount*6 + 2 + 2*item);
         if (offset == 0)
            return (stbtt_uint16) (unicode_codepoint + ttSHORT(data + index_map + 14 + segcount*4 + 2 + 2*item));

         return ttUSHORT(data + offset + (unicode_codepoint-start)*2 + index_map + 14 + segcount*6 + 2 + 2*item);
      }
   } else if (format == 12 || format == 13) {
      stbtt_uint32 ngroups = ttULONG(data+index_map+12);
      stbtt_int32 low,high;
      low = 0; high = (stbtt_int32)ngroups;
      // Binary search the right group.
      while (low < high) {
         stbtt_int32 mid = low + ((high-low) >> 1); // rounds down, so low <= mid < high
         stbtt_uint32 start_char = ttULONG(data+index_map+16+mid*12);
         stbtt_uint32 end_char = ttULONG(data+index_map+16+mid*12+4);
         if ((stbtt_uint32) unicode_codepoint < start_char)
            high = mid;
         else if ((stbtt_uint32) unicode_codepoint > end_char)
            low = mid+1;
         else {
            stbtt_uint32 start_glyph = ttULONG(data+index_map+16+mid*12+8);
            if (format == 12)
               return start_glyph + unicode_codepoint-start_char;
            else // format == 13
               return start_glyph;
         }
      }
      return 0; // not found
   }
   // @TODO
   STBTT_assert(0);
   return 0;
}

""".}

proc stbtt_GetGlyphShape*(info: stbtt_fontinfo, glyph_index: cint): seq[stbtt_vertex]

proc stbtt_GetCodepointShape*(info: stbtt_fontinfo, unicode_codepoint: cint): seq[stbtt_vertex] =
    stbtt_GetGlyphShape(info, stbtt_FindGlyphIndex(info, unicode_codepoint))

proc stbtt_setvertex(v: var stbtt_vertex, t: STBTT_type, x, y, cx, cy: int32) {.exportc.} =
    v.`type` = t
    v.x = cast[int16](x)
    v.y = cast[int16](y)
    v.cx = cast[int16](cx)
    v.cy = cast[int16](cy)

proc stbtt_GetGlyfOffset(info: stbtt_fontinfo, glyph_index: cint): cint {.exportc.} =
    if glyph_index >= info.numGlyphs: return -1 # glyph index out of range
    if info.indexToLocFormat >= 2:    return -1 # unknown index->glyph map format

    var g1, g2: cint
    if info.indexToLocFormat == 0:
        g1 = info.glyf + ttUSHORT(info.data[], info.loca + glyph_index * 2).cint * 2
        g2 = info.glyf + ttUSHORT(info.data[], info.loca + glyph_index * 2 + 2).cint * 2
    else:
        g1 = info.glyf + ttULONG(info.data[], info.loca + glyph_index * 4).cint
        g2 = info.glyf + ttULONG(info.data[], info.loca + glyph_index * 4 + 4).cint

    result = if g1==g2: -1 else: g1 # if length is 0, return -1

proc stbtt_GetGlyphBox*(info: stbtt_fontinfo, glyph_index: cint, x0, y0, x1, y1: ptr cint): bool =
    # as above, but takes one or more glyph indices for greater efficiency
    let g = stbtt_GetGlyfOffset(info, glyph_index)
    if g < 0: return false

    if x0 != nil: x0[] = ttSHORT(info.data[], g + 2)
    if y0 != nil: y0[] = ttSHORT(info.data[], g + 4)
    if x1 != nil: x1[] = ttSHORT(info.data[], g + 6)
    if y1 != nil: y1[] = ttSHORT(info.data[], g + 8)
    return true

proc stbtt_IsGlyphEmpty*(info: stbtt_fontinfo, glyph_index: cint): bool =
    # returns non-zero if nothing is drawn for this glyph
    let g = stbtt_GetGlyfOffset(info, glyph_index)
    if g < 0: return true
    let numberOfContours = ttSHORT(info.data[], g)
    return numberOfContours == 0

proc stbtt_GetCodepointBox*(info: stbtt_fontinfo, codepoint: cint, x0, y0, x1, y1: ptr cint): bool =
    # Gets the bounding box of the visible part of the glyph, in unscaled coordinates
    stbtt_GetGlyphBox(info, stbtt_FindGlyphIndex(info,codepoint), x0,y0,x1,y1)

proc stbtt_close_shape(vertices: var openarray[stbtt_vertex], num_vertices, was_off, start_off: cint,
         sx, sy, scx, scy, cx, cy: int32): cint {.exportc.} =
    result = num_vertices
    if start_off != 0:
        if was_off != 0:
            stbtt_setvertex(vertices[result], STBTT_vcurve, (cx+scx) shr 1, (cy+scy) shr 1, cx, cy)
            inc result
        stbtt_setvertex(vertices[result], STBTT_vcurve, sx, sy, scx, scy)
        inc result
    else:
        if was_off != 0:
            stbtt_setvertex(vertices[result], STBTT_vcurve, sx, sy, cx, cy)
        else:
            stbtt_setvertex(vertices[result], STBTT_vline, sx, sy, 0, 0)
        inc result

proc stbtt_GetGlyphShape(info: stbtt_fontinfo, glyph_index: cint): seq[stbtt_vertex] =
  # returns # of vertices and fills *vertices with the pointer to them
  #   these are expressed in "unscaled" coordinates
  #
  # The shape is a series of countours. Each one starts with
  # a STBTT_moveto, then consists of a series of mixed
  # STBTT_lineto and STBTT_curveto segments. A lineto
  # draws a line from previous endpoint to its x,y; a curveto
  # draws a quadratic bezier from previous endpoint to
  # its x,y, using cx,cy as the bezier control point.

  #pvertices[] = nil

  let g = stbtt_GetGlyfOffset(info, glyph_index)
  if g < 0: return @[]

  let numberOfContours = ttSHORT(info.data[], g)
  var num_vertices: cint = 0

  #var vertices: ptr stbtt_vertex
  var vertices : seq[stbtt_vertex]

  if numberOfContours > 0:
     var flags = 0'u8
     var flagcount = 0'u8
     let ins: int32 = ttUSHORT(info.data[], g + 10 + numberOfContours * 2).int32
     let endPtsOfContours = g + 10
     var points = g + 10 + numberOfContours * 2 + 2 + ins
     let n : int32 = (1'u16 + ttUSHORT(info.data[], endPtsOfContours + numberOfContours * 2 - 2)).int32
     let m : int32 = n + 2 * numberOfContours # a loose bound on how many vertices we might need
     #vertices = cast[ptr stbtt_vertex](alloc(m * sizeof(stbtt_vertex)))
     vertices = newSeq[stbtt_vertex](m)

     # in first pass, we load uninterpreted data into the allocated array
     # above, shifted to the end of the array so we won't overwrite it when
     # we create our final data starting from the front

     let off = m - n # starting offset for uninterpreted data, regardless of how m ends up being calculated

     # first load flags

     for i in 0 ..< n:
        if flagcount == 0:
           flags = ttBYTE(info.data[], points)
           inc points
           if (flags and 8) != 0:
               flagcount = ttBYTE(info.data[], points)
               inc points
        else:
           dec flagcount
        vertices[off+i].`type` = cast[STBTT_type](flags)

     # now load x coordinates
     var x: int32
     for i in 0 ..< n:
        flags = vertices[off+i].`type`.uint8
        if (flags and 2) != 0:
           let dx : int16 = ttBYTE(info.data[], points).int16
           inc points
           x += (if (flags and 16) != 0: dx else: -dx) # ???
        else:
           if (flags and 16) == 0:
              x = x + ttSHORT(info.data[], points)
              points += 2
        vertices[off+i].x = x.int16

     # now load y coordinates
     var y: int32

     for i in 0 ..< n:
        flags = vertices[off+i].`type`.uint8
        if (flags and 4) != 0:
           let dy = ttBYTE(info.data[], points).int16
           inc points
           y += (if (flags and 32) != 0: dy else: -dy) # ???
        else:
           if (flags and 32) == 0:
              y += ttSHORT(info.data[], points)
              points += 2
        vertices[off+i].y = y.int16

     # now convert them to our format
     var cx,cy,sx,sy, scx,scy: int32
     var j : int32
     var was_off, start_off: int32
     var next_move : int32
     var i = 0
     while i < n:
        flags = vertices[off+i].`type`.uint8
        x     = vertices[off+i].x.int16;
        y     = vertices[off+i].y.int16;

        if next_move == i:
           if i != 0:
               num_vertices = stbtt_close_shape(vertices, num_vertices, was_off, start_off, sx,sy,scx,scy,cx,cy);
           # now start the new one
           start_off = if (flags and 1) == 0: 1 else: 0
           if start_off != 0:
              # if we start off with an off-curve point, then when we need to find a point on the curve
              # where we can start, and we need to save some state for when we wraparound.
              scx = x
              scy = y
              if (vertices[off+i+1].`type`.uint16 and 1) == 0:
                 # next point is also a curve point, so interpolate an on-point curve
                 sx = (x + vertices[off+i+1].x.int32) shr 1
                 sy = (y + vertices[off+`i`+1].y.int32) shr 1
              else:
                 # otherwise just use the next point as our start point
                 sx = vertices[off+i+1].x.int32;
                 sy = vertices[off+i+1].y.int32;
                 inc i # we're using point i+1 as the starting point, so skip it
           else:
              sx = x
              sy = y
           stbtt_setvertex(vertices[num_vertices], STBTT_vmove,sx,sy,0,0)
           inc num_vertices
           was_off = 0
           next_move = (1'u16 + ttUSHORT(info.data[], endPtsOfContours + j * 2)).int32
           inc j
        else:
           if (flags and 1) == 0: # if it's a curve
              if was_off != 0: # two off-curve control points in a row means interpolate an on-curve midpoint
                  stbtt_setvertex(vertices[num_vertices], STBTT_vcurve, (cx+x) shr 1, (cy+y) shr 1, cx, cy)
                  inc num_vertices
              cx = x
              cy = y
              was_off = 1
           else:
              if was_off != 0:
                 stbtt_setvertex(vertices[num_vertices], STBTT_vcurve, x,y, cx, cy)
              else:
                 stbtt_setvertex(vertices[num_vertices], STBTT_vline, x,y,0,0)
              inc num_vertices
              was_off = 0
        inc i
     num_vertices = stbtt_close_shape(vertices, num_vertices, was_off, start_off, sx,sy,scx,scy,cx,cy);
  elif numberOfContours == -1:
     # Compound shapes.
     var more : cint = 1
     var comp = g + 10
     while more != 0:
        var mtx: array[6, cfloat] = [1.cfloat, 0, 0, 1, 0, 0]
        var flags = ttSHORT(info.data[], comp).uint16
        comp += 2
        var gidx = ttSHORT(info.data[], comp).uint16
        comp += 2

        if (flags and 2) != 0: # XY values
           if (flags and 1) != 0: # shorts
              mtx[4] = ttSHORT(info.data[], comp).cfloat; comp+=2;
              mtx[5] = ttSHORT(info.data[], comp).cfloat; comp+=2;
           else:
              mtx[4] = ttCHAR(info.data[], comp).cfloat; comp+=1;
              mtx[5] = ttCHAR(info.data[], comp).cfloat; comp+=1;
        else:
           # @TODO handle matching point
           assert(false)

        if (flags and (1 shl 3)) != 0: # WE_HAVE_A_SCALE
           mtx[0] = ttSHORT(info.data[], comp).cfloat/16384.0; comp+=2;
           mtx[3] = mtx[0]
           mtx[1] = 0
           mtx[2] = 0
        elif (flags and (1 shl 6)) != 0: # WE_HAVE_AN_X_AND_YSCALE
           mtx[0] = ttSHORT(info.data[], comp).cfloat/16384.0; comp+=2;
           mtx[1] = 0
           mtx[2] = 0
           mtx[3] = ttSHORT(info.data[], comp).cfloat/16384.0f; comp+=2;
        elif (flags and (1 shl 7)) != 0: # WE_HAVE_A_TWO_BY_TWO
           mtx[0] = ttSHORT(info.data[], comp).cfloat/16384.0; comp+=2;
           mtx[1] = ttSHORT(info.data[], comp).cfloat/16384.0; comp+=2;
           mtx[2] = ttSHORT(info.data[], comp).cfloat/16384.0; comp+=2;
           mtx[3] = ttSHORT(info.data[], comp).cfloat/16384.0; comp+=2;

        # Find transformation scales.
        let m = sqrt(mtx[0]*mtx[0] + mtx[1]*mtx[1])
        let n = sqrt(mtx[2]*mtx[2] + mtx[3]*mtx[3])

        # Get indexed glyph.
        var comp_verts = stbtt_GetGlyphShape(info, gidx.cint)

        if comp_verts.len > 0:
           # Transform vertices.
           for i in 0 ..< comp_verts.len:
              var v = addr comp_verts[i]
              var x = v.x
              var y = v.y

              v.x = (m * (mtx[0]* x.cfloat + mtx[2]* y.cfloat + mtx[4])).stbtt_vertex_type
              v.y = (n * (mtx[1]* x.cfloat + mtx[3]* y.cfloat + mtx[5])).stbtt_vertex_type
              x = v.cx
              y = v.cy
              v.cx = (m * (mtx[0] * x.cfloat + mtx[2] * y.cfloat + mtx[4])).stbtt_vertex_type
              v.cy = (n * (mtx[1] * x.cfloat + mtx[3] * y.cfloat + mtx[5])).stbtt_vertex_type

           # Append vertices.
           if vertices.isNil:
               vertices = comp_verts
           else:
               vertices.add(comp_verts)
           num_vertices += comp_verts.len.cint

        # More components ?
        more = flags.cint and (1 shl 5)
  elif numberOfContours < 0:
     # @TODO other compound variations?
     assert(false)
  else:
     # numberOfCounters == 0, do nothing
     discard

  if vertices.isNil:
    return @[]

  if num_vertices > 0:
    vertices.setLen(num_vertices)
  return vertices

proc stbtt_GetGlyphHMetrics*(info: stbtt_fontinfo, glyph_index: cint, advanceWidth, leftSideBearing: var cint) {.exportc.} =
    let numOfLongHorMetrics = ttUSHORT(info.data[], info.hhea + 34).int
    if glyph_index < numOfLongHorMetrics:
        advanceWidth    = ttSHORT(info.data[], info.hmtx + 4 * glyph_index)
        leftSideBearing = ttSHORT(info.data[], info.hmtx + 4 * glyph_index + 2)
    else:
        advanceWidth    = ttSHORT(info.data[], info.hmtx + 4 * (numOfLongHorMetrics - 1))
        leftSideBearing = ttSHORT(info.data[], info.hmtx + 4 * numOfLongHorMetrics + 2 * (glyph_index - numOfLongHorMetrics))

proc stbtt_GetGlyphKernAdvance*(info: stbtt_fontinfo, glyph1, glyph2: cint): cint =
    # we only look at the first table. it must be 'horizontal' and format 0.
    if info.kern == 0:
        return 0
    if ttUSHORT(info.data[], info.kern + 2) < 1: # number of tables, need at least 1
        return 0
    if ttUSHORT(info.data[], info.kern + 8) != 1: # horizontal flag must be set in format
        return 0
    var l: cint = 0
    var r: cint = cast[cint](ttUSHORT(info.data[], info.kern + 10) - 1)
    let needle : uint32 = (cast[uint32](glyph1) shl 16) or cast[uint32](glyph2)
    while (l <= r):
        let m : cint = (l + r) shr 1
        let straw = ttULONG(info.data[], info.kern + 18 + (m * 6)) # note: unaligned read
        if (needle < straw):
            r = m - 1
        elif (needle > straw):
            l = m + 1
        else:
            return ttSHORT(info.data[], info.kern + 22 + (m * 6))
    return 0

proc stbtt_GetCodepointKernAdvance*(info: stbtt_fontinfo, ch1, ch2: cint): cint =
    # an additional amount to add to the 'advance' value between ch1 and ch2
    if info.kern == 0: # if no kerning table, don't waste time looking up both codepoint->glyphs
       return 0
    return stbtt_GetGlyphKernAdvance(info, stbtt_FindGlyphIndex(info, ch1), stbtt_FindGlyphIndex(info, ch2))

proc stbtt_GetCodepointHMetrics*(info: stbtt_fontinfo, codepoint: cint, advanceWidth, leftSideBearing: var cint) =
    # leftSideBearing is the offset from the current horizontal position to the left edge of the character
    # advanceWidth is the offset from the current horizontal position to the next horizontal position
    # these are expressed in unscaled coordinates
    stbtt_GetGlyphHMetrics(info, stbtt_FindGlyphIndex(info,codepoint), advanceWidth, leftSideBearing)

proc stbtt_GetFontVMetrics*(info: stbtt_fontinfo, ascent, descent, lineGap: var cint) =
    # ascent is the coordinate above the baseline the font extends; descent
    # is the coordinate below the baseline the font extends (i.e. it is typically negative)
    # lineGap is the spacing between one row's descent and the next row's ascent...
    # so you should advance the vertical position by "*ascent - *descent + *lineGap"
    #   these are expressed in unscaled coordinates, so you must multiply by
    #   the scale factor for a given size

    ascent  = ttSHORT(info.data[], info.hhea + 4)
    descent = ttSHORT(info.data[], info.hhea + 6)
    lineGap = ttSHORT(info.data[], info.hhea + 8)

proc stbtt_GetFontBoundingBox*(info: stbtt_fontinfo, x0, y0, x1, y1: var int) =
    # the bounding box around all possible characters
    x0 = ttSHORT(info.data[], info.head + 36)
    y0 = ttSHORT(info.data[], info.head + 38)
    x1 = ttSHORT(info.data[], info.head + 40)
    y1 = ttSHORT(info.data[], info.head + 42)

proc stbtt_ScaleForPixelHeight*(info: stbtt_fontinfo, height: cfloat): cfloat {.exportc.} =
    # computes a scale factor to produce a font whose "height" is 'pixels' tall.
    # Height is measured as the distance from the highest ascender to the lowest
    # descender; in other words, it's equivalent to calling stbtt_GetFontVMetrics
    # and computing:
    #       scale = pixels / (ascent - descent)
    # so if you prefer to measure height by the ascent only, use a similar calculation.

    let fheight = ttSHORT(info.data[], info.hhea + 4) - ttSHORT(info.data[], info.hhea + 6)
    result = height / fheight.cfloat

proc stbtt_ScaleForMappingEmToPixels*(info: stbtt_fontinfo, pixels: cfloat): cfloat {.exportc.} =
    ## computes a scale factor to produce a font whose EM size is mapped to
    ## 'pixels' tall. This is probably what traditional APIs compute, but
    ## I'm not positive.
    return pixels / ttUSHORT(info.data[], info.head + 18).cfloat


{.emit: """

void stbtt_FreeShape(const stbtt_fontinfo *info, stbtt_vertex *v)
{
    STBTT_free(v, info->userdata);
}

""".}

################################################################################
#
# antialiasing software rasterizer
#
proc stbtt_GetGlyphBitmapBoxSubpixel(info: stbtt_fontinfo, glyph: cint, scale_x, scale_y, shift_x, shift_y: cfloat, ix0, iy0, ix1, iy1: ptr cint) =
    var x0, y0, x1, y1: cint
    if not stbtt_GetGlyphBox(info, glyph, addr x0, addr y0, addr x1, addr y1):
        # e.g. space character
        if not ix0.isNil: ix0[] = 0
        if not iy0.isNil: iy0[] = 0
        if not ix1.isNil: ix1[] = 0
        if not iy1.isNil: iy1[] = 0
    else:
        # move to integral bboxes (treating pixels as little squares, what pixels get touched)?
        if not ix0.isNil: ix0[] = floor( x0.cfloat * scale_x + shift_x).cint
        if not iy0.isNil: iy0[] = floor(-y1.cfloat * scale_y + shift_y).cint
        if not ix1.isNil: ix1[] = ceil( x1.cfloat * scale_x + shift_x).cint
        if not iy1.isNil: iy1[] = ceil(-y0.cfloat * scale_y + shift_y).cint

proc stbtt_GetGlyphBitmapBox(info: stbtt_fontinfo, glyph: cint, scale_x, scale_y: cfloat, ix0, iy0, ix1, iy1: ptr cint) {.exportc.} =
    stbtt_GetGlyphBitmapBoxSubpixel(info, glyph, scale_x, scale_y, 0.0, 0.0, ix0, iy0, ix1, iy1)

proc stbtt_GetCodepointBitmapBoxSubpixel(info: stbtt_fontinfo, codepoint: cint, scale_x, scale_y, shift_x, shift_y: cfloat, ix0, iy0, ix1, iy1: ptr cint) {.exportc.} =
    # same as stbtt_GetCodepointBitmapBox, but you can specify a subpixel
    # shift for the character
    stbtt_GetGlyphBitmapBoxSubpixel(info, stbtt_FindGlyphIndex(info, codepoint), scale_x, scale_y, shift_x, shift_y, ix0, iy0, ix1, iy1)

proc stbtt_GetCodepointBitmapBox*(info: stbtt_fontinfo, codepoint: cint, scale_x, scale_y: cfloat, ix0, iy0, ix1, iy1: ptr cint) =
    # get the bbox of the bitmap centered around the glyph origin; so the
    # bitmap width is ix1-ix0, height is iy1-iy0, and location to place
    # the bitmap top left is (leftSideBearing*scale,iy0).
    # (Note that the bitmap uses y-increases-down, but the shape uses
    # y-increases-up, so CodepointBitmapBox and CodepointBox are inverted.)
    stbtt_GetCodepointBitmapBoxSubpixel(info, codepoint, scale_x, scale_y, 0.0, 0.0, ix0, iy0, ix1, iy1)

################################################################################
#
#  Rasterizer

type stbtt_hheap_chunk {.exportc.} = object
    next: ptr stbtt_hheap_chunk

type stbtt_hheap {.exportc.} = object
    head: ptr stbtt_hheap_chunk
    first_free: pointer
    num_remaining_in_head_chunk: cint

{.push stackTrace: off.}
proc stbtt_hheap_alloc(hh: ptr stbtt_hheap, size: csize, userdata: pointer): pointer {.exportc.} =
   {.emit: """
   (void)(sizeof(`stbtt_hheap_chunk`)); // Fix nim bug
   if (`hh`->first_free) {
      void *p = `hh`->first_free;
      `hh`->first_free = * (void **) p;
      return p;
   } else {
      if (`hh`->num_remaining_in_head_chunk == 0) {
         int count = (`size` < 32 ? 2000 : `size` < 128 ? 800 : 100);
         stbtt_hheap_chunk *c = (stbtt_hheap_chunk *) STBTT_malloc(sizeof(stbtt_hheap_chunk) + `size` * count, `userdata`);
         if (c == NULL)
            return NULL;
         c->next = `hh`->head;
         `hh`->head = c;
         `hh`->num_remaining_in_head_chunk = count;
      }
      --`hh`->num_remaining_in_head_chunk;
      return (char *) (`hh`->head) + `size` * `hh`->num_remaining_in_head_chunk;
   }
   """.}

proc stbtt_hheap_free(hh: ptr stbtt_hheap, p: pointer) {.exportc.} =
   {.emit: """
   *(void **) `p` = `hh`->first_free;
   `hh`->first_free = `p`;
   """.}

proc stbtt_hheap_cleanup(hh: ptr stbtt_hheap, userdata: pointer) {.exportc.} =
   {.emit: """
   stbtt_hheap_chunk *c = `hh`->head;
   while (c) {
      stbtt_hheap_chunk *n = c->next;
      STBTT_free(c, `userdata`);
      c = n;
   }
   """.}
{.pop.}

type stbtt_edge {.exportc.} = object
    x0,y0, x1,y1: cfloat
    invert: cint

type stbtt_active_edge {.exportc.} = object
    next: ptr stbtt_active_edge
    fx,fdx,fdy: cfloat
    direction: cfloat
    sy: cfloat
    ey: cfloat

{.push stackTrace: off.}
proc stbtt_new_active(hh: ptr stbtt_hheap, e: ptr stbtt_edge, off_x: cint, start_point: cfloat, userdata: pointer): ptr stbtt_active_edge =
   {.emit: """
   stbtt_active_edge *z = (stbtt_active_edge *) stbtt_hheap_alloc(`hh`, sizeof(*z), `userdata`);
   float dxdy = (`e`->x1 - `e`->x0) / (`e`->y1 - `e`->y0);
   //STBTT_assert(`e`->y0 <= `start_point`);
   if (!z) return z;
   z->fdx = dxdy;
   z->fdy = dxdy != 0.0f ? (1.0f/dxdy) : 0.0f;
   z->fx = `e`->x0 + dxdy * (`start_point` - `e`->y0);
   z->fx -= `off_x`;
   z->direction = `e`->invert ? 1.0f : -1.0f;
   z->sy = `e`->y0;
   z->ey = `e`->y1;
   z->next = 0;
   `result` = z;
   """.}

# the edge passed in here does not cross the vertical line at x or the vertical line at x+1
# (i.e. it has already been clipped to those)
proc stbtt_handle_clipped_edge(scanline: ptr cfloat, x: cint, e: ptr stbtt_active_edge, x0, y0, x1, y1: cfloat) {.exportc.} =
   {.emit: """
   if (`y0` == `y1`) return;
   STBTT_assert(`y0` < `y1`);
   STBTT_assert(`e`->sy <= `e`->ey);
   if (`y0` > `e`->ey) return;
   if (`y1` < `e`->sy) return;
   if (`y0` < `e`->sy) {
      `x0` += (`x1`-`x0`) * (`e`->sy - `y0`) / (`y1`-`y0`);
      `y0` = `e`->sy;
   }
   if (`y1` > `e`->ey) {
      `x1` += (`x1`-`x0`) * (`e`->ey - `y1`) / (`y1`-`y0`);
      `y1` = `e`->ey;
   }

   if (`x0` == `x`)
      STBTT_assert(`x1` <= `x`+1);
   else if (`x0` == `x`+1)
      STBTT_assert(`x1` >= `x`);
   else if (`x0` <= `x`)
      STBTT_assert(`x1` <= `x`);
   else if (`x0` >= `x`+1)
      STBTT_assert(`x1` >= `x`+1);
   else
      STBTT_assert(`x1` >= `x` && `x1` <= `x`+1);

   if (`x0` <= `x` && `x1` <= `x`)
      `scanline`[`x`] += `e`->direction * (`y1`-`y0`);
   else if (`x0` >= `x`+1 && `x1` >= `x`+1)
      ;
   else {
      STBTT_assert(`x0` >= `x` && `x0` <= `x`+1 && `x1` >= `x` && `x1` <= `x`+1);
      `scanline`[`x`] += `e`->direction * (`y1`-`y0`) * (1-((`x0`-`x`)+(`x1`-`x`))/2); // coverage = 1 - average x position
   }
   """.}

proc stbtt_fill_active_edges_new(scanline, scanline_fill: ptr cfloat, length: cint, e: ptr stbtt_active_edge, y_top: cfloat) =
   {.emit: """
   float y_bottom = `y_top`+1;

   while (`e`) {
      // brute force every pixel

      // compute intersection points with top & bottom
      STBTT_assert(`e`->ey >= `y_top`);

      if (`e`->fdx == 0) {
         float x0 = `e`->fx;
         if (x0 < `length`) {
            if (x0 >= 0) {
               stbtt_handle_clipped_edge(`scanline`,(int) x0,`e`, x0,`y_top`, x0,y_bottom);
               stbtt_handle_clipped_edge(`scanline_fill`-1,(int) x0+1,`e`, x0,`y_top`, x0,y_bottom);
            } else {
               stbtt_handle_clipped_edge(`scanline_fill`-1,0,`e`, x0,`y_top`, x0,y_bottom);
            }
         }
      } else {
         float x0 = `e`->fx;
         float dx = `e`->fdx;
         float xb = x0 + dx;
         float x_top, x_bottom;
         float sy0,sy1;
         float dy = `e`->fdy;
         STBTT_assert(`e`->sy <= y_bottom && `e`->ey >= `y_top`);

         // compute endpoints of line segment clipped to this scanline (if the
         // line segment starts on this scanline. x0 is the intersection of the
         // line with y_top, but that may be off the line segment.
         if (`e`->sy > `y_top`) {
            x_top = x0 + dx * (`e`->sy - `y_top`);
            sy0 = `e`->sy;
         } else {
            x_top = x0;
            sy0 = `y_top`;
         }
         if (`e`->ey < y_bottom) {
            x_bottom = x0 + dx * (`e`->ey - `y_top`);
            sy1 = `e`->ey;
         } else {
            x_bottom = xb;
            sy1 = y_bottom;
         }

         if (x_top >= 0 && x_bottom >= 0 && x_top < `length` && x_bottom < `length`) {
            // from here on, we don't have to range check x values

            if ((int) x_top == (int) x_bottom) {
               float height;
               // simple case, only spans one pixel
               int x = (int) x_top;
               height = sy1 - sy0;
               STBTT_assert(x >= 0 && x < `length`);
               `scanline`[x] += `e`->direction * (1-((x_top - x) + (x_bottom-x))/2)  * height;
               `scanline_fill`[x] += `e`->direction * height; // everything right of this pixel is filled
            } else {
               int x,x1,x2;
               float y_crossing, step, sign, area;
               // covers 2+ pixels
               if (x_top > x_bottom) {
                  // flip `scanline` vertically; signed area is the same
                  float t;
                  sy0 = y_bottom - (sy0 - `y_top`);
                  sy1 = y_bottom - (sy1 - `y_top`);
                  t = sy0, sy0 = sy1, sy1 = t;
                  t = x_bottom, x_bottom = x_top, x_top = t;
                  dx = -dx;
                  dy = -dy;
                  t = x0, x0 = xb, xb = t;
               }

               x1 = (int) x_top;
               x2 = (int) x_bottom;
               // compute intersection with y axis at x1+1
               y_crossing = (x1+1 - x0) * dy + `y_top`;

               sign = `e`->direction;
               // area of the rectangle covered from y0..y_crossing
               area = sign * (y_crossing-sy0);
               // area of the triangle (x_top,y0), (x+1,y0), (x+1,y_crossing)
               `scanline`[x1] += area * (1-((x_top - x1)+(x1+1-x1))/2);

               step = sign * dy;
               for (x = x1+1; x < x2; ++x) {
                  `scanline`[x] += area + step/2;
                  area += step;
               }
               y_crossing += dy * (x2 - (x1+1));

               STBTT_assert(fabs(area) <= 1.01f);

               `scanline`[x2] += area + sign * (1-((x2-x2)+(x_bottom-x2))/2) * (sy1-y_crossing);

               `scanline_fill`[x2] += sign * (sy1-sy0);
            }
         } else {
            // if edge goes outside of box we're drawing, we require
            // clipping logic. since this does not match the intended use
            // of this library, we use a different, very slow brute
            // force implementation
            int x;
            for (x=0; x < `length`; ++x) {
               // cases:
               //
               // there can be up to two intersections with the pixel. any intersection
               // with left or right edges can be handled by splitting into two (or three)
               // regions. intersections with top & bottom do not necessitate case-wise logic.
               //
               // the old way of doing this found the intersections with the left & right edges,
               // then used some simple logic to produce up to three segments in sorted order
               // from top-to-bottom. however, this had a problem: if an x edge was epsilon
               // across the x border, then the corresponding y position might not be distinct
               // from the other y segment, and it might ignored as an empty segment. to avoid
               // that, we need to explicitly produce segments based on x positions.

               // rename variables to clear pairs
               float y0 = `y_top`;
               float x1 = (float) (x);
               float x2 = (float) (x+1);
               float x3 = xb;
               float y3 = y_bottom;
               float y1,y2;

               // x = `e`->x + `e`->dx * (y-`y_top`)
               // (y-`y_top`) = (x - `e`->x) / `e`->dx
               // y = (x - `e`->x) / `e`->dx + `y_top`
               y1 = (x - x0) / dx + `y_top`;
               y2 = (x+1 - x0) / dx + `y_top`;

               if (x0 < x1 && x3 > x2) {         // three segments descending down-right
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x0,y0, x1,y1);
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x1,y1, x2,y2);
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x2,y2, x3,y3);
               } else if (x3 < x1 && x0 > x2) {  // three segments descending down-left
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x0,y0, x2,y2);
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x2,y2, x1,y1);
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x1,y1, x3,y3);
               } else if (x0 < x1 && x3 > x1) {  // two segments across x, down-right
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x0,y0, x1,y1);
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x1,y1, x3,y3);
               } else if (x3 < x1 && x0 > x1) {  // two segments across x, down-left
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x0,y0, x1,y1);
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x1,y1, x3,y3);
               } else if (x0 < x2 && x3 > x2) {  // two segments across x+1, down-right
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x0,y0, x2,y2);
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x2,y2, x3,y3);
               } else if (x3 < x2 && x0 > x2) {  // two segments across x+1, down-left
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x0,y0, x2,y2);
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x2,y2, x3,y3);
               } else {  // one segment
                  stbtt_handle_clipped_edge(`scanline`,x,`e`, x0,y0, x3,y3);
               }
            }
         }
      }
      `e` = `e`->next;
   }
   """.}

# directly AA rasterize edges w/o supersampling
proc stbtt_rasterize_sorted_edges(result: var stbtt_bitmap, e: ptr stbtt_edge, n, vsubsample, off_x, off_y: cint, userdata: pointer) =
   {.emit: """
   stbtt_hheap hh = { 0, 0, 0 };
   stbtt_active_edge *active = NULL;
   int y,j=0, i;
   float scanline_data[129], *scanline, *scanline2;

   if (`result`->w > 64)
      scanline = (float *) STBTT_malloc((`result`->w*2+1) * sizeof(float), `userdata`);
   else
      scanline = scanline_data;

   scanline2 = scanline + `result`->w;

   y = `off_y`;
   `e`[`n`].y0 = (float) (`off_y` + `result`->h) + 1;

   while (j < `result`->h) {
      // find center of pixel for this scanline
      float scan_y_top    = y + 0.0f;
      float scan_y_bottom = y + 1.0f;
      stbtt_active_edge **step = &active;

      STBTT_memset(scanline , 0, `result`->w*sizeof(scanline[0]));
      STBTT_memset(scanline2, 0, (`result`->w+1)*sizeof(scanline[0]));

      // update all active edges;
      // remove all active edges that terminate before the top of this scanline
      while (*step) {
         stbtt_active_edge * z = *step;
         if (z->ey <= scan_y_top) {
            *step = z->next; // delete from list
            STBTT_assert(z->direction);
            z->direction = 0;
            stbtt_hheap_free(&hh, z);
         } else {
            step = &((*step)->next); // advance through list
         }
      }

      // insert all edges that start before the bottom of this scanline
      while (`e`->y0 <= scan_y_bottom) {
         if (`e`->y0 != `e`->y1) {
            stbtt_active_edge *z = `stbtt_new_active`(&hh, `e`, `off_x`, scan_y_top, `userdata`);
            if (z != NULL) {
                STBTT_assert(z->ey >= scan_y_top);
                // insert at front
                z->next = active;
                active = z;
            }
         }
         ++`e`;
      }

      // now process all active edges
      if (active)
         `stbtt_fill_active_edges_new`(scanline, scanline2+1, `result`->w, active, scan_y_top);

      {
         float sum = 0;
         for (i=0; i < `result`->w; ++i) {
            float k;
            int m;
            sum += scanline2[i];
            k = scanline[i] + sum;
            k = (float) STBTT_fabs(k)*255 + 0.5f;
            m = (int) k;
            if (m > 255) m = 255;
            `result`->pixels[j*`result`->stride + i] = (unsigned char) m;
         }
      }
      // advance all the edges
      step = &active;
      while (*step) {
         stbtt_active_edge *z = *step;
         z->fx += z->fdx; // advance to position for current scanline
         step = &((*step)->next); // advance through list
      }

      ++y;
      ++j;
   }

   stbtt_hheap_cleanup(&hh, `userdata`);

   if (scanline != scanline_data)
      STBTT_free(scanline, `userdata`);
   """.}

{.emit: """
#define stbtt_COMPARE(a,b)  ((a)->y0 < (b)->y0)
""".}

proc stbtt_sort_edges_ins_sort(p: ptr stbtt_edge, n: cint) =
   {.emit: """
   int i,j;
   for (i=1; i < `n`; ++i) {
      stbtt_edge t = `p`[i], *a = &t;
      j = i;
      while (j > 0) {
         stbtt_edge *b = &`p`[j-1];
         int c = stbtt_COMPARE(a,b);
         if (!c) break;
         `p`[j] = `p`[j-1];
         --j;
      }
      if (i != j)
         `p`[j] = t;
   }
   """.}

proc stbtt_sort_edges_quicksort(p: ptr stbtt_edge, n: cint) =
   # threshhold for transitioning to insertion sort
   {.emit: """
   while (`n` > 12) {
      stbtt_edge t;
      int c01,c12,c,m,i,j;

      /* compute median of three */
      m = `n` >> 1;
      c01 = stbtt_COMPARE(&`p`[0],&`p`[m]);
      c12 = stbtt_COMPARE(&`p`[m],&`p`[`n`-1]);
      /* if 0 >= mid >= end, or 0 < mid < end, then use mid */
      if (c01 != c12) {
         /* otherwise, we'll need to swap something else to middle */
         int z;
         c = stbtt_COMPARE(&`p`[0],&`p`[`n`-1]);
         /* 0>mid && mid<`n`:  0>`n` => `n`; 0<`n` => 0 */
         /* 0<mid && mid>`n`:  0>`n` => 0; 0<`n` => `n` */
         z = (c == c12) ? 0 : `n`-1;
         t = `p`[z];
         `p`[z] = `p`[m];
         `p`[m] = t;
      }
      /* now p[m] is the median-of-three */
      /* swap it to the beginning so it won't move around */
      t = `p`[0];
      `p`[0] = `p`[m];
      `p`[m] = t;

      /* partition loop */
      i=1;
      j=`n`-1;
      for(;;) {
         /* handling of equality is crucial here */
         /* for sentinels & efficiency with duplicates */
         for (;;++i) {
            if (!stbtt_COMPARE(&`p`[i], &`p`[0])) break;
         }
         for (;;--j) {
            if (!stbtt_COMPARE(&`p`[0], &`p`[j])) break;
         }
         /* make sure we haven't crossed */
         if (i >= j) break;
         t = `p`[i];
         `p`[i] = `p`[j];
         `p`[j] = t;

         ++i;
         --j;
      }
      /* recurse on smaller side, iterate on larger */
      if (j < (`n`-i)) {
         `stbtt_sort_edges_quicksort`(`p`,j);
         `p` = `p`+i;
         `n` = `n`-i;
      } else {
         `stbtt_sort_edges_quicksort`(`p`+i, `n`-i);
         `n` = j;
      }
   }
   """.}

{.pop.} # stackTrace: off

proc stbtt_sort_edges(p: ptr stbtt_edge, n: cint) =
    stbtt_sort_edges_quicksort(p, n)
    stbtt_sort_edges_ins_sort(p, n)

type stbtt_point = object
    x, y: cfloat

proc stbtt_rasterize(result: var stbtt_bitmap, ptsArr: openarray[stbtt_point], wcountArr: openarray[cint], scale_x, scale_y, shift_x, shift_y: cfloat, off_x, off_y, invert: cint, userdata: pointer) {.exportc.} =
    let y_scale_inv = if invert != 0: -scale_y else: scale_y
    let vsubsample : cint = 1
    # vsubsample should divide 255 evenly; otherwise we won't reach full opacity

    # now we have to blow out the windings into explicit edge lists

    var n : cint = 0
    for w in wcountArr: n += w

    var e = newSeq[stbtt_edge](n+1)
    n = 0

    var m : cint = 0

    for i in 0 ..< wcountArr.len:
        let cm = m
        m += wcountArr[i]
        var j = wcountArr[i]-1
        for k in 0 ..< wcountArr[i]:
            var a = k
            var b = j
            # skip the edge if horizontal
            if ptsArr[cm + j].y == ptsArr[cm + k].y:
                j = k.int32
                continue
            # add edge from j to k to the list
            e[n].invert = 0;
            if ( if invert != 0: ptsArr[cm + j].y > ptsArr[cm + k].y else: ptsArr[cm + j].y < ptsArr[cm + k].y):
                e[n].invert = 1
                a = j
                b = k.int32
            e[n].x0 = ptsArr[cm + a].x * scale_x + shift_x;
            e[n].y0 = (ptsArr[cm + a].y * y_scale_inv + shift_y) * vsubsample.float;
            e[n].x1 = ptsArr[cm + b].x * scale_x + shift_x;
            e[n].y1 = (ptsArr[cm + b].y * y_scale_inv + shift_y) * vsubsample.float;
            inc n
            j = k.int32

    let pe = addr e[0]

    # now sort the edges by their highest point (should snap to integer, and then by x)
    stbtt_sort_edges(pe, n);

    # now, traverse the scanlines and find the intersections on each scanline, use xor winding rule
    stbtt_rasterize_sorted_edges(result, pe, n, vsubsample, off_x, off_y, userdata)

proc stbtt_add_point(points: var openarray[stbtt_point], n: int, x, y: float) =
    if n < points.len: # during first pass, it's unallocated
        points[n].x = x
        points[n].y = y

# tesselate until threshhold p is happy... @TODO warped to compensate for non-linear stretching
proc stbtt_tesselate_curve(points: var openarray[stbtt_point], num_points: var cint, x0, y0, x1, y1, x2, y2, objspace_flatness_squared : float, n: int) =
    # midpoint
    let mx = (x0 + 2*x1 + x2)/4
    let my = (y0 + 2*y1 + y2)/4
    # versus directly drawn line
    let dx = (x0+x2)/2 - mx
    let dy = (y0+y2)/2 - my
    if n > 16: # 65536 segments on one curve better be enough!
        return
    if dx*dx+dy*dy > objspace_flatness_squared: # half-pixel error allowed... need to be smaller if AA
        stbtt_tesselate_curve(points, num_points, x0,y0, (x0+x1)/2.0, (y0+y1)/2.0, mx,my, objspace_flatness_squared, n+1)
        stbtt_tesselate_curve(points, num_points, mx,my, (x1+x2)/2.0, (y1+y2)/2.0, x2,y2, objspace_flatness_squared, n+1)
    else:
        stbtt_add_point(points, num_points, x2, y2)
        num_points += 1

# returns number of contours
proc stbtt_FlattenCurves(vertices: openarray[stbtt_vertex], objspace_flatness: cfloat, contour_lengths: var seq[cint]): seq[stbtt_point] =
    var num_points : cint = 0

    let objspace_flatness_squared = objspace_flatness * objspace_flatness
    var n, start: cint

    # count how many "moves" there are to get the contour count
    for v in vertices:
        if v.`type` == STBTT_vmove:
            n += 1

    if n == 0: return
    contour_lengths = newSeq[cint](n)

    var windings = newSeq[stbtt_point](0)

    # make two passes through the points so we don't need to realloc
    for pass in countup(0, 1):
        var x, y: float
        if pass == 1:
            windings.newSeq(num_points)

        num_points = 0
        n = -1
        for v in vertices:
            case v.`type`:
                of STBTT_vmove:
                    # start the next contour
                    if n >= 0:
                        contour_lengths[n] = num_points - start
                    n += 1
                    start = num_points

                    x = v.x.float
                    y = v.y.float
                    stbtt_add_point(windings, num_points, x, y)
                    num_points += 1

                of STBTT_vline:
                    x = v.x.float
                    y = v.y.float
                    stbtt_add_point(windings, num_points, x, y)
                    num_points += 1

                of STBTT_vcurve:
                    stbtt_tesselate_curve(windings, num_points, x,y,
                                        v.cx.float, v.cy.float,
                                        v.x.float,  v.y.float,
                                        objspace_flatness_squared, 0)
                    x = v.x.float
                    y = v.y.float
                else:
                    discard

        contour_lengths[n] = num_points - start

    result = windings

proc stbtt_Rasterize(
        result: var stbtt_bitmap,           # 1-channel bitmap to draw into
        flatness_in_pixels: cfloat,         # allowable error of curve in pixels
        vertices: openarray[stbtt_vertex],  # array of vertices defining shape
        scale_x, scale_y,                   # scale applied to input vertices
        shift_x, shift_y: cfloat,           # translation applied to input vertices
        x_off, y_off,                       # another translation applied to input
        invert: cint,                       # if non-zero, vertically flip shape
        userdata: pointer = nil) =          # context for to STBTT_MALLOC
    let scale = min(scale_x, scale_y)
    var winding_lengths = newSeq[cint]()
    var windings = stbtt_FlattenCurves(vertices, cfloat(flatness_in_pixels / scale), winding_lengths);
    if not windings.isNil:
        stbtt_rasterize(result, windings, winding_lengths, scale_x, scale_y, shift_x, shift_y, x_off, y_off, invert, userdata)
        #if not winding_lengths.isNil: dealloc(winding_lengths)
        #if not windings.isNil: dealloc(windings)

proc stbtt_GetGlyphBitmapSubpixel(info: stbtt_fontinfo, scale_x, scale_y, shift_x, shift_y: cfloat, glyph: cint, width, height, xoff, yoff: ptr cint): ptr uint8 {.exportc.} =
   var ix0,iy0,ix1,iy1 : cint
   var gbm: stbtt_bitmap
   var vertices = stbtt_GetGlyphShape(info, glyph)

   var sx = scale_x
   var sy = scale_y

   if sx == 0: sx = sy
   if sy == 0:
      if sx == 0: return nil
      sy = sx

   stbtt_GetGlyphBitmapBoxSubpixel(info, glyph, sx, sy, shift_x, shift_y, addr ix0, addr iy0, addr ix1, addr iy1)

   # now we get the size
   gbm.w = ix1 - ix0
   gbm.h = iy1 - iy0
   gbm.pixels = nil # in case we error

   if not width.isNil: width[] = gbm.w
   if not height.isNil: height[] = gbm.h
   if not xoff.isNil: xoff[] = ix0
   if not yoff.isNil: yoff[] = iy0

   if gbm.w != 0 and gbm.h != 0:
      gbm.pixels = cast[ptr uint8](alloc(gbm.w * gbm.h))
      if not gbm.pixels.isNil:
         gbm.stride = gbm.w
         stbtt_Rasterize(gbm, 0.35, vertices, sx, sy, shift_x, shift_y, ix0, iy0, 1)

   #if not vertices.isNil: dealloc(vertices)
   result = gbm.pixels

proc stbtt_GetGlyphBitmap*(info: stbtt_fontinfo, scale_x, scale_y: cfloat, glyph: cint, width, height, xoff, yoff: ptr cint): ptr uint8 =
    return stbtt_GetGlyphBitmapSubpixel(info, scale_x, scale_y, 0.0, 0.0, glyph, width, height, xoff, yoff)

proc stbtt_MakeGlyphBitmapSubpixel(info: stbtt_fontinfo, output: ptr uint8, out_w, out_h, out_stride: cint, scale_x, scale_y, shift_x, shift_y: cfloat, glyph: cint) {.exportc.} =
    var ix0, iy0: cint
    var vertices = stbtt_GetGlyphShape(info, glyph)
    var gbm : stbtt_bitmap

    stbtt_GetGlyphBitmapBoxSubpixel(info, glyph, scale_x, scale_y, shift_x, shift_y, addr ix0, addr iy0, nil, nil);
    gbm.pixels = output
    gbm.w = out_w
    gbm.h = out_h
    gbm.stride = out_stride

    if gbm.w != 0 and gbm.h != 0:
        stbtt_Rasterize(gbm, 0.35, vertices, scale_x, scale_y, shift_x, shift_y, ix0, iy0, 1)

proc stbtt_MakeGlyphBitmap*(info: stbtt_fontinfo, output: ptr byte, out_w, out_h, out_stride: cint, scale_x, scale_y: cfloat, glyph: cint) {.exportc.} =
    stbtt_MakeGlyphBitmapSubpixel(info, output, out_w, out_h, out_stride, scale_x, scale_y, 0.0f,0.0f, glyph)

proc stbtt_MakeCodepointBitmap*(info: stbtt_fontinfo, output: ptr byte, out_w, out_h, out_stride: cint, scale_x, scale_y: cfloat, codepoint: cint) {.importc.}

{.emit: """

unsigned char *stbtt_GetCodepointBitmapSubpixel(const stbtt_fontinfo *info, float scale_x, float scale_y, float shift_x, float shift_y, int codepoint, int *width, int *height, int *xoff, int *yoff)
{
   return stbtt_GetGlyphBitmapSubpixel(info, scale_x, scale_y,shift_x,shift_y, stbtt_FindGlyphIndex(info,codepoint), width,height,xoff,yoff);
}

void stbtt_MakeCodepointBitmapSubpixel(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, float shift_x, float shift_y, int codepoint)
{
   stbtt_MakeGlyphBitmapSubpixel(info, output, out_w, out_h, out_stride, scale_x, scale_y, shift_x, shift_y, stbtt_FindGlyphIndex(info,codepoint));
}

unsigned char *stbtt_GetCodepointBitmap(const stbtt_fontinfo *info, float scale_x, float scale_y, int codepoint, int *width, int *height, int *xoff, int *yoff)
{
   return stbtt_GetCodepointBitmapSubpixel(info, scale_x, scale_y, 0.0f,0.0f, codepoint, width,height,xoff,yoff);
}

void stbtt_MakeCodepointBitmap(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, int codepoint)
{
   stbtt_MakeCodepointBitmapSubpixel(info, output, out_w, out_h, out_stride, scale_x, scale_y, 0.0f,0.0f, codepoint);
}

//////////////////////////////////////////////////////////////////////////////
//
// bitmap baking
//
// This is SUPER-CRAPPY packing to keep source code small

extern int stbtt_BakeFontBitmap(const unsigned char *data, int offset,  // font location (use offset=0 for plain .ttf)
                                float pixel_height,                     // height of font in pixels
                                unsigned char *pixels, int pw, int ph,  // bitmap to be filled in
                                int first_char, int num_chars,          // characters to bake
                                stbtt_bakedchar *chardata)
{
   float scale;
   int x,y,bottom_y, i;
   stbtt_fontinfo f;
   if (!stbtt_InitFont(&f, data, offset))
      return -1;
   STBTT_memset(pixels, 0, pw*ph); // background of 0 around pixels
   x=y=1;
   bottom_y = 1;

   scale = stbtt_ScaleForPixelHeight(&f, pixel_height);

   for (i=0; i < num_chars; ++i) {
      int advance, lsb, x0,y0,x1,y1,gw,gh;
      int g = stbtt_FindGlyphIndex(&f, first_char + i);
      stbtt_GetGlyphHMetrics(&f, g, &advance, &lsb);
      stbtt_GetGlyphBitmapBox(&f, g, scale,scale, &x0,&y0,&x1,&y1);
      gw = x1-x0;
      gh = y1-y0;
      if (x + gw + 1 >= pw)
         y = bottom_y, x = 1; // advance to next row
      if (y + gh + 1 >= ph) // check if it fits vertically AFTER potentially moving to next row
         return -i;
      STBTT_assert(x+gw < pw);
      STBTT_assert(y+gh < ph);
      stbtt_MakeGlyphBitmap(&f, pixels+x+y*pw, gw,gh,pw, scale,scale, g);
      chardata[i].x0 = (stbtt_int16) x;
      chardata[i].y0 = (stbtt_int16) y;
      chardata[i].x1 = (stbtt_int16) (x + gw);
      chardata[i].y1 = (stbtt_int16) (y + gh);
      chardata[i].xadvance = scale * advance;
      chardata[i].xoff     = (float) x0;
      chardata[i].yoff     = (float) y0;
      x = x + gw + 1;
      if (y+gh+1 > bottom_y)
         bottom_y = y+gh+1;
   }
   return bottom_y;
}

""".}

proc stbtt_GetBakedQuad*(bakedChar: stbtt_bakedchar, pw, ph: int,  # same data as above
                               xpos, ypos: var cfloat,     # pointers to current position in screen pixel space
                               q: var stbtt_aligned_quad,  # output: quad to draw
                               opengl_fillrule: bool       # true if opengl fill rule; false if DX9 or earlier
                               ) {.exportc.} =
    # Call GetBakedQuad with char_index = 'character - first_char', and it
    # creates the quad you need to draw and advances the current position.
    #
    # The coordinate system used assumes y increases downwards.
    #
    # Characters will extend both above and below the current position;
    # see discussion of "BASELINE" above.
    #
    # It's inefficient; you might want to c&p it and optimize it.
    let
        d3d_bias = if opengl_fillrule: 0.0 else: -0.5
        ipw = 1.0 / pw.float
        iph = 1.0 / ph.float
        round_x = floor((xpos + bakedChar.xoff) + 0.5).int
        round_y = floor((ypos + bakedChar.yoff) + 0.5).int

    q.x0 = round_x.float + d3d_bias
    q.y0 = round_y.float + d3d_bias
    q.x1 = round_x.float + bakedChar.x1.float - bakedChar.x0.float + d3d_bias
    q.y1 = round_y.float + bakedChar.y1.float - bakedChar.y0.float + d3d_bias

    q.s0 = bakedChar.x0.float * ipw
    q.t0 = bakedChar.y0.float * iph
    q.s1 = bakedChar.x1.float * ipw
    q.t1 = bakedChar.y1.float * iph

    xpos += bakedChar.xadvance

type stbrp_coord = cint

{.emit: """

//////////////////////////////////////////////////////////////////////////////
//
// rectangle packing replacement routines if you don't have stb_rect_pack.h
//

#ifndef STB_RECT_PACK_VERSION
#ifdef _MSC_VER
#define STBTT__NOTUSED(v)  (void)(v)
#else
#define STBTT__NOTUSED(v)  (void)sizeof(v)
#endif

typedef int stbrp_coord;

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
// COMPILER WARNING ?!?!?                                                         //
//                                                                                //
//                                                                                //
// if you get a compile warning due to these symbols being defined more than      //
// once, move #include "stb_rect_pack.h" before #include "stb_truetype.h"         //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////

""".}

type stbrp_context {.exportc.} = object
    width,height: cint
    x, y, bottom_y: cint

type stbrp_node {.exportc.} = object
    x: uint8

type stbrp_rect {.exportc.} = object
    x, y: stbrp_coord
    id, w, h, was_packed: cint

proc stbrp_init_target(con: ptr stbrp_context, pw, ph: cint, nodes: openarray[stbrp_node]) {.exportc.} =
    con.width = pw
    con.height = ph
    con.x = 0
    con.y = 0
    con.bottom_y = 0

proc stbrp_pack_rects(con: var stbrp_context, rects: var openarray[stbrp_rect]) {.exportc.} =
    for r in rects.mitems:
        if con.x + r.w > con.width:
            con.x = 0
            con.y = con.bottom_y

        if con.y + r.h > con.height:
            break
        r.x = con.x
        r.y = con.y
        r.was_packed = 1
        con.x += r.w
        if con.y + r.h > con.bottom_y:
            con.bottom_y = con.y + r.h


{.emit: """

#endif

//////////////////////////////////////////////////////////////////////////////
//
// bitmap baking
//
// This is SUPER-AWESOME (tm Ryan Gordon) packing using stb_rect_pack.h. If
// stb_rect_pack.h isn't available, it uses the BakeFontBitmap strategy.

int stbtt_PackBegin(stbtt_pack_context *spc, unsigned char *pixels, int pw, int ph, int stride_in_bytes, int padding, void *alloc_context)
{
   stbrp_context *context = (stbrp_context *) STBTT_malloc(sizeof(*context)            ,alloc_context);
   int            num_nodes = pw - padding;
   stbrp_node    *nodes   = (stbrp_node    *) STBTT_malloc(sizeof(*nodes  ) * num_nodes,alloc_context);

   if (context == NULL || nodes == NULL) {
      if (context != NULL) STBTT_free(context, alloc_context);
      if (nodes   != NULL) STBTT_free(nodes  , alloc_context);
      return 0;
   }

   spc->user_allocator_context = alloc_context;
   spc->width = pw;
   spc->height = ph;
   spc->pixels = pixels;
   spc->pack_info = context;
   spc->nodes = nodes;
   spc->padding = padding;
   spc->stride_in_bytes = stride_in_bytes != 0 ? stride_in_bytes : pw;
   spc->h_oversample = 1;
   spc->v_oversample = 1;

   stbrp_init_target(context, pw-padding, ph-padding, nodes, num_nodes);

   STBTT_memset(pixels, 0, pw*ph); // background of 0 around pixels

   return 1;
}

void stbtt_PackEnd  (stbtt_pack_context *spc)
{
   STBTT_free(spc->nodes    , spc->user_allocator_context);
   STBTT_free(spc->pack_info, spc->user_allocator_context);
}

void stbtt_PackSetOversampling(stbtt_pack_context *spc, unsigned int h_oversample, unsigned int v_oversample)
{
   STBTT_assert(h_oversample <= STBTT_MAX_OVERSAMPLE);
   STBTT_assert(v_oversample <= STBTT_MAX_OVERSAMPLE);
   if (h_oversample <= STBTT_MAX_OVERSAMPLE)
      spc->h_oversample = h_oversample;
   if (v_oversample <= STBTT_MAX_OVERSAMPLE)
      spc->v_oversample = v_oversample;
}

#define STBTT__OVER_MASK  (STBTT_MAX_OVERSAMPLE-1)

static void stbtt__h_prefilter(unsigned char *pixels, int w, int h, int stride_in_bytes, unsigned int kernel_width)
{
   unsigned char buffer[STBTT_MAX_OVERSAMPLE];
   int safe_w = w - kernel_width;
   int j;
   for (j=0; j < h; ++j) {
      int i;
      unsigned int total;
      memset(buffer, 0, kernel_width);

      total = 0;

      // make kernel_width a constant in common cases so compiler can optimize out the divide
      switch (kernel_width) {
         case 2:
            for (i=0; i <= safe_w; ++i) {
               total += pixels[i] - buffer[i & STBTT__OVER_MASK];
               buffer[(i+kernel_width) & STBTT__OVER_MASK] = pixels[i];
               pixels[i] = (unsigned char) (total / 2);
            }
            break;
         case 3:
            for (i=0; i <= safe_w; ++i) {
               total += pixels[i] - buffer[i & STBTT__OVER_MASK];
               buffer[(i+kernel_width) & STBTT__OVER_MASK] = pixels[i];
               pixels[i] = (unsigned char) (total / 3);
            }
            break;
         case 4:
            for (i=0; i <= safe_w; ++i) {
               total += pixels[i] - buffer[i & STBTT__OVER_MASK];
               buffer[(i+kernel_width) & STBTT__OVER_MASK] = pixels[i];
               pixels[i] = (unsigned char) (total / 4);
            }
            break;
         default:
            for (i=0; i <= safe_w; ++i) {
               total += pixels[i] - buffer[i & STBTT__OVER_MASK];
               buffer[(i+kernel_width) & STBTT__OVER_MASK] = pixels[i];
               pixels[i] = (unsigned char) (total / kernel_width);
            }
            break;
      }

      for (; i < w; ++i) {
         STBTT_assert(pixels[i] == 0);
         total -= buffer[i & STBTT__OVER_MASK];
         pixels[i] = (unsigned char) (total / kernel_width);
      }

      pixels += stride_in_bytes;
   }
}

static void stbtt__v_prefilter(unsigned char *pixels, int w, int h, int stride_in_bytes, unsigned int kernel_width)
{
   unsigned char buffer[STBTT_MAX_OVERSAMPLE];
   int safe_h = h - kernel_width;
   int j;
   for (j=0; j < w; ++j) {
      int i;
      unsigned int total;
      memset(buffer, 0, kernel_width);

      total = 0;

      // make kernel_width a constant in common cases so compiler can optimize out the divide
      switch (kernel_width) {
         case 2:
            for (i=0; i <= safe_h; ++i) {
               total += pixels[i*stride_in_bytes] - buffer[i & STBTT__OVER_MASK];
               buffer[(i+kernel_width) & STBTT__OVER_MASK] = pixels[i*stride_in_bytes];
               pixels[i*stride_in_bytes] = (unsigned char) (total / 2);
            }
            break;
         case 3:
            for (i=0; i <= safe_h; ++i) {
               total += pixels[i*stride_in_bytes] - buffer[i & STBTT__OVER_MASK];
               buffer[(i+kernel_width) & STBTT__OVER_MASK] = pixels[i*stride_in_bytes];
               pixels[i*stride_in_bytes] = (unsigned char) (total / 3);
            }
            break;
         case 4:
            for (i=0; i <= safe_h; ++i) {
               total += pixels[i*stride_in_bytes] - buffer[i & STBTT__OVER_MASK];
               buffer[(i+kernel_width) & STBTT__OVER_MASK] = pixels[i*stride_in_bytes];
               pixels[i*stride_in_bytes] = (unsigned char) (total / 4);
            }
            break;
         default:
            for (i=0; i <= safe_h; ++i) {
               total += pixels[i*stride_in_bytes] - buffer[i & STBTT__OVER_MASK];
               buffer[(i+kernel_width) & STBTT__OVER_MASK] = pixels[i*stride_in_bytes];
               pixels[i*stride_in_bytes] = (unsigned char) (total / kernel_width);
            }
            break;
      }

      for (; i < h; ++i) {
         STBTT_assert(pixels[i*stride_in_bytes] == 0);
         total -= buffer[i & STBTT__OVER_MASK];
         pixels[i*stride_in_bytes] = (unsigned char) (total / kernel_width);
      }

      pixels += 1;
   }
}

""".}

proc stbtt_oversample_shift(oversample: cint): float {.exportc.} =
    if oversample != 0:
        # The prefilter is a box filter of width "oversample",
        # which shifts phase by (oversample - 1)/2 pixels in
        # oversampled space. We want to shift in the opposite
        # direction to counter this.
        result = -(oversample - 1).float / (2.0 * oversample.float)

{.emit: """

int stbtt_PackFontRanges(stbtt_pack_context *spc, unsigned char *fontdata, int font_index, stbtt_pack_range *ranges, int num_ranges)
{
   stbtt_fontinfo info;
   float recip_h = 1.0f / spc->h_oversample;
   float recip_v = 1.0f / spc->v_oversample;
   float sub_x = stbtt_oversample_shift(spc->h_oversample);
   float sub_y = stbtt_oversample_shift(spc->v_oversample);
   int i,j,k,n, return_value = 1;
   stbrp_context *context = (stbrp_context *) spc->pack_info;
   stbrp_rect    *rects;

   // flag all characters as NOT packed
   for (i=0; i < num_ranges; ++i)
      for (j=0; j < ranges[i].num_chars_in_range; ++j)
         ranges[i].chardata_for_range[j].x0 =
         ranges[i].chardata_for_range[j].y0 =
         ranges[i].chardata_for_range[j].x1 =
         ranges[i].chardata_for_range[j].y1 = 0;

   n = 0;
   for (i=0; i < num_ranges; ++i)
      n += ranges[i].num_chars_in_range;

   rects = (stbrp_rect *) calloc(n, sizeof(*rects));

   if (rects == NULL)
      return 0;

   stbtt_InitFont(&info, fontdata, stbtt_GetFontOffsetForIndex(fontdata,font_index));
   k=0;
   for (i=0; i < num_ranges; ++i) {
      float fh = ranges[i].font_size;
      float scale = fh > 0 ? stbtt_ScaleForPixelHeight(&info, fh) : stbtt_ScaleForMappingEmToPixels(&info, -fh);
      for (j=0; j < ranges[i].num_chars_in_range; ++j) {
         int x0,y0,x1,y1;
         stbtt_GetCodepointBitmapBoxSubpixel(&info, ranges[i].first_unicode_char_in_range + j,
                                              scale * spc->h_oversample,
                                              scale * spc->v_oversample,
                                              0,0,
                                              &x0,&y0,&x1,&y1);
         rects[k].w = (stbrp_coord) (x1-x0 + spc->padding + spc->h_oversample-1);
         rects[k].h = (stbrp_coord) (y1-y0 + spc->padding + spc->v_oversample-1);
         ++k;
      }
   }

   stbrp_pack_rects(context, rects, k);

   k = 0;
   for (i=0; i < num_ranges; ++i) {
      float fh = ranges[i].font_size;
      float scale = fh > 0 ? stbtt_ScaleForPixelHeight(&info, fh) : stbtt_ScaleForMappingEmToPixels(&info, -fh);
      for (j=0; j < ranges[i].num_chars_in_range; ++j) {
         stbrp_rect *r = &rects[k];
         if (r->was_packed) {
            stbtt_packedchar *bc = &ranges[i].chardata_for_range[j];
            int advance, lsb, x0,y0,x1,y1;
            int glyph = stbtt_FindGlyphIndex(&info, ranges[i].first_unicode_char_in_range + j);
            stbrp_coord pad = (stbrp_coord) spc->padding;

            // pad on left and top
            r->x += pad;
            r->y += pad;
            r->w -= pad;
            r->h -= pad;
            stbtt_GetGlyphHMetrics(&info, glyph, &advance, &lsb);
            stbtt_GetGlyphBitmapBox(&info, glyph,
                                    scale * spc->h_oversample,
                                    scale * spc->v_oversample,
                                    &x0,&y0,&x1,&y1);
            stbtt_MakeGlyphBitmapSubpixel(&info,
                                          spc->pixels + r->x + r->y*spc->stride_in_bytes,
                                          r->w - spc->h_oversample+1,
                                          r->h - spc->v_oversample+1,
                                          spc->stride_in_bytes,
                                          scale * spc->h_oversample,
                                          scale * spc->v_oversample,
                                          0,0,
                                          glyph);

            if (spc->h_oversample > 1)
               stbtt__h_prefilter(spc->pixels + r->x + r->y*spc->stride_in_bytes,
                                  r->w, r->h, spc->stride_in_bytes,
                                  spc->h_oversample);

            if (spc->v_oversample > 1)
               stbtt__v_prefilter(spc->pixels + r->x + r->y*spc->stride_in_bytes,
                                  r->w, r->h, spc->stride_in_bytes,
                                  spc->v_oversample);

            bc->x0       = (stbtt_int16)  r->x;
            bc->y0       = (stbtt_int16)  r->y;
            bc->x1       = (stbtt_int16) (r->x + r->w);
            bc->y1       = (stbtt_int16) (r->y + r->h);
            bc->xadvance =                scale * advance;
            bc->xoff     =       (float)  x0 * recip_h + sub_x;
            bc->yoff     =       (float)  y0 * recip_v + sub_y;
            bc->xoff2    =                (x0 + r->w) * recip_h + sub_x;
            bc->yoff2    =                (y0 + r->h) * recip_v + sub_y;
         } else {
            return_value = 0; // if any fail, report failure
         }

         ++k;
      }
   }

   return return_value;
}

int stbtt_PackFontRange(stbtt_pack_context *spc, unsigned char *fontdata, int font_index, float font_size,
            int first_unicode_char_in_range, int num_chars_in_range, stbtt_packedchar *chardata_for_range)
{
   stbtt_pack_range range;
   range.first_unicode_char_in_range = first_unicode_char_in_range;
   range.num_chars_in_range          = num_chars_in_range;
   range.chardata_for_range          = chardata_for_range;
   range.font_size                   = font_size;
   return stbtt_PackFontRanges(spc, fontdata, font_index, &range, 1);
}

void stbtt_GetPackedQuad(stbtt_packedchar *chardata, int pw, int ph, int char_index, float *xpos, float *ypos, stbtt_aligned_quad *q, int align_to_integer)
{
   float ipw = 1.0f / pw, iph = 1.0f / ph;
   stbtt_packedchar *b = chardata + char_index;

   if (align_to_integer) {
      float x = (float) STBTT_ifloor((*xpos + b->xoff) + 0.5);
      float y = (float) STBTT_ifloor((*ypos + b->yoff) + 0.5);
      q->x0 = x;
      q->y0 = y;
      q->x1 = x + b->xoff2 - b->xoff;
      q->y1 = y + b->yoff2 - b->yoff;
   } else {
      q->x0 = *xpos + b->xoff;
      q->y0 = *ypos + b->yoff;
      q->x1 = *xpos + b->xoff2;
      q->y1 = *ypos + b->yoff2;
   }

   q->s0 = b->x0 * ipw;
   q->t0 = b->y0 * iph;
   q->s1 = b->x1 * ipw;
   q->t1 = b->y1 * iph;

   *xpos += b->xadvance;
}


//////////////////////////////////////////////////////////////////////////////
//
// font name matching -- recommended not to use this
//

// check if a utf8 string contains a prefix which is the utf16 string; if so return length of matching utf8 string
static stbtt_int32 stbtt__CompareUTF8toUTF16_bigendian_prefix(const stbtt_uint8 *s1, stbtt_int32 len1, const stbtt_uint8 *s2, stbtt_int32 len2)
{
   stbtt_int32 i=0;

   // convert utf16 to utf8 and compare the results while converting
   while (len2) {
      stbtt_uint16 ch = s2[0]*256 + s2[1];
      if (ch < 0x80) {
         if (i >= len1) return -1;
         if (s1[i++] != ch) return -1;
      } else if (ch < 0x800) {
         if (i+1 >= len1) return -1;
         if (s1[i++] != 0xc0 + (ch >> 6)) return -1;
         if (s1[i++] != 0x80 + (ch & 0x3f)) return -1;
      } else if (ch >= 0xd800 && ch < 0xdc00) {
         stbtt_uint32 c;
         stbtt_uint16 ch2 = s2[2]*256 + s2[3];
         if (i+3 >= len1) return -1;
         c = ((ch - 0xd800) << 10) + (ch2 - 0xdc00) + 0x10000;
         if (s1[i++] != 0xf0 + (c >> 18)) return -1;
         if (s1[i++] != 0x80 + ((c >> 12) & 0x3f)) return -1;
         if (s1[i++] != 0x80 + ((c >>  6) & 0x3f)) return -1;
         if (s1[i++] != 0x80 + ((c      ) & 0x3f)) return -1;
         s2 += 2; // plus another 2 below
         len2 -= 2;
      } else if (ch >= 0xdc00 && ch < 0xe000) {
         return -1;
      } else {
         if (i+2 >= len1) return -1;
         if (s1[i++] != 0xe0 + (ch >> 12)) return -1;
         if (s1[i++] != 0x80 + ((ch >> 6) & 0x3f)) return -1;
         if (s1[i++] != 0x80 + ((ch     ) & 0x3f)) return -1;
      }
      s2 += 2;
      len2 -= 2;
   }
   return i;
}

int stbtt_CompareUTF8toUTF16_bigendian(const char *s1, int len1, const char *s2, int len2)
{
   return len1 == stbtt__CompareUTF8toUTF16_bigendian_prefix((const stbtt_uint8*) s1, len1, (const stbtt_uint8*) s2, len2);
}

// returns results in whatever encoding you request... but note that 2-byte encodings
// will be BIG-ENDIAN... use stbtt_CompareUTF8toUTF16_bigendian() to compare
const char *stbtt_GetFontNameString(const stbtt_fontinfo *font, int *length, int platformID, int encodingID, int languageID, int nameID)
{
   stbtt_int32 i,count,stringOffset;
   stbtt_uint8 *fc = font->data;
   stbtt_uint32 offset = font->fontstart;
   stbtt_uint32 nm = stbtt_find_table(fc, offset, "name");
   if (!nm) return NULL;

   count = ttUSHORT(fc+nm+2);
   stringOffset = nm + ttUSHORT(fc+nm+4);
   for (i=0; i < count; ++i) {
      stbtt_uint32 loc = nm + 6 + 12 * i;
      if (platformID == ttUSHORT(fc+loc+0) && encodingID == ttUSHORT(fc+loc+2)
          && languageID == ttUSHORT(fc+loc+4) && nameID == ttUSHORT(fc+loc+6)) {
         *length = ttUSHORT(fc+loc+8);
         return (const char *) (fc+stringOffset+ttUSHORT(fc+loc+10));
      }
   }
   return NULL;
}

static int stbtt__matchpair(stbtt_uint8 *fc, stbtt_uint32 nm, stbtt_uint8 *name, stbtt_int32 nlen, stbtt_int32 target_id, stbtt_int32 next_id)
{
   stbtt_int32 i;
   stbtt_int32 count = ttUSHORT(fc+nm+2);
   stbtt_int32 stringOffset = nm + ttUSHORT(fc+nm+4);

   for (i=0; i < count; ++i) {
      stbtt_uint32 loc = nm + 6 + 12 * i;
      stbtt_int32 id = ttUSHORT(fc+loc+6);
      if (id == target_id) {
         // find the encoding
         stbtt_int32 platform = ttUSHORT(fc+loc+0), encoding = ttUSHORT(fc+loc+2), language = ttUSHORT(fc+loc+4);

         // is this a Unicode encoding?
         if (platform == 0 || (platform == 3 && encoding == 1) || (platform == 3 && encoding == 10)) {
            stbtt_int32 slen = ttUSHORT(fc+loc+8);
            stbtt_int32 off = ttUSHORT(fc+loc+10);

            // check if there's a prefix match
            stbtt_int32 matchlen = stbtt__CompareUTF8toUTF16_bigendian_prefix(name, nlen, fc+stringOffset+off,slen);
            if (matchlen >= 0) {
               // check for target_id+1 immediately following, with same encoding & language
               if (i+1 < count && ttUSHORT(fc+loc+12+6) == next_id && ttUSHORT(fc+loc+12) == platform && ttUSHORT(fc+loc+12+2) == encoding && ttUSHORT(fc+loc+12+4) == language) {
                  slen = ttUSHORT(fc+loc+12+8);
                  off = ttUSHORT(fc+loc+12+10);
                  if (slen == 0) {
                     if (matchlen == nlen)
                        return 1;
                  } else if (matchlen < nlen && name[matchlen] == ' ') {
                     ++matchlen;
                     if (stbtt_CompareUTF8toUTF16_bigendian((char*) (name+matchlen), nlen-matchlen, (char*)(fc+stringOffset+off),slen))
                        return 1;
                  }
               } else {
                  // if nothing immediately following
                  if (matchlen == nlen)
                     return 1;
               }
            }
         }

         // @TODO handle other encodings
      }
   }
   return 0;
}

static int stbtt__matches(stbtt_uint8 *fc, stbtt_uint32 offset, stbtt_uint8 *name, stbtt_int32 flags)
{
   stbtt_int32 nlen = (stbtt_int32) STBTT_strlen((char *) name);
   stbtt_uint32 nm,hd;
   if (!stbtt_isfont(fc+offset)) return 0;

   // check italics/bold/underline flags in macStyle...
   if (flags) {
      hd = stbtt_find_table(fc, offset, "head");
      if ((ttUSHORT(fc+hd+44) & 7) != (flags & 7)) return 0;
   }

   nm = stbtt_find_table(fc, offset, "name");
   if (!nm) return 0;

   if (flags) {
      // if we checked the macStyle flags, then just check the family and ignore the subfamily
      if (stbtt__matchpair(fc, nm, name, nlen, 16, -1))  return 1;
      if (stbtt__matchpair(fc, nm, name, nlen,  1, -1))  return 1;
      if (stbtt__matchpair(fc, nm, name, nlen,  3, -1))  return 1;
   } else {
      if (stbtt__matchpair(fc, nm, name, nlen, 16, 17))  return 1;
      if (stbtt__matchpair(fc, nm, name, nlen,  1,  2))  return 1;
      if (stbtt__matchpair(fc, nm, name, nlen,  3, -1))  return 1;
   }

   return 0;
}

int stbtt_FindMatchingFont(const unsigned char *font_collection, const char *name_utf8, stbtt_int32 flags)
{
   stbtt_int32 i;
   for (i=0;;++i) {
      stbtt_int32 off = stbtt_GetFontOffsetForIndex(font_collection, i);
      if (off < 0) return off;
      if (stbtt__matches((stbtt_uint8 *) font_collection, off, (stbtt_uint8*) name_utf8, flags))
         return off;
   }
}

#endif // STB_TRUETYPE_IMPLEMENTATION
"""
.}
