cmake_minimum_required(VERSION 3.16)
project(inventory_server CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

set(CMAKE_CXX_FLAGS_RELEASE "-O2")

add_executable(inventory_server main.cpp)

target_include_directories(inventory_server PRIVATE ${CMAKE_SOURCE_DIR}/include)

find_package(Threads REQUIRED)
target_link_libraries(inventory_server PRIVATE Threads::Threads stdc++fs)

find_package(OpenSSL QUIET)
if(OpenSSL_FOUND)
    target_link_libraries(inventory_server PRIVATE OpenSSL::SSL OpenSSL::Crypto)
endif()

find_package(ZLIB QUIET)
if(ZLIB_FOUND)
    target_link_libraries(inventory_server PRIVATE ZLIB::ZLIB)
endif()
