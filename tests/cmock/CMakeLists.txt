cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(test_cmock)

test_runner_generate(src/main.c)
cmock_handle(${ZEPHYR_BASE}/include/zephyr/drivers/gpio.h drivers)

target_sources(app PRIVATE src/main.c)
