

add_subdirectory(sdl)

project(imgui)

add_library(imgui STATIC)
target_sources(imgui PRIVATE imgui/imgui.cpp imgui/imgui.cpp imgui/imgui_draw.cpp imgui/imgui_tables.cpp imgui/imgui_widgets.cpp imgui/imgui_internal.h)
target_sources(imgui PUBLIC imgui/imgui.h)
target_include_directories (imgui PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/imgui)
target_sources(imgui PRIVATE imgui/backends/imgui_impl_sdl2.cpp imgui/backends/imgui_impl_sdlrenderer2.cpp ImGui-Addons/FileBrowser/ImGuiFileBrowser.cpp)
target_sources(imgui PUBLIC imgui/backends/imgui_impl_sdl2.h imgui/backends/imgui_impl_sdlrenderer2.h)
target_include_directories (imgui PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/imgui ${CMAKE_CURRENT_SOURCE_DIR}/imgui/backends ${CMAKE_CURRENT_SOURCE_DIR}/ImGui-Addons/FileBrowser/ INTERFACE SDL2 imgui)
target_link_libraries(imgui SDL2)
