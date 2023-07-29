set_property(GLOBAL PROPERTY CEEDLING_MODULE_BASE ${CMAKE_CURRENT_LIST_DIR})

add_subdirectory_ifdef(CONFIG_UNITY unity)
add_subdirectory_ifdef(CONFIG_CMOCK cmock)
