# The following functions are modified version
# from the original project: https://github.com/nrfconnect/sdk-nrf/
#
# The original version had this license:
#
# Copyright (c) 2019 Nordic Semiconductor
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause

set_property(GLOBAL PROPERTY CMOCK_PREFIX "mock_")
set_property(GLOBAL PROPERTY CMOCK_OBJ_PREFIX "")

# Internal macro for creating unity configuration yaml.
# The name of the output file is returned in `out_config_file`.
# mock_name:         name of file that is mocked. Can be empty to create common file with no excludes.
# exclude_fn_list:   holds list of functions that should be placed in strippables.
# exclude_word_list: holds list of words that should be placed in strippables.
# out_config_file:   return setting with path and name to generate config file
macro(configure_cmock_conf_file mock_name exclude_fn_list exclude_word_list out_config_file)
  get_property(CEEDLING_MODULE_BASE GLOBAL PROPERTY CEEDLING_MODULE_BASE)
  get_property(UNITY_CFG_TEMPLATE GLOBAL PROPERTY UNITY_CFG_TEMPLATE)
  set(unity_config_file_name unity_cfg.yaml)
  set(out_dir ${APPLICATION_BINARY_DIR}/runner)

  if("${exclude_fn_list}" STREQUAL "" AND "${exclude_word_list}" STREQUAL "")
    configure_unity_conf_file(mock_name _out_config_file)
    set(${out_config_file} ${_out_config_file})
  else()
    set(CMOCK_STRIPPABLES ":strippables:\n")
    foreach(ex ${exclude_fn_list})
      string(CONFIGURE "        - '(?:${ex}\\s*\\(+.*?\\)+)'\n" strip_regex)
      set(CMOCK_STRIPPABLES "${CMOCK_STRIPPABLES}${strip_regex}")
    endforeach()
    foreach(ex ${exclude_word_list})
      string(CONFIGURE "        - '(?:${ex})'\n" strip_word)
      set(CMOCK_STRIPPABLES "${CMOCK_STRIPPABLES}${strip_word}")
    endforeach()
    set(${out_config_file} ${out_dir}/${mock_name}.${unity_config_file_name})
    configure_file(${UNITY_CFG_TEMPLATE} ${${out_config_file}})
    set(CMOCK_STRIPPABLES)
  endif()
endmacro()

# Generate cmock for provided header file.
function(cmock_generate header_path dst_path)
  get_property(CMOCK_DIR GLOBAL PROPERTY CMOCK_DIR)
  get_property(CMOCK_PREFIX GLOBAL PROPERTY CMOCK_PREFIX)

  get_filename_component(file_name "${header_path}" NAME_WE)
  set(MOCK_FILE ${dst_path}/${CMOCK_PREFIX}${file_name}.c)

  file(MAKE_DIRECTORY "${dst_path}")
  configure_cmock_conf_file("${file_name}" "${CMOCK_FUNC_EXCLUDE}" "${CMOCK_WORD_EXCLUDE}" conf_file)

  add_custom_command(OUTPUT ${MOCK_FILE}
    COMMAND ${RUBY_EXECUTABLE}
    ${CMOCK_DIR}/lib/cmock.rb
    --mock_prefix=${CMOCK_PREFIX}
    --mock_path=${dst_path}
    -o${conf_file}
    ${header_path}
    DEPENDS ${header_path}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
  )

  target_sources(app PRIVATE ${MOCK_FILE})
endfunction()

# Add --wrap linker option for each function listed in the input file.
function(cmock_linker_trick func_name_path)
  get_property(CMOCK_OBJ_PREFIX GLOBAL PROPERTY CMOCK_OBJ_PREFIX)
  file(STRINGS ${func_name_path} contents)
  if (contents)
    set(linker_str "-Wl")
  endif()
  foreach(src ${contents})
    set(linker_str "${linker_str},--defsym,${src}=${CMOCK_OBJ_PREFIX}${src}")
  endforeach()
  zephyr_link_libraries(${linker_str})
endfunction()


# Handle wrapping functions from mocked file.
# Function takes header file and generates a file containing list of functions.
# File is then passed to 'cmock_linker_trick' which adds linker option for each
# function listed in the file.
# FUNC_EXCLUDE <pattern>: Exclude functions matching pattern. Pattern can be a simple style regex.
function(cmock_linker_wrap_trick header_file_path)
  set(flist_file "${header_file_path}.flist")
  get_property(CEEDLING_MODULE_BASE GLOBAL PROPERTY CEEDLING_MODULE_BASE)

  if(DEFINED CMOCK_FUNC_EXCLUDE)
    string(JOIN ";--exclude;" exclude_arg ${CMOCK_FUNC_EXCLUDE})
    set(exclude_arg "--exclude" ${exclude_arg})
  endif()

  execute_process(
    COMMAND
    ${PYTHON_EXECUTABLE}
    ${CEEDLING_MODULE_BASE}/scripts/unity/func_name_list.py
    --input ${header_file_path}
    --output ${flist_file}
    ${exclude_arg}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    RESULT_VARIABLE op_result
    OUTPUT_VARIABLE output_result
    COMMAND_ECHO STDOUT
  )

  if (NOT ${op_result} EQUAL 0)
    message(SEND_ERROR "${output_result}")
    message(FATAL_ERROR "Failed to parse header ${header_file_path}")
  endif()
  cmock_linker_trick(${flist_file})
endfunction()

# Function takes original header and prepares two version
# - version with system calls removed and static inline functions
#   converted to standard function declarations
# - version with additional CMOCK_OBJ_PREFIX prefix for all functions that
#   is used to generate cmock
function(cmock_headers_prepare in_header out_header wrap_header)
  get_property(CEEDLING_MODULE_BASE GLOBAL PROPERTY CEEDLING_MODULE_BASE)
  get_property(CMOCK_OBJ_PREFIX GLOBAL PROPERTY CMOCK_OBJ_PREFIX)

  execute_process(
    COMMAND
    ${PYTHON_EXECUTABLE}
    ${CEEDLING_MODULE_BASE}/scripts/unity/header_prepare.py
    "--input" ${in_header}
    "--output" ${out_header}
    "--wrap" ${wrap_header}
    "--prefix" "${CMOCK_OBJ_PREFIX}"
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    RESULT_VARIABLE op_result
    OUTPUT_VARIABLE output_result
    COMMAND_ECHO STDOUT
  )

  if (NOT ${op_result} EQUAL 0)
    message(SEND_ERROR "${output_result}")
    message(FATAL_ERROR "Failed to parse header ${in_header}")
  endif()
endfunction()

# function for handling usage of mock
# optional second argument can contain offset that include should be placed in
# for example if file under test is include mocked header as <foo/header.h> then
# mock and replaced header should be placed in <mock_path>/foo with <mock_path>
# added as include path.
# EXCLUDE <pattern>: Exclude functions matching pattern. Deprecated, use FUNC_EXCLUDE instead.
# FUNC_EXCLUDE <pattern>: Exclude functions matching pattern. Pattern can be a simple style regex.
# WORD_EXCLUDE <pattern>: Exclude words matching pattern. Pattern can be a simple style regex.
function(cmock_handle header_file)
  cmake_parse_arguments(CMOCK "" "" "EXCLUDE;FUNC_EXCLUDE;WORD_EXCLUDE" ${ARGN})
  get_property(CMOCK_DIR GLOBAL PROPERTY CMOCK_DIR)
  set(CMOCK_PRODUCTS_DIR ${APPLICATION_BINARY_DIR}/mocks)

  if (DEFINED CMOCK_EXCLUDE)
    message(DEPRECATION " cmock_handle(EXCLUDE) is deprecated, use FUNC_EXCLUDE instead")
    list(APPEND CMOCK_FUNC_EXCLUDE ${CMOCK_EXCLUDE})
  endif()

  #get optional offset macro
  set (extra_macro_args ${CMOCK_UNPARSED_ARGUMENTS})
  list(LENGTH extra_macro_args num_extra_args)
  if (NOT ${num_extra_args} EQUAL 0)
    list(GET extra_macro_args 0 optional_offset)
    set(dst_path "${CMOCK_PRODUCTS_DIR}/${optional_offset}")
  else()
    set(dst_path "${CMOCK_PRODUCTS_DIR}")
  endif()
  message(STATUS "header ${dst_path}")

  file(MAKE_DIRECTORY "${dst_path}/internal")

  get_filename_component(header_name "${header_file}" NAME)
  set(mod_header_path "${dst_path}/${header_name}")
  set(wrap_header "${dst_path}/internal/${header_name}")

  cmock_headers_prepare(${header_file} ${mod_header_path} ${wrap_header})
  cmock_generate(${wrap_header} ${dst_path})

  #cmock_linker_wrap_trick(${mod_header_path})

  target_include_directories(app BEFORE PRIVATE ${CMOCK_PRODUCTS_DIR})
  message(STATUS "Generating cmock for header ${header_file}")
endfunction()
