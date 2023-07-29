# The following functions are modified version
# from the original project: https://github.com/nrfconnect/sdk-nrf/
#
# The original version had this license:
#
# Copyright (c) 2019 Nordic Semiconductor
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#

# Internal macro for creating unity configuration yaml.
# The name of the output file is returned in `out_config_file`.
# name:              name of runner. Can be empty to create common file.
# out_config_file:   return setting with path and name to generate config file
macro(configure_unity_conf_file name out_config_file)
  get_property(CEEDLING_MODULE_BASE GLOBAL PROPERTY CEEDLING_MODULE_BASE)
  get_property(UNITY_CFG_TEMPLATE GLOBAL PROPERTY UNITY_CFG_TEMPLATE)
  set(unity_config_file_name unity_cfg.yaml)
  set(out_dir ${APPLICATION_BINARY_DIR}/runner)

  if("${name}" STREQUAL "")
    configure_file(${UNITY_CFG_TEMPLATE}
                   ${out_dir}/${unity_config_file_name}
    )
  endif()
  # Just return the common file.
 set(${out_config_file} ${out_dir}/${unity_config_file_name})
endmacro()

# Generate test runner file.
function(test_runner_generate test_file_path)
  get_property(UNITY_DIR GLOBAL PROPERTY UNITY_DIR)
  get_property(UNITY_CONFIG_HEADER_DIR GLOBAL PROPERTY UNITY_CONFIG_HEADER_DIR)
  set(UNITY_PRODUCTS_DIR ${APPLICATION_BINARY_DIR}/runner)
  file(MAKE_DIRECTORY "${UNITY_PRODUCTS_DIR}")
  get_filename_component(test_file_name "${test_file_path}" NAME)
  set(output_file "${UNITY_PRODUCTS_DIR}/runner_${test_file_name}")
  configure_unity_conf_file("${file_name}" conf_file)

  add_custom_command(
    COMMAND ${RUBY_EXECUTABLE}
    ${UNITY_DIR}/auto/generate_test_runner.rb
    ${conf_file}
    ${test_file_path} ${output_file}
    DEPENDS ${test_file_path}
    OUTPUT ${output_file}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
  )

  zephyr_library_sources(
    ${output_file}
  )
  zephyr_include_directories(
    ${UNITY_CONFIG_HEADER_DIR}
  )
  
  message(STATUS "Generating test runner ${output_file}")
endfunction()

