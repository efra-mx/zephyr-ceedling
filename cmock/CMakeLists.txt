cmake_minimum_required(VERSION 3.22.1)

get_property(CEEDLING_MODULE_BASE GLOBAL PROPERTY CEEDLING_MODULE_BASE)

set_property(GLOBAL PROPERTY CMOCK_DIR ${CEEDLING_MODULE_BASE}/../ceedling/vendor/cmock)
get_property(CMOCK_DIR GLOBAL PROPERTY CMOCK_DIR)
get_property(UNITY_DIR GLOBAL PROPERTY UNITY_DIR)

include(${CEEDLING_MODULE_BASE}/cmake/unity.cmake)
include(${CEEDLING_MODULE_BASE}/cmake/cmock.cmake)

zephyr_library()
zephyr_include_directories(
  ${UNITY_DIR}/src
  ${CMOCK_DIR}/src
  ${CMAKE_CURRENT_LIST_DIR}
)
zephyr_library_sources(
  ${CMOCK_DIR}/src/cmock.c
)
