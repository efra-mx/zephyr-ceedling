/* Copyright (c) 2021 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */
#ifndef UNITY_CONFIG_H__
#define UNITY_CONFIG_H__

#define UNITY_INCLUDE_PRINT_FORMATTED
#define UNITY_EXCLUDE_MATH_H
#define UNITY_SUPPORT_64

#ifdef CONFIG_UNITY_OUTPUT_COLOR
#define UNITY_OUTPUT_COLOR
#endif

#ifndef CONFIG_BOARD_NATIVE_POSIX
#include <stddef.h>
#include <stdio.h>
#include <zephyr.h>
#define UNITY_EXCLUDE_SETJMP_H 1
#define UNITY_OUTPUT_CHAR(a) printk("%c", a)
#endif


/* It is required to be added to each test. That is because unity is using
 * different main signature (returns int) and zephyr expects main which does
 * not return value.
 */
extern int unity_main(void);

#endif /* UNITY_CONFIG_H__ */