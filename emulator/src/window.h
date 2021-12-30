#pragma once

#include "SDL.h"

#if defined(__PSP__)
#define DEFAULT_WINDOW_WIDTH  480
#define DEFAULT_WINDOW_HEIGHT 272
#elif defined(__VITA__)
#define DEFAULT_WINDOW_WIDTH  960
#define DEFAULT_WINDOW_HEIGHT 544
#else
#define DEFAULT_WINDOW_WIDTH  1280
#define DEFAULT_WINDOW_HEIGHT 720
#endif

#define VERBOSE_VIDEO   0x00000001
#define VERBOSE_MODES   0x00000002
#define VERBOSE_RENDER  0x00000004
#define VERBOSE_EVENT   0x00000008
#define VERBOSE_AUDIO   0x00000010

typedef struct
{
  /* SDL init flags */
  char** argv;
  uint32_t flags;
  uint32_t verbose;

  /* Video info */
  const char* videodriver;
  int display;
  const char* window_title;
  const char* window_icon;
  uint32_t window_flags;
  SDL_bool flash_on_focus_loss;
  int window_x;
  int window_y;
  int window_w;
  int window_h;
  int window_minW;
  int window_minH;
  int window_maxW;
  int window_maxH;
  int logical_w;
  int logical_h;
  float scale;
  int depth;
  int refresh_rate;
  int num_windows;
  SDL_Window** windows;

  /* Renderer info */
  const char* renderdriver;
  uint32_t render_flags;
  SDL_bool skip_renderer;
  SDL_Renderer** renderers;
  SDL_Texture** targets;

  /* Audio info */
  const char* audiodriver;
  SDL_AudioSpec audiospec;

  /* GL settings */
  int gl_red_size;
  int gl_green_size;
  int gl_blue_size;
  int gl_alpha_size;
  int gl_buffer_size;
  int gl_depth_size;
  int gl_stencil_size;
  int gl_double_buffer;
  int gl_accum_red_size;
  int gl_accum_green_size;
  int gl_accum_blue_size;
  int gl_accum_alpha_size;
  int gl_stereo;
  int gl_multisamplebuffers;
  int gl_multisamplesamples;
  int gl_retained_backing;
  int gl_accelerated;
  int gl_major_version;
  int gl_minor_version;
  int gl_debug;
  int gl_profile_mask;
} SDLCommonState;

#include "begin_code.h"
/* Set up for C function definitions, even when using C++ */
#ifdef __cplusplus
extern "C" {
#endif

  /* Function prototypes */

  /**
   * \brief Parse command line parameters and create common state.
   *
   * \param argv Array of command line parameters
   * \param flags Flags indicating which subsystem to initialize (i.e. SDL_INIT_VIDEO | SDL_INIT_AUDIO)
   *
   * \returns a newly allocated common state object.
   */
  SDLCommonState* SDLCommonCreateState(char** argv, uint32_t flags);

  /**
   * \brief Process one common argument.
   *
   * \param state The common state describing the test window to create.
   * \param index The index of the argument to process in argv[].
   *
   * \returns the number of arguments processed (i.e. 1 for --fullscreen, 2 for --video [videodriver], or -1 on error.
   */
  int SDLCommonArg(SDLCommonState* state, int index);


  /**
   * \brief Logs command line usage info.
   *
   * This logs the appropriate command line options for the subsystems in use
   *  plus other common options, and then any application-specific options.
   *  This uses the SDL_Log() function and splits up output to be friendly to
   *  80-character-wide terminals.
   *
   * \param state The common state describing the test window for the app.
   * \param argv0 argv[0], as passed to main/SDL_main.
   * \param options an array of strings for application specific options. The last element of the array should be NULL.
   */
  void SDLCommonLogUsage(SDLCommonState* state, const char* argv0, const char** options);

  /**
   * \brief Returns common usage information
   *
   * You should (probably) be using SDLCommonLogUsage() instead, but this
   *  function remains for binary compatibility. Strings returned from this
   *  function are valid until SDLCommonQuit() is called, in which case
   *  those strings' memory is freed and can no longer be used.
   *
   * \param state The common state describing the test window to create.
   * \returns a string with usage information
   */
  const char* SDLCommonUsage(SDLCommonState* state);

  /**
   * \brief Open test window.
   *
   * \param state The common state describing the test window to create.
   *
   * \returns SDL_TRUE if initialization succeeded, false otherwise
   */
  SDL_bool SDLCommonInit(SDLCommonState* state);

  /**
   * \brief Easy argument handling when test app doesn't need any custom args.
   *
   * \param state The common state describing the test window to create.
   * \param argc argc, as supplied to SDL_main
   * \param argv argv, as supplied to SDL_main
   *
   * \returns SDL_FALSE if app should quit, true otherwise.
   */
  SDL_bool SDLCommonDefaultArgs(SDLCommonState* state, const int argc, char** argv);

  /**
   * \brief Common event handler for test windows.
   *
   * \param state The common state used to create test window.
   * \param event The event to handle.
   * \param done Flag indicating we are done.
   *
   */
  void SDLCommonEvent(SDLCommonState* state, SDL_Event* event, int* done);

  /**
   * \brief Close test window.
   *
   * \param state The common state used to create test window.
   *
   */
  void SDLCommonQuit(SDLCommonState* state);

  /**
   * \brief Draws various window information (position, size, etc.) to the renderer.
   *
   * \param renderer The renderer to draw to.
   * \param window The window whose information should be displayed.
   *
   */
  void SDLCommonDrawWindowInfo(SDL_Renderer* renderer, SDL_Window* window);

  /* Ends C function definitions when using C++ */
#ifdef __cplusplus
}
#endif
#include "close_code.h"

/* vi: set ts=4 sw=4 expandtab: */
