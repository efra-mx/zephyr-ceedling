cmake_minimum_required(VERSION 3.22.1)

get_property(CEEDLING_MODULE_BASE GLOBAL PROPERTY CEEDLING_MODULE_BASE)

set_property(GLOBAL PROPERTY UNITY_DIR ${CEEDLING_MODULE_BASE}/../ceedling/vendor/unity)
get_property(UNITY_DIR GLOBAL PROPERTY UNITY_DIR)
set_property(GLOBAL PROPERTY UNITY_CFG_TEMPLATE
  "${CEEDLING_MODULE_BASE}/unity/unity_cfg.template.yaml")
set_property(GLOBAL PROPERTY UNITY_CONFIG_HEADER_DIR ${CMAKE_CURRENT_LIST_DIR})

include(${CEEDLING_MODULE_BASE}/cmake/unity.cmake)

# add Unity Test Runner sources as a part of this library
zephyr_library()

# add files directly to the target
zephyr_library_sources(
  ${UNITY_DIR}/src/unity.c
  generic_teardown.c
)

zephyr_include_directories(
  ${UNITY_DIR}/src
  ${CMAKE_CURRENT_SOURCE_DIR}
)

# include custom `unity_config.h`
zephyr_compile_definitions(UNITY_INCLUDE_CONFIG_H)

configure_unity_conf_file("" unused)

find_program(
  RUBY_EXECUTABLE
  ruby
)
if(${RUBY_EXECUTABLE} STREQUAL RUBY_EXECUTABLE-NOTFOUND)
  message(FATAL_ERROR "Unable to find ruby")
endif()
