cmake_minimum_required(VERSION 3.21)

project(PlayerSignals VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
set(BUILD_TESTS OFF CACHE BOOL "Build CommonLibSSE tests" FORCE)
set(ENABLE_SKYRIM_SE ON CACHE BOOL "Build Skyrim SE support" FORCE)
set(ENABLE_SKYRIM_AE ON CACHE BOOL "Build Skyrim AE support" FORCE)
set(ENABLE_SKYRIM_VR ON CACHE BOOL "Build Skyrim VR support" FORCE)
set(COMMONLIB_PREBUILT OFF CACHE BOOL "Use prebuilt CommonLib" FORCE)
set(COMMONLIB_PREBUILT_DIR "" CACHE PATH "Prebuilt CommonLib directory" FORCE)

FetchContent_Declare(
    CommonLibSSE
    GIT_REPOSITORY https://github.com/MinLL/CommonLibVR.git
    GIT_TAG 550cc4fb9114649dcf526d1f3d73d710c5d7003b
    GIT_SUBMODULES extern/openvr
)
FetchContent_MakeAvailable(CommonLibSSE)
get_target_property(_playersignals_commonlib_source_dir CommonLibSSE SOURCE_DIR)
include("${_playersignals_commonlib_source_dir}/cmake/CommonLibSSE.cmake")

add_commonlibsse_plugin(
    PlayerSignals
    AUTHOR "PlayerSignals"
    SOURCES src/Plugin.cpp
)
target_compile_definitions(PlayerSignals PRIVATE WIN32_LEAN_AND_MEAN NOMINMAX)
target_precompile_headers(PlayerSignals PRIVATE src/PCH.h)
