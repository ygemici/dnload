function(check_c_flag flag var)
  include(CheckCCompilerFlag)
  set(output_message "-- C compiler flag ${flag} - ")
  check_c_compiler_flag("${flag}" ${var})
  if(${var})
    if(2 LESS ${ARGC})
      if("DEBUG" STREQUAL "${ARGV2}")
        string(STRIP "${CMAKE_C_FLAGS_DEBUG} ${flag}" NEW_FLAGS)
        set(CMAKE_C_FLAGS_DEBUG "${NEW_FLAG}" PARENT_SCOPE)
      elseif("RELEASE" STREQUAL "${ARGV2}")
        string(STRIP "${CMAKE_C_FLAGS_RELEASE} ${flag}" NEW_FLAGS)
        set(CMAKE_C_FLAGS_RELEASE "${NEW_FLAGS}" PARENT_SCOPE)
      else()
        message(SEND_ERROR "unknown build type ${ARGV1}")
      endif()
    else()
      string(STRIP "${CMAKE_C_FLAGS} ${flag}" NEW_FLAGS)
      set(CMAKE_C_FLAGS "${NEW_FLAGS}" PARENT_SCOPE)
    endif()
    message("${output_message}accepted")
  else()
    message("${output_message}not accepted")
  endif()
endfunction()

function(check_cxx_flag flag var)
  include(CheckCXXCompilerFlag)
  set(output_message "-- C++ compiler flag ${flag} - ")
  check_cxx_compiler_flag("${flag}" ${var})
  if(${var})
    if(2 LESS ${ARGC})
      if("DEBUG" STREQUAL "${ARGV2}")
        string(STRIP "${CMAKE_CXX_FLAGS_DEBUG} ${flag}" NEW_FLAGS)
        set(CMAKE_CXX_FLAGS_DEBUG "${NEW_FLAGS}" PARENT_SCOPE)
      elseif("RELEASE" STREQUAL "${ARGV2}")
        string(STRIP "${CMAKE_CXX_FLAGS_RELEASE} ${flag}" NEW_FLAGS)
        set(CMAKE_CXX_FLAGS_RELEASE "${NEW_FLAGS}" PARENT_SCOPE)
      else()
        message(SEND_ERROR "unknown build type ${ARGV2}")
      endif()
    else()
      string(STRIP "${CMAKE_CXX_FLAGS} ${flag}" NEW_FLAGS)
      set(CMAKE_CXX_FLAGS "${NEW_FLAGS}" PARENT_SCOPE)
    endif()
    message("${output_message}accepted")
  else()
    message("${output_message}not accepted")
  endif()
endfunction()

function(check_linker_flag flag)
  set(output_message "-- Linker flag ${flag} - ")
  if(1 LESS ${ARGC})
    if("DEBUG" STREQUAL "${ARGV1}")
      string(STRIP "${CMAKE_EXE_LINKER_FLAGS_DEBUG} ${flag}" NEW_FLAGS)
      set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${NEW_FLAGS}" PARENT_SCOPE)
    elseif("RELEASE" STREQUAL "${ARGV1}")
      string(STRIP "${CMAKE_EXE_LINKER_FLAGS_RELEASE} ${flag}" NEW_FLAGS)
      set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${NEW_FLAGS}" PARENT_SCOPE)
    else()
      message(SEND_ERROR "unknown build type ${ARGV1}")
    endif()
  else()
    string(STRIP "${CMAKE_EXE_LINKER_FLAGS} ${flag}" NEW_FLAGS)
    set(CMAKE_EXE_LINKER_FLAGS "${NEW_FLAGS}" PARENT_SCOPE)
  endif()
  message("${output_message}enabled")
endfunction()

function(check_include_directory dir)
  set(dir_mode "")
  if(1 LESS ${ARGC})
    if("SYSTEM" STREQUAL ${ARGV1})
      set(dir_mode "system ")
    else()
      message(SEND_ERROR "unknown include directory mode ${ARGV1}")
    endif()
  endif()
  set(output_message "-- Looking for ${dir_mode}include directory '${dir}' - ")
  if(EXISTS "${dir}/")
    message("${output_message}found")
    if(NOT "" STREQUAL ${dir_mode})
      include_directories(${ARGV1} ${dir})
    else()
      include_directories(${dir})
    endif()
  else()
    message("${output_message}not found")
  endif()
endfunction()

function(check_include_directory_msvc dir)
  set(output_message "-- Looking for include directory '${dir}' - ")
  get_filename_component(current_dir "${PROJECT_SOURCE_DIR}" ABSOLUTE)
  set(find_dir "")
  set(last_dir "")
  while(NOT "${last_dir}" STREQUAL "${current_dir}")
    set(try_dir "${current_dir}/env/${dir}/")
    if(EXISTS "${try_dir}")
      set(find_dir "${try_dir}")
      break()
    endif()
    set(last_dir "${current_dir}")
    get_filename_component(current_dir "${last_dir}/.." ABSOLUTE)
  endwhile()
  if(NOT "" STREQUAL "${find_dir}")
    include_directories(${find_dir})
    message("${output_message}${find_dir}")
  else()
    message("${output_message}not found")
  endif()
endfunction()

function(check_link_directory dir)
  set(output_message "-- Looking for link directory '${dir}' - ")
  if(EXISTS "${dir}/")
    message("${output_message}found")
    link_directories(${dir})
  else()
    message("${output_message}not found")
  endif()
endfunction()

function(check_link_directory_msvc dir)
  set(output_message "-- Looking for link directory '${dir}' - ")
  get_filename_component(current_dir "${PROJECT_SOURCE_DIR}" ABSOLUTE)
  set(find_dir "")
  set(last_dir "")
  while(NOT "${last_dir}" STREQUAL "${current_dir}")
    set(try_dir "${current_dir}/env/${dir}/")
    if(EXISTS "${try_dir}")
      set(find_dir "${try_dir}")
      break()
    endif()
    set(last_dir "${current_dir}")
    get_filename_component(current_dir "${last_dir}/.." ABSOLUTE)
  endwhile()
  if(NOT "" STREQUAL "${find_dir}")
    link_directories(${find_dir})
    message("${output_message}${find_dir}")
  else()
    message("${output_message}not found")
  endif()
endfunction()

function(check_raspberry_pi)
  include(CheckCXXSourceCompiles)
  set(output_message "-- Checking for Raspberry Pi - ")
  GET_DIRECTORY_PROPERTY(include_dirs INCLUDE_DIRECTORIES)
  set(CMAKE_REQUIRED_INCLUDES ${include_dirs})
  CHECK_CXX_SOURCE_COMPILES("#include \"bcm_host.h\"\nint main(int argc, char **argv)\n{\n  (void)argc;\n  (void)argv;\n#if !defined(CEC_VERSION)\n#error \"no CEC_VERSION\"\n#endif\n  return 0;\n}" HAVE_BCM_HOST_H)
  if(HAVE_BCM_HOST_H)
    set(RASPBERRY_PI_FOUND TRUE PARENT_SCOPE)
    message("${output_message}found")
  else()
    message("${output_message}not found")
  endif()
endfunction()

set(MINIMUM_BOOST_VERSION 1.42.0)
set(MSVC_BOOST_FOLDER "boost_1_57_0")

function(find_boost_filesystem)
  if(${MSVC})
    check_include_directory_msvc("${MSVC_BOOST_FOLDER}")
    check_link_directory_msvc("${MSVC_BOOST_FOLDER}/stage/lib")
  else()
    set(Boost_USE_STATIC_LIBS on)
    find_package(Boost ${MINIMUM_BOOST_VERSION} REQUIRED filesystem)
    if(Boost_FOUND)
      include_directories(${Boost_INCLUDE_DIRS})
    elseif(ARGV0)
      message(SEND_ERROR "Boost Filesystem required but not found")
    endif()
    set(BOOST_FILESYSTEM_LIBRARY ${Boost_LIBRARIES} PARENT_SCOPE)
  endif()
endfunction()

function(find_boost_program_options)
  if(${MSVC})
    check_include_directory_msvc("${MSVC_BOOST_FOLDER}")
    check_link_directory_msvc("${MSVC_BOOST_FOLDER}/stage/lib")
  else()
    set(Boost_USE_STATIC_LIBS on)
    find_package(Boost ${MINIMUM_BOOST_VERSION} REQUIRED program_options)
    if(Boost_FOUND)
      include_directories(${Boost_INCLUDE_DIRS})
    elseif(ARGV0)
      message(SEND_ERROR "Boost Program Options required but not found")
    endif()
    set(BOOST_PROGRAM_OPTIONS_LIBRARY ${Boost_LIBRARIES} PARENT_SCOPE)
  endif()
endfunction()

function(find_boost_signals)
  if(${MSVC})
    check_include_directory_msvc("${MSVC_BOOST_FOLDER}")
    check_link_directory_msvc("${MSVC_BOOST_FOLDER}/stage/lib")
  else()
    set(Boost_USE_STATIC_LIBS on)
    find_package(Boost ${MINIMUM_BOOST_VERSION} REQUIRED signals)
    if(Boost_FOUND)
      include_directories(${Boost_INCLUDE_DIRS})
    elseif(ARGV0)
      message(SEND_ERROR "Boost Signals required but not found")
    endif()
    set(BOOST_SIGNALS_LIBRARY ${Boost_LIBRARIES} PARENT_SCOPE)
  endif()
endfunction()

function(find_boost_system)
  if(${MSVC})
    check_include_directory_msvc("${MSVC_BOOST_FOLDER}")
    check_link_directory_msvc("${MSVC_BOOST_FOLDER}/stage/lib")
  else()
    set(Boost_USE_STATIC_LIBS on)
    find_package(Boost ${MINIMUM_BOOST_VERSION} REQUIRED system)
    if(Boost_FOUND)
      include_directories(${Boost_INCLUDE_DIRS})
    elseif(ARGV0)
      message(SEND_ERROR "Boost System required but not found")
    endif()
    set(BOOST_SYSTEM_LIBRARY ${Boost_LIBRARIES} PARENT_SCOPE)
  endif()
endfunction()

function(find_boost_thread)
  if(${MSVC})
    check_include_directory_msvc("${MSVC_BOOST_FOLDER}")
    check_link_directory_msvc("${MSVC_BOOST_FOLDER}/stage/lib")
  else()
    set(Boost_USE_STATIC_LIBS on)
    find_package(Boost ${MINIMUM_BOOST_VERSION} REQUIRED thread)
    if(Boost_FOUND)
      include_directories(${Boost_INCLUDE_DIRS})
    elseif(ARGV0)
      message(SEND_ERROR "Boost Thread required but not found")
    endif()
    if(CMAKE_SYSTEM_NAME MATCHES "FreeBSD")
      set(BOOST_THREAD_LIBRARY ${Boost_LIBRARIES} thr PARENT_SCOPE)
    else()
      set(BOOST_THREAD_LIBRARY ${Boost_LIBRARIES} PARENT_SCOPE)
    endif()
  endif()
endfunction()

function(find_boost_unit_test_framework)
  if(${MSVC})
    check_include_directory_msvc("${MSVC_BOOST_FOLDER}")
    check_link_directory_msvc("${MSVC_BOOST_FOLDER}/stage/lib")
  else()
    set(Boost_USE_STATIC_LIBS on)
    find_package(Boost ${MINIMUM_BOOST_VERSION} REQUIRED unit_test_framework)
    if(Boost_FOUND)
      include_directories(${Boost_INCLUDE_DIRS})
    elseif(ARGV0)
      message(SEND_ERROR "Boost Test required but not found")
    endif()
    set(BOOST_UNIT_TEST_FRAMEWORK_LIBRARY ${Boost_LIBRARIES} PARENT_SCOPE)
  endif()
endfunction()

function(find_freetype)
  if(${MSVC})
    check_include_directory_msvc("freetype-2.5.5/include")
    check_link_directory_msvc("freetype-2.5.5/objs/vc2010/Win32")
    set(FREETYPE_LIBRARY_DEBUG "freetype255MTd.lib" PARENT_SCOPE)
    set(FREETYPE_LIBRARY "freetype255MT.lib" PARENT_SCOPE)
  else()
    set(lib_mode SHARED)
    if(1 LESS ${ARGC})
      set(lib_mode "${ARGV1}")
    endif()
    include(FindFreetype)
    if(FREETYPE_FOUND)
      include_directories(${FREETYPE_INCLUDE_DIRS})
    elseif(ARGV0)
      message(SEND_ERROR "FreeType required but not found")
    endif()
    set(FREETYPE_LIBRARY ${FREETYPE_LIBRARIES} PARENT_SCOPE)
  endif()
endfunction()

function(find_glew)
  if(${MSVC})
    check_include_directory_msvc("glew-1.12.0/include")
    check_link_directory_msvc("glew-1.12.0/lib/Debug/Win32")
    check_link_directory_msvc("glew-1.12.0/lib/Release/Win32")
    if(1 LESS ${ARGC})
      if("STATIC" STREQUAL "${ARGV1}")
        add_definitions("/DGLEW_STATIC")
      endif()
    endif()
    set(GLEW_LIBRARY_DEBUG "glew32sd.lib" PARENT_SCOPE)
    set(GLEW_LIBRARY "glew32s.lib" PARENT_SCOPE)
  else()
    set(lib_mode SHARED)
    if(1 LESS ${ARGC})
      if("STATIC" STREQUAL "${ARGV1}")
        add_definitions("-DGLEW_STATIC")
      endif()
      set(lib_mode "${ARGV1}")
    endif()
    include(FindPkgConfig)
    pkg_search_module(GLEW glew)
    if(GLEW_FOUND)
      if(GLEW_INCLUDE_DIRS)
        include_directories(${GLEW_INCLUDE_DIRS})
      endif()
      if(GLEW_LIBRARY_DIRS)
        link_directories(${GLEW_LIBRARY_DIRS})
      endif()
      if(GLEW_CFLAGS)
        add_definitions(${GLEW_CFLAGS})
      endif()
      if(GLEW_CFLAGS_OTHER)
        add_definitions(${GLEW_CFLAGS_OTHER})
      endif()
      message("-- Found GLEW: ${GLEW_VERSION}")
    elseif(ARGV1)
      message(SEND_ERROR "GLEW required but not found")
    endif()
    set(GLEW_LIBRARY ${GLEW_LIBRARIES} PARENT_SCOPE)
  endif()
endfunction()

function(find_glu)
  set(lib_mode SHARED)
  if(1 LESS ${ARGC})
    set(lib_mode "${ARGV1}")
  endif()
  include(FindOpenGL)
  if(OPENGL_GLU_FOUND)
    message("-- Found GLU: ${OPENGL_glu_LIBRARY}")
  elseif(ARGV0)
    message(SEND_ERROR "GLU required but not found")
  endif()
endfunction()

function(find_jpeg)
  if(${MSVC})
    check_include_directory_msvc("jpeg-9a")
    check_link_directory_msvc("jpeg-9a/Release")
    set(JPEG_LIBRARY_DEBUG "jpeg.lib" PARENT_SCOPE)
    set(JPEG_LIBRARY "jpeg.lib" PARENT_SCOPE)
  else()
    set(lib_mode SHARED)
    if(1 LESS ${ARGC})
      set(lib_mode "${ARGV1}")
    endif()
    include(FindJPEG)
    if(JPEG_FOUND)
      include_directories(${JPEG_INCLUDE_DIR})
      set(JPEG_LIBRARY ${JPEG_LIBRARIES} PARENT_SCOPE)
    elseif(ARGV0)
      message(SEND_ERROR "libpng required but not found")
    endif()
  endif()
endfunction()

function(find_ogg)
  if(${MSVC})
    check_include_directory_msvc("libogg-1.3.2/include")
    check_link_directory_msvc("libogg-1.3.2/win32/VS2010/Win32")
    set(OGG_LIBRARY_DEBUG "Debug/libogg_static" PARENT_SCOPE)
    set(OGG_LIBRARY "Release/libogg_static" PARENT_SCOPE)
  else()
    set(lib_mode SHARED)
    if(1 LESS ${ARGC})
      set(lib_mode "${ARGV1}")
    endif()
    include(FindPkgConfig)
    pkg_search_module(OGG ogg)
    if(OGG_FOUND)
      if(OGG_INCLUDE_DIRS)
        include_directories(${OGG_INCLUDE_DIRS})
      endif()
      if(OGG_LIBRARY_DIRS)
        link_directories(${OGG_LIBRARY_DIRS})
      endif()
      if(OGG_CFLAGS)
        add_definitions(${OGG_CFLAGS})
      endif()
      if(OGG_CFLAGS_OTHER)
        add_definitions(${OGG_CFLAGS_OTHER})
      endif()
      message("-- Found Ogg: ${OGG_VERSION}")
    elseif(ARGV0)
      message(SEND_ERROR "Ogg required but not found")
    endif()
    set(OGG_LIBRARY ${OGG_LIBRARIES} PARENT_SCOPE)
  endif()
endfunction()

function(find_openal)
  if(${MSVC})
    check_include_directory_msvc("openal-soft-1.16.0/include")
    check_link_directory_msvc("openal-soft-1.16.0")
    set(OPENAL_LIBRARY_DEBUG "Debug/OpenAL32" PARENT_SCOPE)
    set(OPENAL_LIBRARY "Release/OpenAL32" PARENT_SCOPE)
  else()
    set(lib_mode SHARED)
    if(1 LESS ${ARGC})
      set(lib_mode "${ARGV1}")
    endif()
    include(FindOpenAL)
    if(OPENAL_FOUND)
      include_directories(${OPENAL_INCLUDE_DIR})
    elseif(ARGV0)
      message(SEND_ERROR "OpenAL required but not found")
    endif()
    set(OPENAL_LIBRARY ${OPENAL_LIBRARY} PARENT_SCOPE)
  endif()
endfunction()

function(find_opengl)
  set(lib_mode SHARED)
  if(ARGV1)
    set(lib_mode "${ARGV1}")
  endif()
  include(FindOpenGL)
  if(!OPENGL_FOUND)
    message(SEND_ERROR "OpenGL required but not found")
  endif()
endfunction()

function(find_png)
  if(${MSVC})
    check_include_directory_msvc("lpng1616")
    check_include_directory_msvc("zlib-1.2.8")
    check_link_directory_msvc("lpng1616/projects/vstudio")
    set(PNG_LIBRARY_DEBUG "Debug Library/libpng16" "Debug Library/zlib" PARENT_SCOPE)
    set(PNG_LIBRARY "Release Library/libpng16" "Release Library/zlib" PARENT_SCOPE)
  else()
    set(lib_mode SHARED)
    if(1 LESS ${ARGC})
      set(lib_mode "${ARGV1}")
    endif()
    include(FindPNG)
    if(PNG_FOUND)
      include_directories(${PNG_INCLUDE_DIRS})
      add_definitions(${PNG_DEFINITIONS})
      set(PNG_LIBRARY ${PNG_LIBRARIES} PARENT_SCOPE)
    elseif(ARGV0)
      message(SEND_ERROR "libpng required but not found")
    endif()
  endif()
endfunction()

function(find_sdl)
  if(${MSVC})
    check_include_directory_msvc("SDL-1.2.15/include")
    check_link_directory_msvc("SDL-1.2.15/lib/x86")
    set(SDL_LIBRARY_DEBUG "SDL" "SDLmain" PARENT_SCOPE)
    set(SDL_LIBRARY "SDL" "SDLmain" PARENT_SCOPE)
  else()
    set(lib_mode SHARED)
    if(1 LESS ${ARGC})
      set(lib_mode "${ARGV1}")
    endif()
    include(FindSDL)
    if(SDL_FOUND)
      include_directories(${SDL_INCLUDE_DIR})
    elseif(ARGV0)
      message(SEND_ERROR "SDL required but not found")
    endif()
    set(SDL_LIBRARY "${SDL_LIBRARY}" PARENT_SCOPE)
  endif()
endfunction()

function(find_vorbis)
  if(${MSVC})
    check_include_directory_msvc("libvorbis-1.3.5/include")
    check_link_directory_msvc("libvorbis-1.3.5/win32/VS2010/Win32")
    set(VORBIS_LIBRARY_DEBUG "Debug/libvorbis_static" PARENT_SCOPE)
    set(VORBIS_LIBRARY "Release/libvorbis_static" PARENT_SCOPE)
  else()
    set(lib_mode SHARED)
    if(1 LESS ${ARGC})
      set(lib_mode "${ARGV1}")
    endif()
    include(FindPkgConfig)
    pkg_search_module(VORBIS vorbis)
    if(VORBIS_FOUND)
      if(VORBIS_INCLUDE_DIRS)
        include_directories(${VORBIS_INCLUDE_DIRS})
      endif()
      if(VORBIS_LIBRARY_DIRS)
        link_directories(${VORBIS_LIBRARY_DIRS})
      endif()
      if(VORBIS_CFLAGS)
        add_definitions(${VORBIS_CFLAGS})
      endif()
      if(VORBIS_CFLAGS_OTHER)
        add_definitions(${VORBIS_CFLAGS_OTHER})
      endif()
      message("-- Found Vorbis: ${VORBIS_VERSION}")
    elseif(ARGV0)
      message(SEND_ERROR "Vorbis required but not found")
    endif()
    set(VORBIS_LIBRARY ${VORBIS_LIBRARIES} PARENT_SCOPE)
  endif()
endfunction()

function(output_flags)
  if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
    set(CMAKE_BUILD_TYPE "Release" PARENT_SCOPE)
  endif()
  if(ARGV0)
    if(${MSVC})
      string(STRIP "${CMAKE_C_FLAGS_DEBUG} /D${ARGV0}" CMAKE_C_FLAGS_DEBUG_NEW)
      string(STRIP "${CMAKE_CXX_FLAGS_DEBUG} /D${ARGV0}" CMAKE_CXX_FLAGS_DEBUG_NEW)
    else()
      string(STRIP "${CMAKE_C_FLAGS_DEBUG} -D${ARGV0}" CMAKE_C_FLAGS_DEBUG_NEW)
      string(STRIP "${CMAKE_CXX_FLAGS_DEBUG} -D${ARGV0}" CMAKE_CXX_FLAGS_DEBUG_NEW)
    endif()
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG_NEW}")
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG_NEW}" PARENT_SCOPE)
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG_NEW}")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG_NEW}" PARENT_SCOPE)
  endif()
  if(1 LESS ${ARGC})
    set(CMAKE_VERBOSE_MAKEFILE ${ARGV1})
    set(CMAKE_VERBOSE_MAKEFILE ${ARGV1} PARENT_SCOPE)
    message("-- Using verbose makefiles: ${CMAKE_VERBOSE_MAKEFILE}")
  endif()
  GET_DIRECTORY_PROPERTY(include_dirs INCLUDE_DIRECTORIES)
  GET_DIRECTORY_PROPERTY(link_dirs LINK_DIRECTORIES)
  message("-- Using configuration: ${CMAKE_BUILD_TYPE} from ${CMAKE_CONFIGURATION_TYPES}")
  message("-- Using C compiler: ${CMAKE_C_COMPILER}")
  message("-- Using C++ compiler: ${CMAKE_CXX_COMPILER}")
  message("-- Using C compiler flags: ${CMAKE_C_FLAGS}")
  message("-- Using C++ compiler flags: ${CMAKE_CXX_FLAGS}")
  message("-- Using DEBUG C compiler flags: ${CMAKE_C_FLAGS_DEBUG}")
  message("-- Using DEBUG C++ compiler flags: ${CMAKE_CXX_FLAGS_DEBUG}")
  message("-- Using RELEASE C compiler flags: ${CMAKE_C_FLAGS_RELEASE}")
  message("-- Using RELEASE C++ compiler flags: ${CMAKE_CXX_FLAGS_RELEASE}")
  message("-- Using linker flags: ${CMAKE_EXE_LINKER_FLAGS}")
  message("-- Using DEBUG linker flags: ${CMAKE_EXE_LINKER_FLAGS_DEBUG}")
  message("-- Using RELEASE linker flags: ${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
  message("-- Using include directories: ${include_dirs}")
  message("-- Using link directories: ${link_dirs}")
endfunction()

if(${MSVC})
  add_definitions("/D_CRT_SECURE_NO_WARNINGS")
  add_definitions("/D_SCL_SECURE_NO_WARNINGS")
  add_definitions("/DWIN32")

  #check_c_flag("/W3" HAS_C_FLAG_W3)
  #check_cxx_flag("/W3" HAS_CXX_FLAG_W3)

  #check_cxx_flag("/EHsc" HAS_CXX_FLAG_EHSC)

  #check_c_flag("/Od" HAS_C_FLAG_OD "DEBUG")
  #check_cxx_flag("/Od" HAS_CXX_FLAG_OD "DEBUG")

  #check_c_flag("/Ox" HAS_C_FLAG_OX "RELEASE")
  #check_cxx_flag("/Ox" HAS_CXX_FLAG_OX "RELEASE")
  check_c_flag("/Oi" HAS_C_FLAG_OI "RELEASE")
  check_cxx_flag("/Oi" HAS_CXX_FLAG_OI "RELEASE")
  check_c_flag("/Ot" HAS_C_FLAG_OT "RELEASE")
  check_cxx_flag("/Ot" HAS_CXX_FLAG_OT "RELEASE")
  check_c_flag("/Oy" HAS_C_FLAG_OY "RELEASE")
  check_cxx_flag("/Oy" HAS_CXX_FLAG_OY "RELEASE")
  check_c_flag("/GL" HAS_C_FLAG_GL "RELEASE")
  check_cxx_flag("/GL" HAS_CXX_FLAG_GL "RELEASE")

  #check_linker_flag("/INCREMENTAL:NO" "DEBUG")

  check_linker_flag("/LTCG" "RELEASE")
else()
  check_include_directory("/opt/include")
  check_include_directory("/opt/local/include")
  check_include_directory("/opt/vc/include" SYSTEM)
  check_include_directory("/opt/vc/include/interface/vcos/pthreads" SYSTEM)
  check_include_directory("/opt/vc/include/interface/vmcs_host/linux" SYSTEM)
  check_include_directory("/sw/include")
  check_include_directory("/usr/local/include" SYSTEM)
  check_include_directory("/usr/X11R6/include")
  check_link_directory("/opt/lib")
  check_link_directory("/opt/local/lib")
  check_link_directory("/opt/vc/lib")
  check_link_directory("/sw/lib")
  check_link_directory("/usr/lib/arm-linux-gnueabihf")
  check_link_directory("/usr/local/lib")
  check_link_directory("/usr/X11R6/lib")

  check_c_flag("-Werror=unused-command-line-argument" HAS_C_FLAG_WERROR_UNUSED_COMMAND_LINE_ARGUMENT)
  check_cxx_flag("-Werror=unused-command-line-argument" HAS_CXX_FLAG_WERROR_UNUSED_COMMAND_LINE_ARGUMENT)
  check_c_flag("-Werror=unknown-warning-option" HAS_C_FLAG_WERROR_UNKNOWN_WARNING_OPTION)
  check_cxx_flag("-Werror=unknown-warning-option" HAS_CXX_FLAG_WERROR_UNKNOWN_WARNING_OPTION)

  check_c_flag("-std=c99" HAS_C_FLAG_STD_C99)
  check_cxx_flag("-std=c++11" HAS_CXX_FLAG_STD_CXX11)

  check_c_flag("-Werror=return-type" HAS_C_FLAG_WERROR_RETURN_TYPE)
  check_cxx_flag("-Werror=return-type" HAS_CXX_FLAG_WERROR_RETURN_TYPE)

  check_c_flag("-Werror-implicit-function-declaration" HAS_C_FLAG_WERROR_IMPLICIT_FUNCTION_DECLARATION)

  check_cxx_flag("-Werror=non-virtual-dtor" HAS_CXX_FLAG_WERROR_NON_VIRTUAL_DTOR)

  check_c_flag("-Wall" HAS_C_FLAG_WALL)
  check_cxx_flag("-Wall" HAS_CXX_FLAG_WALL)
  check_c_flag("-Wcast-align" HAS_C_FLAG_WCAST_ALIGN)
  check_cxx_flag("-Wcast-align" HAS_CXX_FLAG_WCAST_ALIGN)
  check_c_flag("-Wconversion" HAS_C_FLAG_WCONVERSION)
  check_cxx_flag("-Wconversion" HAS_CXX_FLAG_WCONVERSION)
  check_c_flag("-Wextra" HAS_C_FLAG_WEXTRA)
  check_cxx_flag("-Wextra" HAS_CXX_FLAG_WEXTRA)
  check_c_flag("-Winit-self" HAS_C_FLAG_WINIT_SELF)
  check_cxx_flag("-Winit-self" HAS_CXX_FLAG_WINIT_SELF)
  check_c_flag("-Winvalid-pch" HAS_C_FLAG_WINVALID_PCH)
  check_cxx_flag("-Winvalid-pch" HAS_CXX_FLAG_WINVALID_PCH)
  check_c_flag("-Wlogical-op" HAS_C_FLAG_WLOGICAL_OP)
  check_cxx_flag("-Wlogical-op" HAS_CXX_FLAG_WLOGICAL_OP)
  check_c_flag("-Wmissing-format-attribute" HAS_C_FLAG_WMISSING_FORMAT_ATTRIBUTE)
  check_cxx_flag("-Wmissing-format-attribute" HAS_CXX_FLAG_WMISSING_FORMAT_ATTRIBUTE)
  check_c_flag("-Wmissing-include-dirs" HAS_C_FLAG_WMISSING_INCLUDE_DIRS)
  check_cxx_flag("-Wmissing-include-dirs" HAS_CXX_FLAG_WMISSING_INCLUDE_DIRS)
  check_c_flag("-Wpacked" HAS_C_FLAG_WPACKED)
  check_cxx_flag("-Wpacked" HAS_CXX_FLAG_WPACKED)
  check_c_flag("-Wredundant-decls" HAS_C_FLAG_WREDUNDANT_DECLS)
  check_cxx_flag("-Wredundant-decls" HAS_CXX_FLAG_WREDUNDANT_DECLS)
  check_c_flag("-Wshadow" HAS_C_FLAG_WSHADOW)
  check_cxx_flag("-Wshadow" HAS_CXX_FLAG_WSHADOW)
  check_c_flag("-Wswitch-default" HAS_C_FLAG_WSWITCH_DEFAULT)
  check_cxx_flag("-Wswitch-default" HAS_CXX_FLAG_WSWITCH_DEFAULT)
  #check_c_flag("-Wswitch-enum" HAS_C_FLAG_SWITCH_ENUM)
  #check_cxx_flag("-Wswitch-enum" HAS_CXX_FLAG_SWITCH_ENUM)
  check_c_flag("-Wwrite-strings" HAS_C_FLAG_WWRITE_STRINGS)
  check_cxx_flag("-Wwrite-strings" HAS_CXX_FLAG_WWRITE_STRINGS)
  check_c_flag("-Wundef" HAS_C_FLAG_WUNDEF)
  check_cxx_flag("-Wundef" HAS_CXX_FLAG_WUNDEF)

  check_c_flag("-Wbad-function-cast" HAS_C_FLAG_WBAD_FUNCTION_CAST)
  check_c_flag("-Wmissing-declarations" HAS_C_FLAG_WMISSING_DECLARATIONS)
  check_c_flag("-Wmissing-prototypes" HAS_C_FLAG_WMISSING_PROTOTYPES)
  check_c_flag("-Wnested-externs" HAS_C_FLAG_WNESTED_EXTERNS)
  check_c_flag("-Wold-style-definition" HAS_C_FLAG_WOLD_STYLE_DEFINITION)
  check_c_flag("-Wstrict-prototypes" HAS_C_FLAG_WSTRICT_PROTOTYPES)

  check_cxx_flag("-Wctor-dtor-privacy" HAS_CXX_FLAG_WCTOR_DTOR_PRIVACY)
  check_cxx_flag("-Wold-style-cast" HAS_CXX_FLAG_WOLD_STYLE_CAST)
  check_cxx_flag("-Woverloaded-virtual" HAS_CXX_FLAG_WOVERLOADED_VIRTUAL)

  check_c_flag("-fdiagnostics-color=auto" HAS_C_FLAG_FDIAGNOSTICS_COLOR)
  check_cxx_flag("-fdiagnostics-color=auto" HAS_CXX_FLAG_FDIAGNOSTICS_COLOR)
  check_c_flag("-fdiagnostics-show-option" HAS_C_FLAG_FDIAGNOSTICS_SHOW_OPTION)
  check_cxx_flag("-fdiagnostics-show-option" HAS_CXX_FLAG_FDIAGNOSTICS_SHOW_OPTION)
  check_c_flag("-ftracer" HAS_C_FLAG_FTRACER)
  check_cxx_flag("-ftracer" HAS_CXX_FLAG_FTRACER)
  check_c_flag("-fweb" HAS_C_FLAG_FWEB)
  check_cxx_flag("-fweb" HAS_CXX_FLAG_FWEB)
  check_c_flag("-pipe" HAS_C_FLAG_PIPE)
  check_cxx_flag("-pipe" HAS_CXX_FLAG_PIPE)

  #check_c_flag("-g" HAS_C_FLAG_G "DEBUG")
  #check_cxx_flag("-g" HAS_CXX_FLAG_G "DEBUG")
  check_c_flag("-O0" HAS_C_FLAG_O0 "DEBUG")
  check_cxx_flag("-O0" HAS_CXX_FLAG_O0 "DEBUG")
  check_c_flag("-funit-at-a-time" HAS_C_FLAG_FUNIT_AT_A_TIME "DEBUG")
  check_cxx_flag("-funit-at-a-time" HAS_CXX_FLAG_FUNIT_AT_A_TIME "DEBUG")

  #check_c_flag("-O3" HAS_C_FLAG_O3 "RELEASE")
  #check_cxx_flag("-O3" HAS_CXX_FLAG_O3 "RELEASE")
  check_c_flag("-ffast-math" HAS_C_FLAG_FFAST_MATH "RELEASE")
  check_cxx_flag("-ffast-math" HAS_CXX_FLAG_FFAST_MATH "RELEASE")
  check_c_flag("-fgcse-las" HAS_C_FLAG_FGCSE_LAS "RELEASE")
  check_cxx_flag("-fgcse-las" HAS_CXX_FLAG_FGCSE_LAS "RELEASE")
  check_c_flag("-fgcse-sm" HAS_C_FLAG_FGCSE_SM "RELEASE")
  check_cxx_flag("-fgcse-sm" HAS_CXX_FLAG_FGCSE_SM "RELEASE")
  check_c_flag("-fomit-frame-pointer" HAS_C_FLAG_FOMIT_FRAME_POINTER "RELEASE")
  check_cxx_flag("-fomit-frame-pointer" HAS_CXX_FLAG_FOMIT_FRAME_POINTER "RELEASE")
  check_c_flag("-fsee" HAS_C_FLAG_FSEE "RELEASE")
  check_cxx_flag("-fsee" HAS_CXX_FLAG_FSEE "RELEASE")
  check_c_flag("-fsingle-precision-constant" HAS_C_FLAG_FSINGLE_PRECISION_CONSTANT "RELEASE")
  check_cxx_flag("-fsingle-precision-constant" HAS_CXX_FLAG_FSINGLE_PRECISION_CONSTANT "RELEASE")

  check_linker_flag("-s" "RELEASE")
endif()
