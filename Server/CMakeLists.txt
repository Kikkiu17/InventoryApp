cmake_minimum_required(VERSION 3.16)
project(inventory_server CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

set(CMAKE_CXX_FLAGS_RELEASE "-O2")

add_executable(inventory_server main.cpp)

target_include_directories(inventory_server PRIVATE ${CMAKE_SOURCE_DIR}/include)

find_package(Threads REQUIRED)
target_link_libraries(inventory_server PRIVATE Threads::Threads stdc++fs)

# Include Asio standalone if not found on system
find_path(ASIO_INCLUDE_DIR asio.hpp)
if(NOT ASIO_INCLUDE_DIR)
    message(STATUS "System Asio headers not found. Downloading standalone Asio...")
    include(FetchContent)
    FetchContent_Declare(
        asio
        URL https://github.com/chriskohlhoff/asio/archive/refs/tags/asio-1-30-2.tar.gz
    )
    FetchContent_MakeAvailable(asio)
    target_include_directories(inventory_server PRIVATE ${asio_SOURCE_DIR}/asio/include)
else()
    target_include_directories(inventory_server PRIVATE ${ASIO_INCLUDE_DIR})
endif()

find_package(OpenSSL REQUIRED)
if(OpenSSL_FOUND)
    target_link_libraries(inventory_server PRIVATE OpenSSL::SSL OpenSSL::Crypto)
    target_compile_definitions(inventory_server PRIVATE CROW_ENABLE_SSL)
endif()

find_package(ZLIB QUIET)
if(ZLIB_FOUND)
    target_link_libraries(inventory_server PRIVATE ZLIB::ZLIB)
endif()
